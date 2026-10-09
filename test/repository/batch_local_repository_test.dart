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

    test('overwrites a cached batch with every field the server returned',
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

      // The same batch arrives from the server carrying Manager's
      // assignment and the closing fields — the exact data this fix
      // exists to deliver.
      await repo.upsertAll([
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
      expect(stored!.assignedStaffId, 'acc-1',
          reason: 'the assignment is the whole point of this fix');
      expect(stored.isClosed, isTrue);
      expect(stored.closedBy, 'acc-1');
      expect(stored.closedAt, DateTime(2026, 3, 1));
      expect(
        await queue.pendingCount(),
        1,
        reason: 'the pull added no queue rows; create()s row is the only one',
      );
    });
  });
}
