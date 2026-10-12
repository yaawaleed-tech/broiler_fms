import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;

import 'package:broiler_fms/data/local/database.dart'
    show AccountsCompanion, AppDatabase, BusinessesCompanion;
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/domain/models/sale.dart';
import 'package:broiler_fms/repository/sale/local_sale_repository.dart';

/// sqlite3_flutter_libs bundles the library into phone builds only,
/// so desktop tests open the system sqlite3. Prefer the normal soname,
/// fall back to the versioned one for machines that have no unversioned
/// development symlink. Top level because drift may open the database
/// from another isolate.
DynamicLibrary _openSqlite() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } on ArgumentError {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

/// Covers the one pull-direction write LocalSaleRepository has: overwriting
/// the cache with sales that came down from Supabase. The
/// local-origin write (record) keeps its own queue wiring, tested
/// over in test/sync/sync_service_test.dart.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late LocalSaleRepository repo;
  late LocalSyncQueueRepository queue;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalSaleRepository(db);
    queue = LocalSyncQueueRepository(db);
  });

  tearDown(() => db.close());

  /// One business and one account, the parents the table points at.
  Future<void> seed() async {
    await db
        .into(db.businesses)
        .insert(
          BusinessesCompanion.insert(businessId: 'biz-1', name: 'Sunny Farm'),
        );
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            accountId: 'acc-1',
            businessId: const Value('biz-1'),
            role: 'manager',
            name: 'Mia',
            email: 'mia@example.com',
          ),
        );
  }

  group('LocalSaleRepository.upsertAll', () {
    test('writes pulled sales without enqueueing them for push', () async {
      await seed();

      await repo.upsertAll([
        Sale(
          saleId: 'sale-9',
          harvestId: 'har-1',
          recordedBy: 'acc-1',
          disposition: 'gift_cull',
          amount: 0,
          createdAt: DateTime(2026, 2, 1),
        ),
      ]);

      final stored = await repo.getById('sale-9');
      expect(stored, isNotNull);
      expect(
        await queue.pendingCount(),
        0,
        reason: 'data that came down from Supabase must never be pushed back',
      );
    });

    test(
      'keeps the local row while its id is still queued for push',
      () async {
        await seed();
        final created = await repo.record(
          harvestId: 'har-1',
          recordedBy: 'acc-1',
          disposition: 'sale',
          amount: 100,
          buyerName: 'Local Buyer',
          pricingMethod: 'flat_total',
          paymentStatus: 'pending',
        );
        expect(await queue.pendingCount(), 1);

        await repo.upsertAll([
          Sale(
            saleId: created.saleId,
            harvestId: 'har-1',
            recordedBy: 'acc-1',
            disposition: 'sale',
            amount: 250,
            createdAt: DateTime(2026, 3, 2),
            buyerName: 'Server Buyer',
            pricingMethod: 'per_kg',
            weightSold: 125,
            pricePerUnit: 2,
            paymentStatus: 'paid',
          ),
        ]);

        final stored = await repo.getById(created.saleId);
        expect(stored!.amount, 100,
            reason: 'a queued row must not be overwritten by the pull');
        expect(stored.buyerName, 'Local Buyer');
        expect(stored.pricingMethod, 'flat_total');
        expect(stored.weightSold, null);
        expect(stored.paymentStatus, 'pending');
        expect(
          await queue.pendingCount(),
          1,
          reason: 'the pull neither cleared nor added queue rows',
        );
      },
    );

    test(
      'applies the server copy once the id is no longer queued',
      () async {
        await seed();
        final created = await repo.record(
          harvestId: 'har-1',
          recordedBy: 'acc-1',
          disposition: 'sale',
          amount: 100,
          buyerName: 'Local Buyer',
          pricingMethod: 'flat_total',
          paymentStatus: 'pending',
        );

        final pending = await queue.pendingRows();
        await queue.markSynced(pending.single.id);
        expect(await queue.pendingCount(), 0);

        final written = await repo.upsertAll([
          Sale(
            saleId: created.saleId,
            harvestId: 'har-1',
            recordedBy: 'acc-1',
            disposition: 'sale',
            amount: 250,
            createdAt: DateTime(2026, 3, 2),
            buyerName: 'Server Buyer',
            pricingMethod: 'per_kg',
            weightSold: 125,
            pricePerUnit: 2,
            paymentStatus: 'paid',
          ),
        ]);

        final stored = await repo.getById(created.saleId);
        expect(stored!.harvestId, 'har-1');
        expect(stored.recordedBy, 'acc-1');
        expect(stored.disposition, 'sale');
        expect(stored.amount, 250);
        expect(stored.createdAt, DateTime(2026, 3, 2));
        expect(stored.buyerName, 'Server Buyer');
        expect(stored.pricingMethod, 'per_kg');
        expect(stored.weightSold, 125);
        expect(stored.pricePerUnit, 2);
        expect(stored.paymentStatus, 'paid');
        expect(written, 1, reason: 'one row handed to the cache write');
        expect(await queue.pendingCount(), 0);
      },
    );
  });
}
