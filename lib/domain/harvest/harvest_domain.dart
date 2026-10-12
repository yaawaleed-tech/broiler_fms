import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/domain/models/harvest.dart';
import 'package:broiler_fms/domain/rules/bird_count_rule.dart';
import 'package:broiler_fms/domain/rules/staff_assignment_rule.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/repository/harvest/local_harvest_repository.dart';
import 'package:broiler_fms/repository/harvest/remote_harvest_repository.dart';
import 'package:broiler_fms/repository/mortality/local_mortality_repository.dart';
import 'package:broiler_fms/domain/current_account_domain.dart';

/// Mobile-side harvest actions, used by Staff.
///
/// Presentation calls this class and never a repository directly. It
/// reads what it needs, applies the rules, then writes through the
/// repository. [recordedBy] is never passed in by the caller, it is
/// always this device's own resolved current account, so it can never
/// be typed wrong or left out.
class HarvestDomain {
  HarvestDomain({
    required LocalHarvestRepository harvestRepo,
    required RemoteHarvestRepository remoteHarvestRepo,
    required LocalBatchRepository batchRepo,
    required LocalMortalityRepository mortalityRepo,
    required Account currentAccount,
  })  : _harvestRepo = harvestRepo,
        _remoteHarvestRepo = remoteHarvestRepo,
        _batchRepo = batchRepo,
        _mortalityRepo = mortalityRepo,
        _currentAccount = currentAccount;

  final LocalHarvestRepository _harvestRepo;
  final RemoteHarvestRepository _remoteHarvestRepo;
  final LocalBatchRepository _batchRepo;
  final LocalMortalityRepository _mortalityRepo;
  final Account _currentAccount;

  /// Records a harvest, after checking the batch is open and the bird
  /// count rule allows it.
  Future<Harvest> recordHarvest({
    required String batchId,
    required DateTime date,
    required int birdCount,
  }) async {
    final batch = await _loadOpenBatch(batchId);
    await _checkBirdsFit(batch, birdCount);
    return _harvestRepo.record(
      batchId: batchId,
      recordedBy: _currentAccount.accountId,
      date: date,
      birdCount: birdCount,
    );
  }

  /// All harvest entries for one batch.
  Future<List<Harvest>> getByBatch(String batchId) {
    return _harvestRepo.getByBatch(batchId);
  }

  /// Same as [getByBatch], but emits a new list whenever the data
  /// changes.
  Stream<List<Harvest>> watchByBatch(String batchId) {
    return _harvestRepo.watchByBatch(batchId);
  }


  /// One harvest entry by id, or null if it isn't in local storage.
  /// A thin public wrapper around the repository's own method, since
  /// Presentation is never allowed to call a repository directly.
  Future<Harvest?> getById(String harvestId) {
    return _harvestRepo.getById(harvestId);
  }

  /// Pulls the latest harvest entries from Supabase and overwrites
  /// the local cache — same contract as BatchDomain.refreshBatches():
  /// needs connectivity, RLS scopes the rows to this account's own
  /// business (Staff: only assigned batches), and nothing enqueues
  /// because this data already lives on the server.
  ///
  /// Returns how many rows were written into the cache.
  Future<int> refreshHarvestEntries() async {
    final harvests = await _remoteHarvestRepo.getAll();
    return _harvestRepo.upsertAll(harvests);
  }

  /// Loads the batch, and throws if it is missing, already closed, or
  /// assigned to a Staff member (a Manager must not write entries into
  /// someone else's batch).
  Future<Batch> _loadOpenBatch(String batchId) async {
    final batch = await _batchRepo.getById(batchId);
    if (batch == null) {
      throw const DomainException('This batch could not be found.');
    }
    if (batch.isClosed) {
      throw const DomainException(
        'This batch is closed, so no more harvests can be recorded.',
      );
    }
    if (!canRecordEntryForBatch(
      role: _currentAccount.role,
      assignedStaffId: batch.assignedStaffId,
    )) {
      throw const DomainException(
        'This batch is assigned to a staff member. Only they can record entries.',
      );
    }
    return batch;
  }

  /// Throws if [birdCount] more birds would exceed the batch's
  /// starting count.
  Future<void> _checkBirdsFit(Batch batch, int birdCount) async {
    final mortality = await _totalMortality(batch.batchId);
    final harvested = await _totalHarvested(batch.batchId);
    final fits = canRecordBirdCount(
      startingBirdCount: batch.startingBirdCount,
      currentMortalityTotal: mortality,
      currentHarvestTotal: harvested,
      additionalCount: birdCount,
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

/// Builds a [HarvestDomain] for the currently signed-in account.
/// Throws if nobody is resolved as signed in yet, since every harvest
/// action needs to know who is recording it.
final harvestDomainProvider = Provider<HarvestDomain>((ref) {
  final currentAccount = ref.watch(currentAccountProvider).value;
  if (currentAccount == null) {
    throw const DomainException('No account is currently signed in.');
  }
  return HarvestDomain(
    harvestRepo: ref.watch(localHarvestRepositoryProvider),
    remoteHarvestRepo: ref.watch(remoteHarvestRepositoryProvider),
    batchRepo: ref.watch(localBatchRepositoryProvider),
    mortalityRepo: ref.watch(localMortalityRepositoryProvider),
    currentAccount: currentAccount,
  );
});