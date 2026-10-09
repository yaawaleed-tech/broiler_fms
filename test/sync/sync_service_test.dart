import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/data/local/database.dart';
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/repository/expense/local_expense_repository.dart';
import 'package:broiler_fms/sync/pushers/entity_pusher.dart';
import 'package:broiler_fms/sync/sync_result.dart';
import 'package:broiler_fms/sync/sync_service.dart';

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

/// A pusher that records what it was asked to push and can be told to
/// fail, be rejected, or to report the record as gone. Never touches
/// Supabase.
class _FakePusher extends EntityPusher {
  _FakePusher(
    this.entityTable, {
    this.onPush,
    this.failWith,
    this.rejectedWith,
    this.reportDropped = false,
  });

  @override
  final String entityTable;

  /// Called with each pushed record id, in push order.
  final void Function(String recordId)? onPush;

  final String? failWith;
  final String? rejectedWith;
  final bool reportDropped;

  @override
  Future<SyncPushResult> push(SyncQueueData row, SupabaseClient client) async {
    if (failWith != null) return SyncPushFailure(failWith!);
    if (rejectedWith != null) return SyncPushRejected(rejectedWith!);
    if (reportDropped) return const SyncPushDropped();
    onPush?.call(row.recordId);
    return const SyncPushSuccess();
  }
}

/// Covers the queue wiring the repositories leave behind, and the pass
/// the sync engine makes over it.
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

  /// One business, one staff account, one batch — the parents every
  /// entry table points at.
  Future<void> seedParents() async {
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
    await db.into(db.batches).insert(
          BatchesCompanion.insert(
            batchId: 'batch-1',
            businessId: 'biz-1',
            batchName: 'House 1',
            startingBirdCount: 100,
            startDate: DateTime(2026, 1, 1),
          ),
        );
  }

  SyncService serviceWith(List<EntityPusher> pushers) => SyncService(
        queue: queue,
        client: client,
        pushers: pushers,
      );

  group('queue wiring', () {
    test('a new batch is queued as an insert, later edits as updates',
        () async {
      await seedParents();
      final batches = LocalBatchRepository(db);

      await batches.create(
        businessId: 'biz-1',
        batchName: 'House 2',
        startingBirdCount: 50,
        startDate: DateTime(2026, 1, 3),
      );
      var rows = await queue.pendingRows();
      expect(rows, hasLength(1));
      expect(rows.single.entityTable, 'batches');
      expect(rows.single.operation, 'insert');

      await batches.assignStaff('batch-1', 'acc-1');
      await batches.close('batch-1', 'acc-1');
      rows = await queue.pendingRows();
      expect(rows.map((r) => r.operation).toList(), ['insert', 'update', 'update']);
      expect(rows.map((r) => r.entityTable).toSet(), {'batches'});
    });

    test('a recorded expense is queued and marked synced on demand',
        () async {
      await seedParents();
      final expenses = LocalExpenseRepository(db);

      final expense = await expenses.record(
        batchId: 'batch-1',
        recordedBy: 'acc-1',
        category: 'feed',
        date: DateTime(2026, 1, 2),
        amount: 12.5,
      );
      final rows = await queue.pendingRows();
      expect(rows, hasLength(1));
      expect(rows.single.entityTable, 'expenses');
      expect(rows.single.recordId, expense.expenseId);
      expect(rows.single.operation, 'insert');

      final stamped = DateTime(2026, 10, 7, 12);
      await expenses.markSynced(expense.expenseId, stamped);
      final readBack = await expenses.getById(expense.expenseId);
      expect(readBack, isNotNull);
      expect(
        await _syncedAtOf(db, expense.expenseId),
        stamped,
        reason: 'markSynced should stamp the row’s syncedAt',
      );
    });
  });

  group('SyncService.drain', () {
    test('pushes parents before children, whatever the queue order is',
        () async {
      final pushed = <String>[];
      final sales = _FakePusher('sales', onPush: pushed.add);
      final batches = _FakePusher('batches', onPush: pushed.add);
      final service = serviceWith([sales, batches]);

      await queue.enqueue(
        entityTable: 'sales',
        recordId: 'sale-1',
        operation: 'insert',
      );
      await queue.enqueue(
        entityTable: 'batches',
        recordId: 'batch-1',
        operation: 'insert',
      );

      final result = await service.drain();

      expect(pushed, ['batch-1', 'sale-1']);
      expect(result.pushed, 2);
      expect(result.failed, 0);
      expect(await queue.pendingRows(), isEmpty,
          reason: 'pushed rows leave the queue');
      expect(await queue.pendingCount(), 0);
    });

    test('reports records that no longer exist locally and drops their rows',
        () async {
      final gone = _FakePusher('batches', reportDropped: true);
      final service = serviceWith([gone]);

      await queue.enqueue(
        entityTable: 'batches',
        recordId: 'batch-1',
        operation: 'insert',
      );

      final result = await service.drain();

      expect(result.dropped, 1);
      expect(result.pushed, 0);
      expect(result.allSucceeded, isTrue);
      expect(await queue.pendingRows(), isEmpty);
    });

    test('a rejected row is flagged, kept, and never retried', () async {
      final rejecting = _FakePusher(
        'mortality_entries',
        rejectedWith: 'mortality plus harvested exceeds the batch start',
      );
      final service = serviceWith([rejecting]);

      await queue.enqueue(
        entityTable: 'mortality_entries',
        recordId: 'mor-1',
        operation: 'insert',
      );

      final result = await service.drain();

      expect(result.rejected, 1);
      expect(result.failed, 0);
      expect(result.allSucceeded, isFalse);
      expect(result.errors.single, contains('mortality plus harvested'));

      // Rejected rows leave the pending list (so the next pass skips
      // them), but still count as unsynced for the logout warning.
      expect(await queue.pendingRows(), isEmpty);
      expect(await queue.pendingCount(), 1);

      final again = await service.drain();
      expect(again.isEmpty, isTrue, reason: 'rejected rows must not retry');
      expect(await queue.pendingCount(), 1,
          reason: 'the rejected row is still unsynced work');
    });

    test('keeps a failed row in the queue with the error recorded',
        () async {
      final failing = _FakePusher(
        'expenses',
        failWith: 'network is down',
      );
      final service = serviceWith([failing]);

      await queue.enqueue(
        entityTable: 'expenses',
        recordId: 'exp-1',
        operation: 'insert',
      );

      final result = await service.drain();

      expect(result.failed, 1);
      expect(result.pushed, 0);
      expect(result.allSucceeded, isFalse);
      expect(result.errors.single, contains('network is down'));

      final rows = await queue.pendingRows();
      expect(rows, hasLength(1));
      expect(rows.single.attempts, 1);
      expect(rows.single.lastError, contains('network is down'));
    });

    test('a second call joins the pass already running', () async {
      final pushed = <String>[];
      var releases = 0;
      final slow = _FakePusher(
        'batches',
        onPush: (id) {
          pushed.add(id);
          // Let both drain() calls race for the same future.
          releases++;
        },
      );
      final service = serviceWith([slow]);

      await queue.enqueue(
        entityTable: 'batches',
        recordId: 'batch-1',
        operation: 'insert',
      );

      final first = service.drain();
      final second = service.drain();
      expect(identical(first, second), isTrue);

      await Future.wait([first, second]);
      expect(pushed, hasLength(1), reason: 'the row must be pushed once');
      expect(releases, 1);
      expect(service.isDraining, isFalse);
    });

    test('an unknown table fails loudly instead of being dropped', () async {
      final service = serviceWith([_FakePusher('batches')]);

      await queue.enqueue(
        entityTable: 'ghosts',
        recordId: 'ghost-1',
        operation: 'insert',
      );

      final result = await service.drain();

      expect(result.failed, 1);
      expect(result.dropped, 0);
      expect(result.errors.single, contains('no pusher registered'));

      final rows = await queue.pendingRows();
      expect(rows, hasLength(1));
      expect(rows.single.lastError, contains('no pusher registered'));
    });

    test('an empty queue drains to an empty result', () async {
      final result = await serviceWith([]).drain();

      expect(result.isEmpty, isTrue);
      expect(result.allSucceeded, isTrue);
    });
  });
}

/// syncedAt as stored for one expense — read straight from Drift so the
/// test does not depend on the model exposing it.
Future<DateTime?> _syncedAtOf(AppDatabase db, String expenseId) async {
  final query = db.select(db.expenses)
    ..where((e) => e.expenseId.equals(expenseId));
  final row = await query.getSingle();
  return row.syncedAt;
}
