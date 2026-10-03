import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/models/feed.dart';
import 'package:broiler_fms/repository/feed/remote_feed_repository.dart';

/// Web-side feed reads, used by Admin. Read-only on purpose, Admin
/// never records a feed entry, only Staff does, through [FeedDomain]
/// on mobile.
class RemoteFeedDomain {
  RemoteFeedDomain(this._feedRepo);

  final RemoteFeedRepository _feedRepo;

  /// All feed entries for one batch.
  Future<List<Feed>> getByBatch(String batchId) {
    return _feedRepo.getByBatch(batchId);
  }
}

/// Builds a [RemoteFeedDomain] wired to the shared Supabase client.
/// Web only, since Admin is the only role that uses this class.
final remoteFeedDomainProvider = Provider<RemoteFeedDomain>(
      (ref) => RemoteFeedDomain(ref.watch(remoteFeedRepositoryProvider)),
);