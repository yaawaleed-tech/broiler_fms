import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:broiler_fms/data/local/database.dart' as local;
import 'package:broiler_fms/domain/models/mortality.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/local/database_provider.dart';

/// Mortality entries stored on the device, used by the mobile app
/// (Staff only). It talks only to Drift and always returns [Mortality]
/// objects.
class LocalMortalityRepository {
  LocalMortalityRepository(this._db);

  final local.AppDatabase _db;
  static const _uuid = Uuid();

  /// Saves a new mortality entry on the device and returns it.
  /// The id is created here so the entry works fully offline.
  Future<Mortality> record({
    required String batchId,
    required String recordedBy,
    required DateTime date,
    required int count,
    String? description,
  }) async {
    final mortality = Mortality(
      mortalityId: _uuid.v4(),
      batchId: batchId,
      recordedBy: recordedBy,
      date: date,
      count: count,
      recordedAt: DateTime.now(),
      description: description,
    );
    await _db.into(_db.mortalityEntries).insert(_toCompanion(mortality));
    return mortality;
  }

  /// All mortality entries for one batch.
  Future<List<Mortality>> getByBatch(String batchId) async {
    final query = _db.select(_db.mortalityEntries)
      ..where((m) => m.batchId.equals(batchId));
    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  /// Same as [getByBatch], but emits a new list whenever the data changes.
  Stream<List<Mortality>> watchByBatch(String batchId) {
    final query = _db.select(_db.mortalityEntries)
      ..where((m) => m.batchId.equals(batchId));
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Drift row to the standard [Mortality]. Lives here, not in the
  /// model, because the model must not import Drift.
  Mortality _fromRow(local.MortalityEntry row) {
    return Mortality(
      mortalityId: row.mortalityId,
      batchId: row.batchId,
      recordedBy: row.recordedBy,
      date: row.date,
      count: row.count,
      recordedAt: row.recordedAt,
      description: row.description,
    );
  }

  /// Standard [Mortality] to the values Drift needs for an insert.
  local.MortalityEntriesCompanion _toCompanion(Mortality m) {
    return local.MortalityEntriesCompanion(
      mortalityId: Value(m.mortalityId),
      batchId: Value(m.batchId),
      recordedBy: Value(m.recordedBy),
      date: Value(m.date),
      count: Value(m.count),
      recordedAt: Value(m.recordedAt),
      description: Value(m.description),
    );
  }
}


/// Builds a [LocalMortalityRepository] wired to the shared Drift
/// database. Mobile only.
final localMortalityRepositoryProvider = Provider<LocalMortalityRepository>(
      (ref) => LocalMortalityRepository(ref.watch(appDatabaseProvider)),
);