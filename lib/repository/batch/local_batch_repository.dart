// drift exports its own `Batch` (a bulk-operation helper), which collides
// with this app's Batch model imported below. Hiding it is enough to keep
// the query-builder operators that a where-clause needs.
import 'package:drift/drift.dart' hide Batch;
import 'package:uuid/uuid.dart';

import 'package:broiler_fms/data/local/database.dart' as local;
import 'package:broiler_fms/domain/models/batch.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/local/database_provider.dart';
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/repository/shared/changed_rows.dart';

/// Batches stored on the device, used by the mobile app (Manager and
/// Staff). It talks only to Drift and always returns [Batch] objects.
///
/// V1 writes are limited to three actions: create, assign Staff, and
/// close. Editing a batch's own details after creation is not in scope.
class LocalBatchRepository {
  LocalBatchRepository(this._db);

  final local.AppDatabase _db;
  static const _uuid = Uuid();
  late final LocalSyncQueueRepository _syncQueueRepo =
      LocalSyncQueueRepository(_db);

  /// Overwrites the cache with batches just pulled from Supabase,
  /// mirroring LocalAccountRepository.upsertAll.
  ///
  /// Deliberately never touches the sync queue: the enqueue() calls
  /// live only inside the local-origin writes below (create, assign,
  /// close), which have to travel up. This is the opposite direction —
  /// data that is already on the server — and queuing it would loop
  /// pointless pushes, which for Staff would fail forever anyway: they
  /// have no RLS UPDATE on batch.
  ///
  /// Any batch whose id is still queued is skipped entirely. A batch
  /// created offline, or one whose assignment or close is still waiting
  /// to be pushed, must not be overwritten by the server's older copy of
  /// the same row, or the pending edit would be silently lost and then
  /// pushed back up in its stale form.
  ///
  /// Only rows that are new, or whose stored values actually differ from
  /// the server's copy, are written — so a pull that changes nothing
  /// reports nothing instead of re-reporting every row it read. Returns
  /// how many rows were genuinely new or different.
  Future<int> upsertAll(List<Batch> batches) async {
    final pending =
        await _syncQueueRepo.pendingRecordIds(entityTable: 'batches');
    final safe =
        batches.where((item) => !pending.contains(item.batchId)).toList();
    if (safe.isEmpty) return 0;
    final stored = await (_db.select(_db.batches)
          ..where((b) => b.batchId.isIn(safe.map((b) => b.batchId))))
        .get();
    final existingById = {for (final row in stored) row.batchId: _fromRow(row)};
    final changed = changedRows(
      safe,
      existingById,
      (b) => b.batchId,
      _differs,
    );
    if (changed.isEmpty) return 0;
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.batches,
        changed.map(_toCompanion).toList(),
      );
    });
    return changed.length;
  }

  /// True when [incoming] differs from what is already stored.
  ///
  /// Covers every column this table persists, and nothing else:
  /// [Batch.assignedStaffName] and [Batch.closedByName] are joined in by
  /// the remote read but are not local columns, so comparing them would
  /// call every pulled batch changed on every pull.
  bool _differs(Batch incoming, Batch stored) {
    return incoming.businessId != stored.businessId ||
        incoming.batchName != stored.batchName ||
        incoming.startingBirdCount != stored.startingBirdCount ||
        !sameStoredInstant(incoming.startDate, stored.startDate) ||
        incoming.isClosed != stored.isClosed ||
        !sameStoredInstant(incoming.createdAt, stored.createdAt) ||
        incoming.assignedStaffId != stored.assignedStaffId ||
        incoming.closedBy != stored.closedBy ||
        incoming.breed != stored.breed ||
        incoming.description != stored.description ||
        !sameStoredInstant(incoming.closedAt, stored.closedAt);
  }

  /// Registers a new batch. Starts unassigned and open.
  Future<Batch> create({
    required String businessId,
    required String batchName,
    required int startingBirdCount,
    required DateTime startDate,
    String? breed,
    String? description,
  }) async {
    final batch = Batch(
      batchId: _uuid.v4(),
      businessId: businessId,
      batchName: batchName,
      startingBirdCount: startingBirdCount,
      startDate: startDate,
      isClosed: false,
      createdAt: DateTime.now(),
      breed: breed,
      description: description,
    );
    await _db.into(_db.batches).insert(_toCompanion(batch));
    await _syncQueueRepo.enqueue(
      entityTable: 'batches',
      recordId: batch.batchId,
      operation: 'insert',
    );
    return batch;
  }

  /// Assigns a Staff account to a batch, or replaces the current one.
  /// A null [staffId] clears the assignment.
  Future<void> assignStaff(String batchId, String? staffId) {
    final result = (_db.update(_db.batches)..where((b) => b.batchId.equals(batchId)))
        .write(local.BatchesCompanion(
      assignedStaffId: Value(staffId),
    ));
    return result.then((_) async {
      await _syncQueueRepo.enqueue(
        entityTable: 'batches',
        recordId: batchId,
        operation: 'update',
      );
    });
  }

  /// Closes a batch. No more entries can be logged against it afterwards.
  Future<void> close(String batchId, String closedBy) {
    final result = (_db.update(_db.batches)..where((b) => b.batchId.equals(batchId)))
        .write(local.BatchesCompanion(
      isClosed: const Value(true),
      closedBy: Value(closedBy),
      closedAt: Value(DateTime.now()),
    ));
    return result.then((_) async {
      await _syncQueueRepo.enqueue(
        entityTable: 'batches',
        recordId: batchId,
        operation: 'update',
      );
    });
  }

  /// Reopens a closed batch, clearing the close stamp. The mirror image
  /// of [close]: entries can be recorded against it again, and the
  /// record of who closed it and when is gone with the stamp.
  Future<void> reopen(String batchId) {
    final result = (_db.update(_db.batches)..where((b) => b.batchId.equals(batchId)))
        .write(local.BatchesCompanion(
      isClosed: const Value(false),
      closedBy: const Value(null),
      closedAt: const Value(null),
    ));
    return result.then((_) async {
      await _syncQueueRepo.enqueue(
        entityTable: 'batches',
        recordId: batchId,
        operation: 'update',
      );
    });
  }

  /// All batches in the business. For Manager, who sees everything.
  Future<List<Batch>> getAllForBusiness(String businessId) async {
    final query = _db.select(_db.batches)
      ..where((b) => b.businessId.equals(businessId));
    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  /// Same as [getAllForBusiness], but emits a new list when data changes.
  Stream<List<Batch>> watchAllForBusiness(String businessId) {
    final query = _db.select(_db.batches)
      ..where((b) => b.businessId.equals(businessId));
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// The batch(es) assigned to one Staff account. Staff sees only these.
  Future<List<Batch>> getForStaff(String staffId) async {
    final query = _db.select(_db.batches)
      ..where((b) => b.assignedStaffId.equals(staffId));
    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  /// Same as [getForStaff], but emits a new list when data changes.
  Stream<List<Batch>> watchForStaff(String staffId) {
    final query = _db.select(_db.batches)
      ..where((b) =>
          b.assignedStaffId.equals(staffId) | b.assignedStaffId.isNull());
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Releases this Staff member's batches that the server no longer
  /// returns to them, by clearing their assignment locally.
  ///
  /// A Staff account only ever sees the batches assigned to it, so a
  /// batch that has gone missing from that response has been reassigned
  /// to somebody else. Clearing the assignment keeps the row on the
  /// device — the entries and history stay — and lets the screen show
  /// it as read-only instead of letting it vanish mid-session.
  ///
  /// Guarded three ways, so this can only ever mark, never destroy:
  ///   * only rows currently assigned to [accountId] are touched;
  ///   * only rows whose id is absent from [serverBatchIds];
  ///   * any row still waiting in the sync queue is skipped outright, so
  ///     a batch this device created and has not pushed yet is never
  ///     mistaken for one the server dropped.
  ///
  /// Writes [Batch.assignedStaffId] and nothing else, and enqueues
  /// nothing: this is a local record of a decision the server already
  /// made, so pushing it back would be pushing the absence of an
  /// assignment the server has already forgotten about. Returns how
  /// many rows were changed.
  Future<int> releaseMissing({
    required String accountId,
    required Set<String> serverBatchIds,
  }) async {
    final pending =
        await _syncQueueRepo.pendingRecordIds(entityTable: 'batches');
    // Anything the server still returns, plus anything this device has
    // not pushed yet, is a row to KEEP. A row is released only when it
    // is in neither set.
    final keep = <String>{...serverBatchIds, ...pending};
    final released = await (_db.update(_db.batches)
          ..where((b) =>
              b.assignedStaffId.equals(accountId) &
              // An empty keep-set must mean "every row of this account",
              // so it is spelled as a skipped clause rather than the
              // "in ()" SQLite rejects.
              (keep.isEmpty
                  ? const Constant(true)
                  : b.batchId.isNotIn(keep))))
        .write(const local.BatchesCompanion(assignedStaffId: Value(null)));
    return released;
  }

  /// One batch by id, or null if it isn't in local storage.
  Future<Batch?> getById(String batchId) async {
    final query = _db.select(_db.batches)
      ..where((b) => b.batchId.equals(batchId));
    final row = await query.getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }
  /// Drift row to the standard [Batch]. Lives here, not in the model,
  /// because the model must not import Drift (it would break the web build).
  Batch _fromRow(local.Batch row) {
    return Batch(
      batchId: row.batchId,
      businessId: row.businessId,
      batchName: row.batchName,
      startingBirdCount: row.startingBirdCount,
      startDate: row.startDate,
      isClosed: row.isClosed,
      createdAt: row.createdAt,
      assignedStaffId: row.assignedStaffId,
      closedBy: row.closedBy,
      breed: row.breed,
      description: row.description,
      closedAt: row.closedAt,
    );
  }

  /// Standard [Batch] to the values Drift needs for an insert or an
  /// upsert. Every column is present on purpose: a column absent from
  /// the companion keeps its old value on conflict-update and falls to
  /// its default on insert, which would silently drop an assignment
  /// or a close that only exists on the server.
  local.BatchesCompanion _toCompanion(Batch b) {
    return local.BatchesCompanion(
      batchId: Value(b.batchId),
      businessId: Value(b.businessId),
      batchName: Value(b.batchName),
      startingBirdCount: Value(b.startingBirdCount),
      startDate: Value(b.startDate),
      isClosed: Value(b.isClosed),
      createdAt: Value(b.createdAt),
      assignedStaffId: Value(b.assignedStaffId),
      closedBy: Value(b.closedBy),
      breed: Value(b.breed),
      description: Value(b.description),
      closedAt: Value(b.closedAt),
    );
  }
}


/// Builds a [LocalBatchRepository] wired to the shared Drift database.
/// Mobile only.
final localBatchRepositoryProvider = Provider<LocalBatchRepository>(
      (ref) => LocalBatchRepository(ref.watch(appDatabaseProvider)),
);