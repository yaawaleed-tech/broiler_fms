import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:broiler_fms/data/local/database.dart' as local;
import 'package:broiler_fms/domain/models/feed.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broiler_fms/data/local/database_provider.dart';
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/repository/shared/changed_rows.dart';

/// Feed entries stored on the device, used by the mobile app
/// (Staff only). It talks only to Drift and always returns [Feed]
/// objects.
class LocalFeedRepository {
  LocalFeedRepository(this._db);

  final local.AppDatabase _db;
  static const _uuid = Uuid();
  late final LocalSyncQueueRepository _syncQueueRepo =
      LocalSyncQueueRepository(_db);

  /// Overwrites the cache with feed entries just pulled from Supabase,
  /// mirroring LocalBatchRepository.upsertAll.
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
  Future<int> upsertAll(List<Feed> feeds) async {
    final pending =
        await _syncQueueRepo.pendingRecordIds(entityTable: 'feed_entries');
    final safe =
        feeds.where((item) => !pending.contains(item.feedEntryId)).toList();
    if (safe.isEmpty) return 0;
    final stored = await (_db.select(_db.feedEntries)
          ..where((f) => f.feedEntryId.isIn(safe.map((f) => f.feedEntryId))))
        .get();
    final existingById = {for (final row in stored) row.feedEntryId: _fromRow(row)};
    final changed = changedRows(
      safe,
      existingById,
      (f) => f.feedEntryId,
      _differs,
    );
    if (changed.isEmpty) return 0;
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.feedEntries,
        changed.map(_toCompanion).toList(),
      );
    });
    return changed.length;
  }

  /// True when [incoming] differs from what is already stored. Covers
  /// every column this table persists.
  bool _differs(Feed incoming, Feed stored) {
    return incoming.batchId != stored.batchId ||
        incoming.recordedBy != stored.recordedBy ||
        !sameStoredInstant(incoming.date, stored.date) ||
        incoming.quantity != stored.quantity ||
        !sameStoredInstant(incoming.recordedAt, stored.recordedAt);
  }

  /// Saves a new feed entry on the device and returns it.
  /// The id is created here so the entry works fully offline.
  Future<Feed> record({
    required String batchId,
    required String recordedBy,
    required DateTime date,
    required double quantity,
  }) async {
    final feed = Feed(
      feedEntryId: _uuid.v4(),
      batchId: batchId,
      recordedBy: recordedBy,
      date: date,
      quantity: quantity,
      recordedAt: DateTime.now(),
    );
    await _db.into(_db.feedEntries).insert(_toCompanion(feed));
    await _syncQueueRepo.enqueue(
      entityTable: 'feed_entries',
      recordId: feed.feedEntryId,
      operation: 'insert',
    );
    return feed;
  }

  /// All feed entries for one batch.
  Future<List<Feed>> getByBatch(String batchId) async {
    final query = _db.select(_db.feedEntries)
      ..where((f) => f.batchId.equals(batchId));
    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  /// Same as [getByBatch], but emits a new list whenever the data changes.
  Stream<List<Feed>> watchByBatch(String batchId) {
    final query = _db.select(_db.feedEntries)
      ..where((f) => f.batchId.equals(batchId));
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// One feed entry by id, or null if it isn't in local storage.
  Future<Feed?> getById(String feedEntryId) async {
    final query = _db.select(_db.feedEntries)
      ..where((f) => f.feedEntryId.equals(feedEntryId));
    final row = await query.getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Stamps [syncedAt] once the entry has reached Supabase.
  Future<void> markSynced(String feedEntryId, DateTime at) {
    final query = _db.update(_db.feedEntries)
      ..where((f) => f.feedEntryId.equals(feedEntryId));
    return query.write(local.FeedEntriesCompanion(syncedAt: Value(at)));
  }

  /// Drift row to the standard [Feed]. Lives here, not in the model,
  /// because the model must not import Drift.
  Feed _fromRow(local.FeedEntry row) {
    return Feed(
      feedEntryId: row.feedEntryId,
      batchId: row.batchId,
      recordedBy: row.recordedBy,
      date: row.date,
      quantity: row.quantity,
      recordedAt: row.recordedAt,
    );
  }

  /// Standard [Feed] to the values Drift needs for an insert.
  local.FeedEntriesCompanion _toCompanion(Feed f) {
    return local.FeedEntriesCompanion(
      feedEntryId: Value(f.feedEntryId),
      batchId: Value(f.batchId),
      recordedBy: Value(f.recordedBy),
      date: Value(f.date),
      quantity: Value(f.quantity),
      recordedAt: Value(f.recordedAt),
    );
  }
}


/// Builds a [LocalFeedRepository] wired to the shared Drift database.
/// Mobile only.
final localFeedRepositoryProvider = Provider<LocalFeedRepository>(
      (ref) => LocalFeedRepository(ref.watch(appDatabaseProvider)),
);