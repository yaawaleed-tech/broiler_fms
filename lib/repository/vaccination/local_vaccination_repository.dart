import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:broiler_fms/data/local/database.dart' as local;
import 'package:broiler_fms/domain/models/vaccination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broiler_fms/data/local/database_provider.dart';
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';

/// Vaccination entries stored on the device, used by the mobile app
/// (Staff only). It talks only to Drift and always returns
/// [Vaccination] objects.
class LocalVaccinationRepository {
  LocalVaccinationRepository(this._db);

  final local.AppDatabase _db;
  static const _uuid = Uuid();
  late final LocalSyncQueueRepository _syncQueueRepo =
      LocalSyncQueueRepository(_db);

  /// Overwrites the cache with vaccination entries just pulled from
  /// Supabase, mirroring LocalBatchRepository.upsertAll.
  ///
  /// Deliberately never touches the sync queue: the enqueue() call
  /// lives inside the local-origin write below (record), which has to
  /// travel up. This is the opposite direction — data that is already
  /// on the server — and queuing it would loop pointless pushes.
  ///
  /// Any entry whose id is still queued is skipped entirely, so a local
  /// record the server has not accepted yet is never replaced by the
  /// server's older copy of the same row. Returns how many rows were
  /// actually written into the cache.
  Future<int> upsertAll(List<Vaccination> vaccinations) async {
    final pending = await _syncQueueRepo.pendingRecordIds(
      entityTable: 'vaccination_entries',
    );
    final safe = vaccinations
        .where((item) => !pending.contains(item.vaccinationId))
        .toList();
    if (safe.isEmpty) return 0;
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.vaccinationEntries,
        safe.map(_toCompanion).toList(),
      );
    });
    return safe.length;
  }

  /// Saves a new vaccination entry on the device and returns it.
  /// The id is created here so the entry works fully offline.
  Future<Vaccination> record({
    required String batchId,
    required String recordedBy,
    required DateTime date,
    required String vaccineName,
  }) async {
    final vaccination = Vaccination(
      vaccinationId: _uuid.v4(),
      batchId: batchId,
      recordedBy: recordedBy,
      date: date,
      vaccineName: vaccineName,
      recordedAt: DateTime.now(),
    );
    await _db
        .into(_db.vaccinationEntries)
        .insert(_toCompanion(vaccination));
    await _syncQueueRepo.enqueue(
      entityTable: 'vaccination_entries',
      recordId: vaccination.vaccinationId,
      operation: 'insert',
    );
    return vaccination;
  }

  /// All vaccination entries for one batch.
  Future<List<Vaccination>> getByBatch(String batchId) async {
    final query = _db.select(_db.vaccinationEntries)
      ..where((v) => v.batchId.equals(batchId));
    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  /// Same as [getByBatch], but emits a new list whenever the data changes.
  Stream<List<Vaccination>> watchByBatch(String batchId) {
    final query = _db.select(_db.vaccinationEntries)
      ..where((v) => v.batchId.equals(batchId));
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// One vaccination entry by id, or null if it isn't in local storage.
  Future<Vaccination?> getById(String vaccinationId) async {
    final query = _db.select(_db.vaccinationEntries)
      ..where((v) => v.vaccinationId.equals(vaccinationId));
    final row = await query.getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Stamps [syncedAt] once the entry has reached Supabase.
  Future<void> markSynced(String vaccinationId, DateTime at) {
    final query = _db.update(_db.vaccinationEntries)
      ..where((v) => v.vaccinationId.equals(vaccinationId));
    return query
        .write(local.VaccinationEntriesCompanion(syncedAt: Value(at)));
  }

  /// Drift row to the standard [Vaccination]. Lives here, not in the
  /// model, because the model must not import Drift.
  Vaccination _fromRow(local.VaccinationEntry row) {
    return Vaccination(
      vaccinationId: row.vaccinationId,
      batchId: row.batchId,
      recordedBy: row.recordedBy,
      date: row.date,
      vaccineName: row.vaccineName,
      recordedAt: row.recordedAt,
    );
  }

  /// Standard [Vaccination] to the values Drift needs for an insert.
  local.VaccinationEntriesCompanion _toCompanion(Vaccination v) {
    return local.VaccinationEntriesCompanion(
      vaccinationId: Value(v.vaccinationId),
      batchId: Value(v.batchId),
      recordedBy: Value(v.recordedBy),
      date: Value(v.date),
      vaccineName: Value(v.vaccineName),
      recordedAt: Value(v.recordedAt),
    );
  }
}


/// Builds a [LocalVaccinationRepository] wired to the shared Drift
/// database. Mobile only.
final localVaccinationRepositoryProvider =
Provider<LocalVaccinationRepository>(
      (ref) => LocalVaccinationRepository(ref.watch(appDatabaseProvider)),
);