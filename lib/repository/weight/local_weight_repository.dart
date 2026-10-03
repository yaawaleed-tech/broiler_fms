import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:broiler_fms/data/local/database.dart' as local;
import 'package:broiler_fms/domain/models/weight_sample.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broiler_fms/data/local/database_provider.dart';

/// Weight samples stored on the device, used by the mobile app
/// (Staff only). It talks only to Drift and always returns
/// [WeightSample] objects.
class LocalWeightRepository {
  LocalWeightRepository(this._db);

  final local.AppDatabase _db;
  static const _uuid = Uuid();

  /// Saves a new weight sample on the device and returns it.
  /// The id is created here so the sample works fully offline.
  Future<WeightSample> record({
    required String batchId,
    required String recordedBy,
    required DateTime date,
    required double sampleWeight,
    required int sampleCount,
  }) async {
    final sample = WeightSample(
      weightSampleId: _uuid.v4(),
      batchId: batchId,
      recordedBy: recordedBy,
      date: date,
      sampleWeight: sampleWeight,
      sampleCount: sampleCount,
      recordedAt: DateTime.now(),
    );
    await _db.into(_db.weightSamples).insert(_toCompanion(sample));
    return sample;
  }

  /// All weight samples for one batch.
  Future<List<WeightSample>> getByBatch(String batchId) async {
    final query = _db.select(_db.weightSamples)
      ..where((w) => w.batchId.equals(batchId));
    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  /// Same as [getByBatch], but emits a new list whenever the data changes.
  Stream<List<WeightSample>> watchByBatch(String batchId) {
    final query = _db.select(_db.weightSamples)
      ..where((w) => w.batchId.equals(batchId));
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Drift row to the standard [WeightSample]. Lives here, not in the
  /// model, because the model must not import Drift.
  WeightSample _fromRow(local.WeightSample row) {
    return WeightSample(
      weightSampleId: row.weightSampleId,
      batchId: row.batchId,
      recordedBy: row.recordedBy,
      date: row.date,
      sampleWeight: row.sampleWeight,
      sampleCount: row.sampleCount,
      recordedAt: row.recordedAt,
    );
  }

  /// Standard [WeightSample] to the values Drift needs for an insert.
  local.WeightSamplesCompanion _toCompanion(WeightSample w) {
    return local.WeightSamplesCompanion(
      weightSampleId: Value(w.weightSampleId),
      batchId: Value(w.batchId),
      recordedBy: Value(w.recordedBy),
      date: Value(w.date),
      sampleWeight: Value(w.sampleWeight),
      sampleCount: Value(w.sampleCount),
      recordedAt: Value(w.recordedAt),
    );
  }
}


/// Builds a [LocalWeightRepository] wired to the shared Drift database.
/// Mobile only.
final localWeightRepositoryProvider = Provider<LocalWeightRepository>(
      (ref) => LocalWeightRepository(ref.watch(appDatabaseProvider)),
);
