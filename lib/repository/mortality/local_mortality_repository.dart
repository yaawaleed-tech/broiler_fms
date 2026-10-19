import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:broiler_fms/data/local/database.dart' as local;
import 'package:broiler_fms/domain/models/mortality.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broiler_fms/data/local/database_provider.dart';
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/repository/shared/changed_rows.dart';

/// Mortality entries stored on the device, used by the mobile app
/// (Staff only). It talks only to Drift and always returns [Mortality]
/// objects.
class LocalMortalityRepository {
  LocalMortalityRepository(this._db);

  final local.AppDatabase _db;
  static const _uuid = Uuid();
  late final LocalSyncQueueRepository _syncQueueRepo =
      LocalSyncQueueRepository(_db);

  /// Overwrites the cache with mortality entries just pulled from
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
  Future<int> upsertAll(List<Mortality> mortalities) async {
    final pending = await _syncQueueRepo.pendingRecordIds(
      entityTable: 'mortality_entries',
    );
    final safe = mortalities
        .where((item) => !pending.contains(item.mortalityId))
        .toList();
    if (safe.isEmpty) return 0;
    final stored = await (_db.select(_db.mortalityEntries)
          ..where((m) => m.mortalityId.isIn(safe.map((m) => m.mortalityId))))
        .get();
    final existingById = {
      for (final row in stored) row.mortalityId: _fromRow(row),
    };
    final changed = changedRows(
      safe,
      existingById,
      (m) => m.mortalityId,
      _differs,
    );
    if (changed.isEmpty) return 0;
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.mortalityEntries,
        changed.map(_toCompanion).toList(),
      );
    });
    return changed.length;
  }

  /// True when [incoming] differs from what is already stored. Covers
  /// every column this table persists.
  bool _differs(Mortality incoming, Mortality stored) {
    return incoming.batchId != stored.batchId ||
        incoming.recordedBy != stored.recordedBy ||
        !sameStoredInstant(incoming.date, stored.date) ||
        incoming.count != stored.count ||
        incoming.description != stored.description ||
        !sameStoredInstant(incoming.recordedAt, stored.recordedAt);
  }

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
    await _syncQueueRepo.enqueue(
      entityTable: 'mortality_entries',
      recordId: mortality.mortalityId,
      operation: 'insert',
    );
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

  /// One mortality entry by id, or null if it isn't in local storage.
  Future<Mortality?> getById(String mortalityId) async {
    final query = _db.select(_db.mortalityEntries)
      ..where((m) => m.mortalityId.equals(mortalityId));
    final row = await query.getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Stamps [syncedAt] once the entry has reached Supabase.
  Future<void> markSynced(String mortalityId, DateTime at) {
    final query = _db.update(_db.mortalityEntries)
      ..where((m) => m.mortalityId.equals(mortalityId));
    return query.write(local.MortalityEntriesCompanion(syncedAt: Value(at)));
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