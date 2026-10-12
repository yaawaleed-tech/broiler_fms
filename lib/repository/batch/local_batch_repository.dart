import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:broiler_fms/data/local/database.dart' as local;
import 'package:broiler_fms/domain/models/batch.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/local/database_provider.dart';
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';

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
  /// Returns how many rows were actually written into the cache.
  Future<int> upsertAll(List<Batch> batches) async {
    final pending =
        await _syncQueueRepo.pendingRecordIds(entityTable: 'batches');
    final safe =
        batches.where((item) => !pending.contains(item.batchId)).toList();
    if (safe.isEmpty) return 0;
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.batches,
        safe.map(_toCompanion).toList(),
      );
    });
    return safe.length;
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
      ..where((b) => b.assignedStaffId.equals(staffId));
    return query.watch().map((rows) => rows.map(_fromRow).toList());
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