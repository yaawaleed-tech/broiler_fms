import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;

import 'package:broiler_fms/data/local/database.dart'
    show
        AccountsCompanion,
        AppDatabase,
        BatchesCompanion,
        BusinessesCompanion;
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';

DynamicLibrary _openSqlite() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } on ArgumentError {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

/// Covers LocalBatchRepository.releaseMissing: the local mark that a
/// Staff member's batch was reassigned to somebody else.
///
/// The invariant under test throughout is that this marks rows and
/// nothing else — no other column moves, and nothing is queued for push.
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
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            accountId: 'acc-2',
            businessId: const Value('biz-1'),
            role: 'staff',
            name: 'Alex',
            email: 'alex@example.com',
          ),
        );
  }

  /// Writes a batch straight into Drift, bypassing the repository, so a
  /// test can set up a state the API would not easily produce.
  Future<void> put({
    required String id,
    String? assignedStaffId = 'acc-1',
    bool isClosed = false,
    DateTime? closedAt,
    String name = 'House 1',
  }) async {
    await db.into(db.batches).insert(
          BatchesCompanion.insert(
            batchId: id,
            businessId: 'biz-1',
            assignedStaffId: Value(assignedStaffId),
            batchName: name,
            startingBirdCount: 100,
            startDate: DateTime(2026, 1, 1),
            isClosed: Value(isClosed),
            createdAt: Value(DateTime(2026, 1, 1)),
            closedAt: Value(closedAt),
          ),
        );
  }

  group('LocalBatchRepository.releaseMissing', () {
    test('clears only the rows missing from the server ids', () async {
      await seed();
      await put(id: 'kept');
      await put(id: 'lost', name: 'House 2');

      final released = await repo.releaseMissing(
        accountId: 'acc-1',
        serverBatchIds: {'kept'},
      );

      expect(released, 1);
      expect((await repo.getById('kept'))!.assignedStaffId, 'acc-1',
          reason: 'the server still returns it');
      expect((await repo.getById('lost'))!.assignedStaffId, isNull,
          reason: 'the server stopped returning it');
    });

    test('leaves another account’s batches alone', () async {
      await seed();
      await put(id: 'other', assignedStaffId: 'acc-2');

      final released = await repo.releaseMissing(
        accountId: 'acc-1',
        serverBatchIds: const {},
      );

      expect(released, 0, reason: 'not this account’s row to release');
      expect((await repo.getById('other'))!.assignedStaffId, 'acc-2');
    });

    test('skips a row that still has a pending queue entry', () async {
      await seed();
      await put(id: 'pending');
      await queue.enqueue(
        entityTable: 'batches',
        recordId: 'pending',
        operation: 'insert',
      );

      final released = await repo.releaseMissing(
        accountId: 'acc-1',
        serverBatchIds: const {},
      );

      expect(released, 0,
          reason: 'a local write not yet pushed is not a reassignment');
      expect((await repo.getById('pending'))!.assignedStaffId, 'acc-1');
    });

    test('still releases the un-queued sibling', () async {
      await seed();
      await put(id: 'pending');
      await put(id: 'free', name: 'House 2');
      await queue.enqueue(
        entityTable: 'batches',
        recordId: 'pending',
        operation: 'insert',
      );

      final released = await repo.releaseMissing(
        accountId: 'acc-1',
        serverBatchIds: const {},
      );

      expect(released, 1);
      expect((await repo.getById('pending'))!.assignedStaffId, 'acc-1');
      expect((await repo.getById('free'))!.assignedStaffId, isNull);
    });

    test('touches no other column', () async {
      await seed();
      final closedAt = DateTime(2026, 2, 3);
      await put(
        id: 'closed',
        isClosed: true,
        closedAt: closedAt,
        name: 'House 9',
      );
      final before = (await repo.getById('closed'))!;
      final beforeClosed = before.isClosed;

      await repo.releaseMissing(
        accountId: 'acc-1',
        serverBatchIds: const {},
      );

      final after = (await repo.getById('closed'))!;
      expect(after.assignedStaffId, isNull);
      expect(after.isClosed, beforeClosed);
      expect(after.closedAt, closedAt);
      expect(after.batchName, before.batchName);
      expect(after.startingBirdCount, before.startingBirdCount);
      expect(after.startDate, before.startDate);
      expect(after.createdAt, before.createdAt);
      expect(after.businessId, before.businessId);
    });

    test('enqueues nothing at all', () async {
      await seed();
      await put(id: 'lost');

      await repo.releaseMissing(
        accountId: 'acc-1',
        serverBatchIds: const {},
      );

      expect(await queue.pendingCount(), 0,
          reason: 'this is a local mark, never something to push up');
    });

    test('is idempotent: a second call changes nothing', () async {
      await seed();
      await put(id: 'lost');

      final first = await repo.releaseMissing(
        accountId: 'acc-1',
        serverBatchIds: const {},
      );
      final second = await repo.releaseMissing(
        accountId: 'acc-1',
        serverBatchIds: const {},
      );

      expect(first, 1);
      expect(second, 0, reason: 'the row is already released');
    });

    test('does not delete the row: it stays readable', () async {
      await seed();
      await put(id: 'lost');

      await repo.releaseMissing(
        accountId: 'acc-1',
        serverBatchIds: const {},
      );

      expect(await repo.getById('lost'), isNotNull,
          reason: 'history is kept, the batch is only marked');
    });
  });

  group('watchForStaff includes released rows', () {
    test('an assigned and a released row both appear', () async {
      await seed();
      await put(id: 'mine');
      await put(id: 'released', name: 'House 2', assignedStaffId: null);
      await put(id: 'theirs', name: 'House 3', assignedStaffId: 'acc-2');

      final seen = await repo.watchForStaff('acc-1').first;

      expect(seen.map((b) => b.batchId), containsAll(['mine', 'released']));
      expect(seen.map((b) => b.batchId), isNot(contains('theirs')),
          reason: 'another account’s batch is still invisible');
    });

    test('getForStaff keeps its old narrow meaning', () async {
      // Unchanged on purpose: only the stream the batch list uses was
      // widened, so this and its existing callers behave as before.
      await seed();
      await put(id: 'mine');
      await put(id: 'released', name: 'House 2', assignedStaffId: null);

      final seen = await repo.getForStaff('acc-1');

      expect(seen.map((b) => b.batchId), ['mine']);
    });
  });
}