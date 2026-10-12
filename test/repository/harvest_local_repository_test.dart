import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;

import 'package:broiler_fms/data/local/database.dart'
    show AccountsCompanion, AppDatabase, BusinessesCompanion;
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/domain/models/harvest.dart';
import 'package:broiler_fms/repository/harvest/local_harvest_repository.dart';

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

/// Covers the one pull-direction write LocalHarvestRepository has: overwriting
/// the cache with harvest entries that came down from Supabase. The
/// local-origin write (record) keeps its own queue wiring, tested
/// over in test/sync/sync_service_test.dart.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late LocalHarvestRepository repo;
  late LocalSyncQueueRepository queue;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalHarvestRepository(db);
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

  group('LocalHarvestRepository.upsertAll', () {
    test(
      'writes pulled harvest entries without enqueueing them for push',
      () async {
        await seed();

        await repo.upsertAll([
          Harvest(
            harvestId: 'har-9',
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: DateTime(2026, 2, 1),
            birdCount: 100,
            recordedAt: DateTime(2026, 2, 1),
          ),
        ]);

        final stored = await repo.getById('har-9');
        expect(stored, isNotNull);
        expect(
          await queue.pendingCount(),
          0,
          reason: 'data that came down from Supabase must never be pushed back',
        );
      },
    );

    test(
      'keeps the local row while its id is still queued for push',
      () async {
        await seed();
        final created = await repo.record(
          batchId: 'batch-1',
          recordedBy: 'acc-1',
          date: DateTime(2026, 1, 1),
          birdCount: 30,
        );
        expect(await queue.pendingCount(), 1);

        await repo.upsertAll([
          Harvest(
            harvestId: created.harvestId,
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: DateTime(2026, 3, 1),
            birdCount: 120,
            recordedAt: DateTime(2026, 3, 2),
          ),
        ]);

        final stored = await repo.getById(created.harvestId);
        expect(stored!.date, DateTime(2026, 1, 1),
            reason: 'a queued row must not be overwritten by the pull');
        expect(stored.birdCount, 30);
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
          batchId: 'batch-1',
          recordedBy: 'acc-1',
          date: DateTime(2026, 1, 1),
          birdCount: 30,
        );

        final pending = await queue.pendingRows();
        await queue.markSynced(pending.single.id);
        expect(await queue.pendingCount(), 0);

        final written = await repo.upsertAll([
          Harvest(
            harvestId: created.harvestId,
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: DateTime(2026, 3, 1),
            birdCount: 120,
            recordedAt: DateTime(2026, 3, 2),
          ),
        ]);

        final stored = await repo.getById(created.harvestId);
        expect(stored!.batchId, 'batch-1');
        expect(stored.recordedBy, 'acc-1');
        expect(stored.date, DateTime(2026, 3, 1));
        expect(stored.birdCount, 120);
        expect(stored.recordedAt, DateTime(2026, 3, 2));
        expect(written, 1, reason: 'one row handed to the cache write');
        expect(await queue.pendingCount(), 0);
      },
    );
  });
}
