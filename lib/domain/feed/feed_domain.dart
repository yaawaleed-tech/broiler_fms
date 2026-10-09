import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/models/feed.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/repository/feed/local_feed_repository.dart';
import 'package:broiler_fms/repository/feed/remote_feed_repository.dart';

/// Mobile-side feed actions, used by Staff.
///
/// No bird-count rule applies here, feed does not change how many
/// birds are in a batch. Only the open-batch check applies.
class FeedDomain {
  FeedDomain({
    required LocalFeedRepository feedRepo,
    required RemoteFeedRepository remoteFeedRepo,
    required LocalBatchRepository batchRepo,
    required Account currentAccount,
  })  : _feedRepo = feedRepo,
        _remoteFeedRepo = remoteFeedRepo,
        _batchRepo = batchRepo,
        _currentAccount = currentAccount;

  final LocalFeedRepository _feedRepo;
  final RemoteFeedRepository _remoteFeedRepo;
  final LocalBatchRepository _batchRepo;
  final Account _currentAccount;

  /// Records a feed entry, after checking the batch is open.
  Future<Feed> recordFeed({
    required String batchId,
    required DateTime date,
    required double quantity,
  }) async {
    await _checkBatchOpen(batchId);
    return _feedRepo.record(
      batchId: batchId,
      recordedBy: _currentAccount.accountId,
      date: date,
      quantity: quantity,
    );
  }

  /// All feed entries for one batch.
  Future<List<Feed>> getByBatch(String batchId) {
    return _feedRepo.getByBatch(batchId);
  }

  /// Same as [getByBatch], but emits a new list whenever the data
  /// changes.
  Stream<List<Feed>> watchByBatch(String batchId) {
    return _feedRepo.watchByBatch(batchId);
  }

  /// Pulls the latest feed entries from Supabase and overwrites the
  /// local cache — same contract as BatchDomain.refreshBatches():
  /// needs connectivity, RLS scopes the rows to this account's own
  /// business (Staff: only assigned batches), and nothing enqueues
  /// because this data already lives on the server.
  Future<void> refreshFeedEntries() async {
    final feeds = await _remoteFeedRepo.getAll();
    await _feedRepo.upsertAll(feeds);
  }

  /// Throws if the batch is missing or already closed.
  Future<void> _checkBatchOpen(String batchId) async {
    final batch = await _batchRepo.getById(batchId);
    if (batch == null) {
      throw const DomainException('This batch could not be found.');
    }
    if (batch.isClosed) {
      throw const DomainException(
        'This batch is closed, so no more feed can be recorded.',
      );
    }
  }
}

/// Builds a [FeedDomain] for the currently signed-in account. Throws if
/// nobody is resolved as signed in yet.
final feedDomainProvider = Provider<FeedDomain>((ref) {
  final currentAccount = ref.watch(currentAccountProvider).value;
  if (currentAccount == null) {
    throw const DomainException('No account is currently signed in.');
  }
  return FeedDomain(
    feedRepo: ref.watch(localFeedRepositoryProvider),
    remoteFeedRepo: ref.watch(remoteFeedRepositoryProvider),
    batchRepo: ref.watch(localBatchRepositoryProvider),
    currentAccount: currentAccount,
  );
});