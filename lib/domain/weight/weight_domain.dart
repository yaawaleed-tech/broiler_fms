import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/models/weight_sample.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/repository/weight/local_weight_repository.dart';
import 'package:broiler_fms/repository/weight/remote_weight_repository.dart';

/// Mobile-side weight sample actions, used by Staff.
///
/// No bird-count rule applies here, a weight sample does not change
/// how many birds are in a batch. Only the open-batch check applies.
class WeightDomain {
  WeightDomain({
    required LocalWeightRepository weightRepo,
    required RemoteWeightRepository remoteWeightRepo,
    required LocalBatchRepository batchRepo,
    required Account currentAccount,
  })  : _weightRepo = weightRepo,
        _remoteWeightRepo = remoteWeightRepo,
        _batchRepo = batchRepo,
        _currentAccount = currentAccount;

  final LocalWeightRepository _weightRepo;
  final RemoteWeightRepository _remoteWeightRepo;
  final LocalBatchRepository _batchRepo;
  final Account _currentAccount;

  /// Records a weight sample, after checking the batch is open.
  Future<WeightSample> recordWeightSample({
    required String batchId,
    required DateTime date,
    required double sampleWeight,
    required int sampleCount,
  }) async {
    await _checkBatchOpen(batchId);
    return _weightRepo.record(
      batchId: batchId,
      recordedBy: _currentAccount.accountId,
      date: date,
      sampleWeight: sampleWeight,
      sampleCount: sampleCount,
    );
  }

  /// All weight samples for one batch.
  Future<List<WeightSample>> getByBatch(String batchId) {
    return _weightRepo.getByBatch(batchId);
  }

  /// Same as [getByBatch], but emits a new list whenever the data
  /// changes.
  Stream<List<WeightSample>> watchByBatch(String batchId) {
    return _weightRepo.watchByBatch(batchId);
  }

  /// Pulls the latest weight samples from Supabase and overwrites the
  /// local cache — same contract as BatchDomain.refreshBatches():
  /// needs connectivity, RLS scopes the rows to this account's own
  /// business (Staff: only assigned batches), and nothing enqueues
  /// because this data already lives on the server.
  Future<void> refreshWeightSamples() async {
    final samples = await _remoteWeightRepo.getAll();
    await _weightRepo.upsertAll(samples);
  }

  /// Throws if the batch is missing or already closed.
  Future<void> _checkBatchOpen(String batchId) async {
    final batch = await _batchRepo.getById(batchId);
    if (batch == null) {
      throw const DomainException('This batch could not be found.');
    }
    if (batch.isClosed) {
      throw const DomainException(
        'This batch is closed, so no more weight samples can be recorded.',
      );
    }
  }
}

/// Builds a [WeightDomain] for the currently signed-in account. Throws
/// if nobody is resolved as signed in yet.
final weightDomainProvider = Provider<WeightDomain>((ref) {
  final currentAccount = ref.watch(currentAccountProvider).value;
  if (currentAccount == null) {
    throw const DomainException('No account is currently signed in.');
  }
  return WeightDomain(
    weightRepo: ref.watch(localWeightRepositoryProvider),
    remoteWeightRepo: ref.watch(remoteWeightRepositoryProvider),
    batchRepo: ref.watch(localBatchRepositoryProvider),
    currentAccount: currentAccount,
  );
});