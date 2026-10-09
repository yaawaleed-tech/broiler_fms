import 'package:broiler_fms/data/local/database.dart' show SyncQueueData;
import 'package:broiler_fms/domain/models/feed.dart';
import 'package:broiler_fms/repository/feed/local_feed_repository.dart';
import 'package:broiler_fms/sync/pushers/entity_pusher.dart';
import 'package:broiler_fms/sync/sync_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pushes queued feed entries to Supabase's `feed_entry` table.
class FeedPusher extends EntityPusher {
  FeedPusher(this._local);

  final LocalFeedRepository _local;

  @override
  String get entityTable => 'feed_entries';

  @override
  Future<SyncPushResult> push(SyncQueueData row, SupabaseClient client) async {
    final feed = await _local.getById(row.recordId);
    if (feed == null) return const SyncPushDropped();

    try {
      await client.from('feed_entry').upsert(_payload(feed));
      await _local.markSynced(row.recordId, DateTime.now());
      return const SyncPushSuccess();
    } on PostgrestException catch (e) {
      return SyncPushFailure(e.message);
    } catch (e) {
      return SyncPushFailure(e.toString());
    }
  }

  Map<String, dynamic> _payload(Feed f) {
    return {
      'feed_entry_id': f.feedEntryId,
      'batch_id': f.batchId,
      'recorded_by': f.recordedBy,
      'date': dateOnly(f.date),
      'quantity': f.quantity,
      'recorded_at': f.recordedAt.toIso8601String(),
    };
  }
}


/// Builds a [FeedPusher] for the sync engine. Mobile only.
final feedPusherProvider = Provider<FeedPusher>(
      (ref) => FeedPusher(ref.watch(localFeedRepositoryProvider)),
);
