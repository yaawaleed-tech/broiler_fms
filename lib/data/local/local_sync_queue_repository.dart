import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'database_provider.dart';

/// Repository for the sync queue. Other repositories call `enqueue()`
/// inside their own write transactions; the sync engine (later phase)
/// calls `pendingRows()` and `markSynced()` / `markFailed()`.
class LocalSyncQueueRepository {
  LocalSyncQueueRepository(this._db);

  final AppDatabase _db;

  /// Enqueue a sync entry. MUST be called inside the same transaction as
  /// the source row's own insert/update — pass the same `Batch`/etc.
  /// transaction context if the project's repositories use `_db.transaction()`.
  Future<void> enqueue({
    required String entityTable,
    required String recordId,
    required String operation, // 'insert' or 'update'
  }) {
    return _db.into(_db.syncQueue).insert(
      SyncQueueCompanion.insert(
        entityTable: entityTable,
        recordId: recordId,
        operation: operation,
      ),
    );
  }

  /// All rows still pending push, oldest first (FK-safe ordering is
  /// applied by the sync engine on top of this, not here). Rejected
  /// rows are excluded: the server has said no for good, and drain()
  /// must never pick them up again.
  Future<List<SyncQueueData>> pendingRows() {
    return (_db.select(_db.syncQueue)
          ..where((t) => t.rejected.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  /// Total unsynced count — used by countUnsyncedRows() (Phase 4).
  ///
  /// Deliberately *not* filtered by rejected: a rejected row is still
  /// a row that never reached Supabase, so logout must keep warning
  /// about it.
  Future<int> pendingCount() async {
    final count = _db.syncQueue.id.count();
    final query = _db.selectOnly(_db.syncQueue)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// How many of those rows still have a chance of reaching Supabase:
  /// everything pending or failed, with the rejected rows excluded.
  ///
  /// Rejected rows (the bird-count trigger, D5) can never resolve on
  /// their own, so they must not hard-block logout — they only feed
  /// the informational warning from [pendingCount()].
  Future<int> blockingCount() async {
    final count = _db.syncQueue.id.count();
    final query = _db.selectOnly(_db.syncQueue)
      ..addColumns([count])
      ..where(_db.syncQueue.rejected.equals(false));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Call after a successful push — removes the queue row.
  Future<void> markSynced(int queueRowId) {
    return (_db.delete(_db.syncQueue)..where((t) => t.id.equals(queueRowId)))
        .go();
  }

  /// Call after a failed push — increments attempts, stores the error.
  ///
  /// Read-increment-write: Drift's `update` has no atomic increment,
  /// so we read the row, add 1 in Dart, then write it back.
  Future<void> markFailed(int queueRowId, String error) async {
    final row = await (_db.select(_db.syncQueue)
          ..where((t) => t.id.equals(queueRowId)))
        .getSingle();
    await (_db.update(_db.syncQueue)..where((t) => t.id.equals(queueRowId)))
        .write(SyncQueueCompanion(
      attempts: Value(row.attempts + 1),
      lastError: Value(error),
    ));
  }

  /// Call when the server rejects a row for good (e.g. the bird-count
  /// trigger fired) — records the error and flags the row so
  /// pendingRows() never returns it again. The row itself is kept so
  /// logout still counts it as unsynced work.
  Future<void> markRejected(int queueRowId, String error) {
    return (_db.update(_db.syncQueue)..where((t) => t.id.equals(queueRowId))).write(
      SyncQueueCompanion(rejected: const Value(true), lastError: Value(error)),
    );
  }
}


/// Builds a [LocalSyncQueueRepository] wired to the shared Drift database.
/// Mobile only — the queue is purely local bookkeeping.
final localSyncQueueRepositoryProvider = Provider<LocalSyncQueueRepository>(
      (ref) => LocalSyncQueueRepository(ref.watch(appDatabaseProvider)),
);
