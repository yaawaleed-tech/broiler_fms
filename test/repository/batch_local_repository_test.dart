import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;

import 'package:broiler_fms/data/local/database.dart'
    show AccountsCompanion, AppDatabase, BusinessesCompanion;
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';

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

/// Covers the one pull-direction write LocalBatchRepository has:
/// overwriting the cache with batches that came down from Supabase.
/// The local-origin writes (create, assign, close) keep their own
/// queue wiring, tested over in test/sync/sync_service_test.dart.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late LocalBatchRepository repo;
  late LocalSyncQueueRepository queue;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalBatchRepository(db);
    queue = LocalSyncQueueRepository(db);
  });

  tearDown(() => db.close());

  /// One business and one Staff account, the parents the batches table
  /// points at.
  Future<void> seed() async {
    await db.into(db.businesses).insert(
          BusinessesCompanion.insert(businessId: 'biz-1', name: 'Sunny Farm'),
        );
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            accountId: 'acc-1',
            businessId: const Value('biz-1'),
            role: 'staff',
            name: 'Sam',
            email: 'sam@example.com',
          ),
        );
  }

  group('LocalBatchRepository.upsertAll', () {
    test('writes pulled batches without enqueueing them for push', () async {
      await seed();
      final pulled = Batch(
        batchId: 'batch-9',
        businessId: 'biz-1',
        batchName: 'House 9',
        startingBirdCount: 50,
        startDate: DateTime(2026, 2, 1),
        isClosed: false,
        createdAt: DateTime(2026, 1, 30),
        assignedStaffId: 'acc-1',
      );

      await repo.upsertAll([pulled]);

      final stored = await repo.getById('batch-9');
      expect(stored, isNotNull);
      expect(stored!.assignedStaffId, 'acc-1');
      expect(
        await queue.pendingCount(),
        0,
        reason: 'data that came down from Supabase must never be pushed back',
      );
    });

    test('keeps the local row while its id is still queued for push',
        () async {
      await seed();
      // The local-origin path: create() writes the row and queues it.
      final created = await repo.create(
        businessId: 'biz-1',
        batchName: 'House 1',
        startingBirdCount: 100,
        startDate: DateTime(2026, 1, 1),
      );
      expect(await queue.pendingCount(), 1);

      // The server sends back the same batch without the assignment this
      // device has queued but not yet sent. Applying it would destroy
      // the pending edit, which then gets pushed back up stale.
      await repo.upsertAll([
        Batch(
          batchId: created.batchId,
          businessId: 'biz-1',
          batchName: 'House 1',
          startingBirdCount: 100,
          startDate: created.startDate,
          isClosed: false,
          createdAt: created.createdAt,
          assignedStaffId: 'acc-1',
        ),
      ]);

      final stored = await repo.getById(created.batchId);
      expect(stored!.assignedStaffId, isNull,
          reason: 'a queued row must not be overwritten by the pull');
      expect(stored.isClosed, isFalse);
      expect(
        await queue.pendingCount(),
        1,
        reason: 'the pull neither cleared nor added queue rows',
      );
    });

    test('applies the server copy once the id is no longer queued', () async {
      await seed();
      final created = await repo.create(
        businessId: 'biz-1',
        batchName: 'House 1',
        startingBirdCount: 100,
        startDate: DateTime(2026, 1, 1),
      );

      // The push went through, so the queue row is gone and this row is
      // no longer local intent — it is just a cache entry now.
      final pending = await queue.pendingRows();
      await queue.markSynced(pending.single.id);
      expect(await queue.pendingCount(), 0);

      final written = await repo.upsertAll([
        Batch(
          batchId: created.batchId,
          businessId: 'biz-1',
          batchName: 'House 1',
          startingBirdCount: 100,
          startDate: created.startDate,
          isClosed: true,
          createdAt: created.createdAt,
          assignedStaffId: 'acc-1',
          closedBy: 'acc-1',
          closedAt: DateTime(2026, 3, 1),
        ),
      ]);

      final stored = await repo.getById(created.batchId);
      expect(stored!.assignedStaffId, 'acc-1');
      expect(stored.isClosed, isTrue);
      expect(stored.closedBy, 'acc-1');
      expect(stored.closedAt, DateTime(2026, 3, 1));
      expect(written, 1, reason: 'one row handed to the cache write');
      expect(
        await queue.pendingCount(),
        0,
        reason: 'the pull added no queue rows',
      );
    });

    test('applies other rows in the same pull while one is protected',
        () async {
      await seed();
      final created = await repo.create(
        businessId: 'biz-1',
        batchName: 'House 1',
        startingBirdCount: 100,
        startDate: DateTime(2026, 1, 1),
      );

      final written = await repo.upsertAll([
        Batch(
          batchId: created.batchId,
          businessId: 'biz-1',
          batchName: 'House 1',
          startingBirdCount: 100,
          startDate: created.startDate,
          isClosed: true,
          createdAt: created.createdAt,
        ),
        Batch(
          batchId: 'batch-other',
          businessId: 'biz-1',
          batchName: 'House 2',
          startingBirdCount: 200,
          startDate: DateTime(2026, 2, 1),
          isClosed: true,
          createdAt: DateTime(2026, 2, 1),
        ),
      ]);

      expect(written, 1, reason: 'the protected row is skipped, not the whole pull');
      expect((await repo.getById('batch-other'))!.batchName, 'House 2');
      expect((await repo.getById(created.batchId))!.isClosed, isFalse);
    });
  });
}
