import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/data/local/database.dart'
    show AccountsCompanion, AppDatabase, BusinessesCompanion;
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/repository/batch/remote_batch_repository.dart';
import 'package:broiler_fms/repository/expense/local_expense_repository.dart';
import 'package:broiler_fms/repository/feed/local_feed_repository.dart';
import 'package:broiler_fms/repository/harvest/local_harvest_repository.dart';
import 'package:broiler_fms/repository/mortality/local_mortality_repository.dart';
import 'package:broiler_fms/repository/sale/local_sale_repository.dart';
import 'package:broiler_fms/repository/weight/local_weight_repository.dart';

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

/// A RemoteBatchRepository that never talks to the network: it hands
/// back whatever rows the test gave it, or throws if told to.
class _StubRemoteBatchRepository extends RemoteBatchRepository {
  _StubRemoteBatchRepository(super.client, {this.rows = const [], this.error});

  final List<Batch> rows;
  final Object? error;

  @override
  Future<List<Batch>> getAll() async {
    if (error != null) throw error!;
    return rows;
  }
}

/// Covers the pull half of BatchDomain.refreshBatches(): the login-time
/// download that finally tells a Staff device about the batch a Manager
/// just assigned it.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late LocalSyncQueueRepository queue;
  late SupabaseClient client;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queue = LocalSyncQueueRepository(db);
    client = SupabaseClient('https://example.supabase.co', 'anon-key');
    addTearDown(client.dispose);
  });

  tearDown(() => db.close());

  /// One business and the Staff account using this device.
  Future<void> seed() async {
    await db.into(db.businesses).insert(
          BusinessesCompanion.insert(businessId: 'biz-1', name: 'Sunny Farm'),
        );
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            accountId: 'acc-staff',
            businessId: const Value('biz-1'),
            role: 'staff',
            name: 'Sam',
            email: 'sam@example.com',
          ),
        );
  }

  BatchDomain buildDomain(RemoteBatchRepository remoteBatchRepo) {
    return BatchDomain(
      batchRepo: LocalBatchRepository(db),
      remoteBatchRepo: remoteBatchRepo,
      harvestRepo: LocalHarvestRepository(db),
      mortalityRepo: LocalMortalityRepository(db),
      expenseRepo: LocalExpenseRepository(db),
      saleRepo: LocalSaleRepository(db),
      feedRepo: LocalFeedRepository(db),
      weightRepo: LocalWeightRepository(db),
      currentAccount: Account(
        accountId: 'acc-staff',
        businessId: 'biz-1',
        role: 'staff',
        name: 'Sam',
        email: 'sam@example.com',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  }

  group('BatchDomain.refreshBatches', () {
    test('an assigned batch pulled down becomes visible to Staff', () async {
      await seed();
      final domain = buildDomain(_StubRemoteBatchRepository(
        client,
        rows: [
          Batch(
            batchId: 'batch-1',
            businessId: 'biz-1',
            batchName: 'House 1',
            startingBirdCount: 100,
            startDate: DateTime(2026, 1, 1),
            isClosed: false,
            createdAt: DateTime(2026, 1, 1),
            assignedStaffId: 'acc-staff',
          ),
        ],
      ));

      expect(await domain.getForStaff('acc-staff'), isEmpty);

      await domain.refreshBatches();

      final visible = await domain.getForStaff('acc-staff');
      expect(visible, hasLength(1));
      expect(visible.single.assignedStaffId, 'acc-staff');
      expect(
        await queue.pendingCount(),
        0,
        reason: 'pulled rows must never be queued for push back up',
      );
    });

    test('a failed pull throws and leaves the cache untouched', () async {
      await seed();
      final domain = buildDomain(_StubRemoteBatchRepository(
        client,
        error: Exception('offline'),
      ));

      await expectLater(domain.refreshBatches(), throwsA(isA<Exception>()));
      expect(await domain.getForStaff('acc-staff'), isEmpty);
      expect(await queue.pendingCount(), 0);
    });
  });
}
