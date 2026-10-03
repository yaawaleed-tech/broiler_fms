import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:broiler_fms/data/local/database.dart' as local;
import 'package:broiler_fms/domain/models/feed.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broiler_fms/data/local/database_provider.dart';

/// Feed entries stored on the device, used by the mobile app
/// (Staff only). It talks only to Drift and always returns [Feed]
/// objects.
class LocalFeedRepository {
  LocalFeedRepository(this._db);

  final local.AppDatabase _db;
  static const _uuid = Uuid();

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