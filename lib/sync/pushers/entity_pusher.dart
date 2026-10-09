import 'package:broiler_fms/data/local/database.dart' show SyncQueueData;
import 'package:broiler_fms/sync/sync_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pushes one kind of queued record to Supabase.
///
/// One pusher per syncable table, registered against the queue's own
/// [EntityPusher.entityTable] value. Those values are the plural local
/// table names ('harvest_entries') while Supabase's tables are
/// singular ('harvest_entry'), so each pusher owns that mapping
/// instead of deriving the remote name from the queue row.
///
/// A pusher only reads: it loads the record through its local
/// repository, turns it into a Supabase row and upserts it. Removing
/// the queue row belongs to the sync service, once the push returns.
///
/// Upsert rather than insert-or-update on purpose: it keys on the
/// primary key, so a retry after an ambiguous failure lands in the same
/// place instead of erroring on a duplicate, and an 'update' queue row
/// for a batch that Supabase has never seen still arrives.
abstract class EntityPusher {
  /// The `entityTable` value this pusher answers for.
  String get entityTable;

  /// Upserts the record named by `row.recordId` and reports how it went.
  ///
  /// Everything that can go wrong becomes a [SyncPushResult], not a
  /// throw: [SyncPushFailure] for anything retryable, and the two
  /// pushers whose tables carry the bird-count trigger return
  /// [SyncPushRejected] when the server refuses a row for good.
  Future<SyncPushResult> push(SyncQueueData row, SupabaseClient client);
}

/// A calendar date as `yyyy-MM-dd`, the shape a Postgres `date` column
/// takes.
///
/// Sent without its time part on purpose: a date picked on the phone is
/// a calendar day, and sending it as a bare date is the one format that
/// reads back as the same day whatever the column's exact type or the
/// server's timezone turns out to be.
String dateOnly(DateTime date) => date.toIso8601String().substring(0, 10);
