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

  /// The record ids of every row still sitting in the queue, optionally
  /// narrowed to a single entity table.
  ///
  /// This is what protects local intent from being clobbered by a pull:
  /// a row whose id is in here has a local change the server has not
  /// seen yet, so a server copy of the same record must not overwrite
  /// it. See [LocalBatchRepository.upsertAll] for the one place that
  /// consumes this.
  ///
  /// Rejected rows are included on purpose. They will never be pushed
  /// again, but they are still local records, and this set answers
  /// "leave these alone", not "these will be pushed".
  Future<Set<String>> pendingRecordIds({String? entityTable}) async {
    final query = _db.selectOnly(_db.syncQueue)
      ..addColumns([_db.syncQueue.recordId]);
    if (entityTable != null) {
      query.where(_db.syncQueue.entityTable.equals(entityTable));
    }
    final rows = await query.get();
    return rows.map((row) => row.read(_db.syncQueue.recordId)!).toSet();
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

  /// The same count as [pendingCount], but as a live Drift query
  /// rather than a one-shot read.
  ///
  /// Drift re-runs this whenever the sync queue table changes in any
  /// way, so it emits on the enqueue insert that starts a batch of
  /// pending work, on the delete [markSynced] does when a row reaches
  /// Supabase, and on the update [markFailed] / [markRejected] write.
  /// That is the whole reason it exists: every code path that changes
  /// how much work is outstanding shows up here without that path
  /// having to tell anyone about it.
  ///
  /// Same deliberate absence of a rejected filter as [pendingCount] —
  /// this is the same number, watched instead of polled.
  Stream<int> watchPendingCount() {
    final count = _db.syncQueue.id.count();
    final query = _db.selectOnly(_db.syncQueue)..addColumns([count]);
    return query.watchSingle().map((row) => row.read(count) ?? 0);
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
