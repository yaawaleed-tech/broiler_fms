import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:broiler_fms/data/local/database.dart' as local;
import 'package:broiler_fms/domain/models/vaccination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broiler_fms/data/local/database_provider.dart';

/// Vaccination entries stored on the device, used by the mobile app
/// (Staff only). It talks only to Drift and always returns
/// [Vaccination] objects.
class LocalVaccinationRepository {
  LocalVaccinationRepository(this._db);

  final local.AppDatabase _db;
  static const _uuid = Uuid();

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