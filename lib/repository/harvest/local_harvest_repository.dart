import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:broiler_fms/data/local/database.dart' as local;
import 'package:broiler_fms/domain/models/harvest.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';

import 'package:broiler_fms/data/local/database_provider.dart';

/// Harvest entries stored on the device, used by the mobile app (Staff and
/// Manager). It talks only to Drift and always returns [Harvest] objects.
///
/// Getting these entries up to Supabase is the Sync Engine's job, not this
/// class's.
class LocalHarvestRepository {
  LocalHarvestRepository(this._db);

  final local.AppDatabase _db;
  static const _uuid = Uuid();
  late final LocalSyncQueueRepository _syncQueueRepo =
      LocalSyncQueueRepository(_db);

  /// Overwrites the cache with harvest entries just pulled from
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
  Future<int> upsertAll(List<Harvest> harvests) async {
    final pending =
        await _syncQueueRepo.pendingRecordIds(entityTable: 'harvest_entries');
    final safe =
        harvests.where((item) => !pending.contains(item.harvestId)).toList();
    if (safe.isEmpty) return 0;
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.harvestEntries,
        safe.map(_toCompanion).toList(),
      );
    });
    return safe.length;
  }

  /// Saves a new harvest entry on the device and returns it.
  /// The id is created here so the entry works fully offline.
  Future<Harvest> record({
    required String batchId,
    required String recordedBy,
    required DateTime date,
    required int birdCount,
  }) async {
    final harvest = Harvest(
      harvestId: _uuid.v4(),
      batchId: batchId,
      recordedBy: recordedBy,
      date: date,
      birdCount: birdCount,
      recordedAt: DateTime.now(),
    );
    await _db.into(_db.harvestEntries).insert(_toCompanion(harvest));
    await _syncQueueRepo.enqueue(
      entityTable: 'harvest_entries',
      recordId: harvest.harvestId,
      operation: 'insert',
    );
    return harvest;
  }

  /// All harvest entries for one batch.
  Future<List<Harvest>> getByBatch(String batchId) async {
    final query = _db.select(_db.harvestEntries)
      ..where((h) => h.batchId.equals(batchId));
    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  /// One harvest entry by id, or null if it isn't in local storage.
  Future<Harvest?> getById(String harvestId) async {
    final query = _db.select(_db.harvestEntries)
      ..where((h) => h.harvestId.equals(harvestId));
    final row = await query.getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Stamps [syncedAt] once the entry has reached Supabase.
  Future<void> markSynced(String harvestId, DateTime at) {
    final query = _db.update(_db.harvestEntries)
      ..where((h) => h.harvestId.equals(harvestId));
    return query.write(local.HarvestEntriesCompanion(syncedAt: Value(at)));
  }

  /// Same as [getByBatch], but emits a new list whenever the data changes.
  Stream<List<Harvest>> watchByBatch(String batchId) {
    final query = _db.select(_db.harvestEntries)
      ..where((h) => h.batchId.equals(batchId));
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Drift row to the standard [Harvest]. Lives here, not in the model,
  /// because the model must not import Drift (it would break the web build).
  Harvest _fromRow(local.HarvestEntry row) {
    return Harvest(
      harvestId: row.harvestId,
      batchId: row.batchId,
      recordedBy: row.recordedBy,
      date: row.date,
      birdCount: row.birdCount,
      recordedAt: row.recordedAt,
    );
  }

  /// Standard [Harvest] to the values Drift needs for an insert.
  local.HarvestEntriesCompanion _toCompanion(Harvest h) {
    return local.HarvestEntriesCompanion(
      harvestId: Value(h.harvestId),
      batchId: Value(h.batchId),
      recordedBy: Value(h.recordedBy),
      date: Value(h.date),
      birdCount: Value(h.birdCount),
      recordedAt: Value(h.recordedAt),
    );
  }
}


/// Builds a [LocalHarvestRepository] wired to the shared Drift
/// database. Mobile only, same rule as every local repository
/// provider, never imported from anything the web build can reach.
final localHarvestRepositoryProvider = Provider<LocalHarvestRepository>(
      (ref) => LocalHarvestRepository(ref.watch(appDatabaseProvider)),
);