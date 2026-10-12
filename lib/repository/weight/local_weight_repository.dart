import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:broiler_fms/data/local/database.dart' as local;
import 'package:broiler_fms/domain/models/weight_sample.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broiler_fms/data/local/database_provider.dart';
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';

/// Weight samples stored on the device, used by the mobile app
/// (Staff only). It talks only to Drift and always returns
/// [WeightSample] objects.
class LocalWeightRepository {
  LocalWeightRepository(this._db);

  final local.AppDatabase _db;
  static const _uuid = Uuid();
  late final LocalSyncQueueRepository _syncQueueRepo =
      LocalSyncQueueRepository(_db);

  /// Overwrites the cache with weight samples just pulled from
  /// Supabase, mirroring LocalBatchRepository.upsertAll.
  ///
  /// Deliberately never touches the sync queue: the enqueue() call
  /// lives inside the local-origin write below (record), which has to
  /// travel up. This is the opposite direction — data that is already
  /// on the server — and queuing it would loop pointless pushes.
  ///
  /// Any sample whose id is still queued is skipped entirely, so a local
  /// record the server has not accepted yet is never replaced by the
  /// server's older copy of the same row. Returns how many rows were
  /// actually written into the cache.
  Future<int> upsertAll(List<WeightSample> samples) async {
    final pending =
        await _syncQueueRepo.pendingRecordIds(entityTable: 'weight_samples');
    final safe =
        samples.where((item) => !pending.contains(item.weightSampleId)).toList();
    if (safe.isEmpty) return 0;
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.weightSamples,
        safe.map(_toCompanion).toList(),
      );
    });
    return safe.length;
  }

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
    await _syncQueueRepo.enqueue(
      entityTable: 'weight_samples',
      recordId: sample.weightSampleId,
      operation: 'insert',
    );
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

  /// One weight sample by id, or null if it isn't in local storage.
  Future<WeightSample?> getById(String weightSampleId) async {
    final query = _db.select(_db.weightSamples)
      ..where((w) => w.weightSampleId.equals(weightSampleId));
    final row = await query.getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Stamps [syncedAt] once the sample has reached Supabase.
  Future<void> markSynced(String weightSampleId, DateTime at) {
    final query = _db.update(_db.weightSamples)
      ..where((w) => w.weightSampleId.equals(weightSampleId));
    return query.write(local.WeightSamplesCompanion(syncedAt: Value(at)));
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
