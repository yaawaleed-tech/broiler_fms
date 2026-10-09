import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/domain/models/mortality.dart';
import 'package:broiler_fms/domain/rules/bird_count_rule.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/repository/harvest/local_harvest_repository.dart';
import 'package:broiler_fms/repository/mortality/local_mortality_repository.dart';
import 'package:broiler_fms/repository/mortality/remote_mortality_repository.dart';

/// Mobile-side mortality actions, used by Staff.
///
/// Mirrors HarvestDomain closely on purpose: mortality and harvest are
/// the two ways birds leave a batch, and they share the exact same
/// bird-count rule, just recording a different kind of entry.
class MortalityDomain {
  MortalityDomain({
    required LocalMortalityRepository mortalityRepo,
    required RemoteMortalityRepository remoteMortalityRepo,
    required LocalBatchRepository batchRepo,
    required LocalHarvestRepository harvestRepo,
    required Account currentAccount,
  })  : _mortalityRepo = mortalityRepo,
        _remoteMortalityRepo = remoteMortalityRepo,
        _batchRepo = batchRepo,
        _harvestRepo = harvestRepo,
        _currentAccount = currentAccount;

  final LocalMortalityRepository _mortalityRepo;
  final RemoteMortalityRepository _remoteMortalityRepo;
  final LocalBatchRepository _batchRepo;
  final LocalHarvestRepository _harvestRepo;
  final Account _currentAccount;

  /// Records a mortality entry, after checking the batch is open and
  /// the bird count rule allows it.
  Future<Mortality> recordMortality({
    required String batchId,
    required DateTime date,
    required int count,
    String? description,
  }) async {
    final batch = await _loadOpenBatch(batchId);
    await _checkBirdsFit(batch, count);
    return _mortalityRepo.record(
      batchId: batchId,
      recordedBy: _currentAccount.accountId,
      date: date,
      count: count,
      description: description,
    );
  }

  /// All mortality entries for one batch.
  Future<List<Mortality>> getByBatch(String batchId) {
    return _mortalityRepo.getByBatch(batchId);
  }

  /// Same as [getByBatch], but emits a new list whenever the data
  /// changes.
  Stream<List<Mortality>> watchByBatch(String batchId) {
    return _mortalityRepo.watchByBatch(batchId);
  }

  /// Pulls the latest mortality entries from Supabase and overwrites
  /// the local cache — same contract as BatchDomain.refreshBatches():
  /// needs connectivity, RLS scopes the rows to this account's own
  /// business (Staff: only assigned batches), and nothing enqueues
  /// because this data already lives on the server.
  Future<void> refreshMortalityEntries() async {
    final mortalities = await _remoteMortalityRepo.getAll();
    await _mortalityRepo.upsertAll(mortalities);
  }

  /// Loads the batch, and throws if it is missing or already closed.
  Future<Batch> _loadOpenBatch(String batchId) async {
    final batch = await _batchRepo.getById(batchId);
    if (batch == null) {
      throw const DomainException('This batch could not be found.');
    }
    if (batch.isClosed) {
      throw const DomainException(
        'This batch is closed, so no more mortality can be recorded.',
      );
    }
    return batch;
  }

  /// Throws if [count] more birds would exceed the batch's starting
  /// count.
  Future<void> _checkBirdsFit(Batch batch, int count) async {
    final mortality = await _totalMortality(batch.batchId);
    final harvested = await _totalHarvested(batch.batchId);
    final fits = canRecordBirdCount(
      startingBirdCount: batch.startingBirdCount,
      currentMortalityTotal: mortality,
      currentHarvestTotal: harvested,
      additionalCount: count,
    );
    if (fits) return;
    final left = remainingBirdCount(
      startingBirdCount: batch.startingBirdCount,
      currentMortalityTotal: mortality,
      currentHarvestTotal: harvested,
    );
    throw DomainException(
      'Only $left birds remain in this batch.',
    );
  }

  /// Total birds recorded as dead in the batch so far.
  Future<int> _totalMortality(String batchId) async {
    final entries = await _mortalityRepo.getByBatch(batchId);
    return entries.fold<int>(0, (sum, entry) => sum + entry.count);
  }

  /// Total birds already harvested from the batch so far.
  Future<int> _totalHarvested(String batchId) async {
    final entries = await _harvestRepo.getByBatch(batchId);
    return entries.fold<int>(0, (sum, entry) => sum + entry.birdCount);
  }
}

/// Builds a [MortalityDomain] for the currently signed-in account.
/// Throws if nobody is resolved as signed in yet.
final mortalityDomainProvider = Provider<MortalityDomain>((ref) {
  final currentAccount = ref.watch(currentAccountProvider).value;
  if (currentAccount == null) {
    throw const DomainException('No account is currently signed in.');
  }
  return MortalityDomain(
    mortalityRepo: ref.watch(localMortalityRepositoryProvider),
    remoteMortalityRepo: ref.watch(remoteMortalityRepositoryProvider),
    batchRepo: ref.watch(localBatchRepositoryProvider),
    harvestRepo: ref.watch(localHarvestRepositoryProvider),
    currentAccount: currentAccount,
  );
});