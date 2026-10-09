import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/domain/models/feed.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broiler_fms/data/remote/supabase_provider.dart';
/// Feed entries read straight from Supabase, used by the web app
/// (Admin), and by mobile's FeedDomain.refreshFeedEntries() at login.
/// It always returns [Feed] objects.
///
/// Read-only by design: Admin never records a feed entry, and there is
/// no local database on the web.
class RemoteFeedRepository {
  RemoteFeedRepository(this._client);

  final SupabaseClient _client;

  /// All feed entries the signed-in account is allowed to see, oldest
  /// first. RLS scopes this to the account's own business (and to
  /// assigned batches for Staff), so no filter is needed by hand.
  Future<List<Feed>> getAll() async {
    final rows = await _client.from('feed_entry').select().order('date');
    return rows.map(Feed.fromJson).toList();
  }

  /// All feed entries for one batch.
  Future<List<Feed>> getByBatch(String batchId) async {
    final rows = await _client
        .from('feed_entry')
        .select()
        .eq('batch_id', batchId)
        .order('date');
    return rows.map(Feed.fromJson).toList();
  }
}


/// Builds a [RemoteFeedRepository] wired to the shared Supabase client,
/// for web Admin's read-only feed views and for mobile's login-time
/// cache refresh.
final remoteFeedRepositoryProvider = Provider<RemoteFeedRepository>(
      (ref) => RemoteFeedRepository(ref.watch(supabaseClientProvider)),
);
