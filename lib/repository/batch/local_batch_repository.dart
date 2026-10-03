import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:broiler_fms/data/local/database.dart' as local;
import 'package:broiler_fms/domain/models/batch.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/local/database_provider.dart';

/// Batches stored on the device, used by the mobile app (Manager and
/// Staff). It talks only to Drift and always returns [Batch] objects.
///
/// V1 writes are limited to three actions: create, assign Staff, and
/// close. Editing a batch's own details after creation is not in scope.
class LocalBatchRepository {
  LocalBatchRepository(this._db);

  final local.AppDatabase _db;
  static const _uuid = Uuid();

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
    return batch;
  }

  /// Assigns a Staff account to a batch, or replaces the current one.
  Future<void> assignStaff(String batchId, String staffId) {
    return (_db.update(_db.batches)..where((b) => b.batchId.equals(batchId)))
        .write(local.BatchesCompanion(
      assignedStaffId: Value(staffId),
    ));
  }

  /// Closes a batch. No more entries can be logged against it afterwards.
  Future<void> close(String batchId, String closedBy) {
    return (_db.update(_db.batches)..where((b) => b.batchId.equals(batchId)))
        .write(local.BatchesCompanion(
      isClosed: const Value(true),
      closedBy: Value(closedBy),
      closedAt: Value(DateTime.now()),
    ));
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

  /// Standard [Batch] to the values Drift needs for an insert.
  local.BatchesCompanion _toCompanion(Batch b) {
    return local.BatchesCompanion(
      batchId: Value(b.batchId),
      businessId: Value(b.businessId),
      batchName: Value(b.batchName),
      startingBirdCount: Value(b.startingBirdCount),
      startDate: Value(b.startDate),
      isClosed: Value(b.isClosed),
      createdAt: Value(b.createdAt),
      breed: Value(b.breed),
      description: Value(b.description),
    );
  }
}


/// Builds a [LocalBatchRepository] wired to the shared Drift database.
/// Mobile only.
final localBatchRepositoryProvider = Provider<LocalBatchRepository>(
      (ref) => LocalBatchRepository(ref.watch(appDatabaseProvider)),
);