import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/domain/models/financial_summary.dart';
import 'package:broiler_fms/domain/rules/batch_closure_rule.dart';
import 'package:broiler_fms/domain/rules/financial_summary_rule.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/repository/batch/remote_batch_repository.dart';
import 'package:broiler_fms/repository/expense/local_expense_repository.dart';
import 'package:broiler_fms/repository/feed/local_feed_repository.dart';
import 'package:broiler_fms/repository/harvest/local_harvest_repository.dart';
import 'package:broiler_fms/repository/mortality/local_mortality_repository.dart';
import 'package:broiler_fms/repository/sale/local_sale_repository.dart';
import 'package:broiler_fms/repository/weight/local_weight_repository.dart';
import 'package:broiler_fms/domain/rules/bird_count_rule.dart';

/// Mobile-side batch actions, used by Manager and Staff.
///
/// Presentation calls this class and never a repository directly.
/// [businessId] on create and [closedBy] on close are never passed in
/// by the caller, both come from this device's own resolved current
/// account.
class BatchDomain {
  BatchDomain({
    required LocalBatchRepository batchRepo,
    required RemoteBatchRepository remoteBatchRepo,
    required LocalHarvestRepository harvestRepo,
    required LocalMortalityRepository mortalityRepo,
    required LocalExpenseRepository expenseRepo,
    required LocalSaleRepository saleRepo,
    required LocalFeedRepository feedRepo,
    required LocalWeightRepository weightRepo,
    required Account currentAccount,
  })  : _batchRepo = batchRepo,
        _remoteBatchRepo = remoteBatchRepo,
        _harvestRepo = harvestRepo,
        _mortalityRepo = mortalityRepo,
        _expenseRepo = expenseRepo,
        _saleRepo = saleRepo,
        _feedRepo = feedRepo,
        _weightRepo = weightRepo,
        _currentAccount = currentAccount;

  final LocalBatchRepository _batchRepo;
  final RemoteBatchRepository _remoteBatchRepo;
  final LocalHarvestRepository _harvestRepo;
  final LocalMortalityRepository _mortalityRepo;
  final LocalExpenseRepository _expenseRepo;
  final LocalSaleRepository _saleRepo;
  final LocalFeedRepository _feedRepo;
  final LocalWeightRepository _weightRepo;
  final Account _currentAccount;

  /// Registers a new batch for the current account's own business.
  Future<Batch> createBatch({
    required String batchName,
    required int startingBirdCount,
    required DateTime startDate,
    String? breed,
    String? description,
  }) {
    final businessId = _currentAccount.businessId;
    if (businessId == null) {
      throw const DomainException(
        'This account is not linked to a business yet.',
      );
    }
    return _batchRepo.create(
      businessId: businessId,
      batchName: batchName,
      startingBirdCount: startingBirdCount,
      startDate: startDate,
      breed: breed,
      description: description,
    );
  }

  /// Assigns a Staff account to a batch, or replaces the current one.
  /// Passing a null [staffId] clears the assignment and leaves the
  /// batch running with nobody on it.
  Future<void> assignStaff(String batchId, String? staffId) {
    return _batchRepo.assignStaff(batchId, staffId);
  }

  /// Closes a batch, after checking every bird has been accounted for.
  /// closedBy is always this device's own resolved current account.
  Future<void> closeBatch(String batchId) async {
    final batch = await _loadBatch(batchId);
    await _checkFullyAccountedFor(batch);
    return _batchRepo.close(batchId, _currentAccount.accountId);
  }

  /// Reopens a closed batch, after checking it is actually closed.
  /// Clears the close stamp (closedBy / closedAt) along with the flag.
  ///
  /// Manager-only by convention, not by a check here: same as
  /// [closeBatch] and [assignStaff], the role lives in Presentation
  /// (the button only shows for Manager) and RLS is the server-side
  /// backstop.
  Future<void> reopenBatch(String batchId) async {
    final batch = await _loadBatch(batchId);
    if (!batch.isClosed) {
      throw const DomainException('This batch is not closed, so there is nothing to reopen.');
    }
    return _batchRepo.reopen(batchId);
  }

  /// All batches in the business. For Manager, who sees everything.
  Future<List<Batch>> getAllForBusiness(String businessId) {
    return _batchRepo.getAllForBusiness(businessId);
  }

  /// Same as [getAllForBusiness], but emits a new list when data changes.
  Stream<List<Batch>> watchAllForBusiness(String businessId) {
    return _batchRepo.watchAllForBusiness(businessId);
  }

  /// The batch(es) assigned to one Staff account. Staff sees only these.
  Future<List<Batch>> getForStaff(String staffId) {
    return _batchRepo.getForStaff(staffId);
  }

  /// Same as [getForStaff], but emits a new list when data changes.
  Stream<List<Batch>> watchForStaff(String staffId) {
    return _batchRepo.watchForStaff(staffId);
  }

  /// One batch by id, or null if it isn't in local storage.
  Future<Batch?> getById(String batchId) {
    return _batchRepo.getById(batchId);
  }

  /// Pulls the latest batches from Supabase and overwrites the local
  /// cache — the batch counterpart to AccountDomain.refreshStaffPool().
  /// Needs connectivity; RLS returns only the rows this signed-in
  /// account is allowed to see, for every role, so nothing is filtered
  /// by hand here, and nothing enqueues: this data already lives on
  /// the server and must never be pushed back up.
  ///
  /// Returns how many rows were written into the cache, after
  /// [LocalBatchRepository.upsertAll] skips any batch still queued for
  /// push, plus how many were released because the server stopped
  /// returning them to this account.
  Future<int> refreshBatches() async {
    final batches = await _remoteBatchRepo.getAll();
    final written = await _batchRepo.upsertAll(batches);
    // Only reached once getAll has returned, so a failed pull throws
    // above and never marks anything. The ids come from the same
    // response that was just applied, so a batch the server still
    // returns is never mistaken for a reassigned one.
    final released = await _batchRepo.releaseMissing(
      accountId: _currentAccount.accountId,
      serverBatchIds: batches.map((b) => b.batchId).toSet(),
    );
    return written + released;
  }


  /// How many birds in this batch have not yet been harvested or
  /// recorded as mortality. Recomputed fresh on every call, not
  /// cached, since the underlying entries can change between calls.
  Future<int> getRemainingBirdCount(String batchId) async {
    final batch = await _loadBatch(batchId);
    final mortality = await _totalMortality(batch.batchId);
    final harvested = await _totalHarvested(batch.batchId);
    return remainingBirdCount(
      startingBirdCount: batch.startingBirdCount,
      currentMortalityTotal: mortality,
      currentHarvestTotal: harvested,
    );
  }


  /// Total birds recorded as dead in this batch so far. A thin public
  /// wrapper around the same total [closeBatch] already checks
  /// internally, exposed here for batch detail screens to display.
  Future<int> getTotalMortality(String batchId) => _totalMortality(batchId);

  /// Total birds already harvested from this batch so far. A thin
  /// public wrapper around the same total [closeBatch] already checks
  /// internally, exposed here for batch detail screens to display.
  Future<int> getTotalHarvested(String batchId) => _totalHarvested(batchId);

  /// Total birds in harvests that have no sale yet, so their price is
  /// still owed. A thin public wrapper around the same total the
  /// financial summary uses, exposed here so batch detail can say how
  /// many birds are waiting to be priced without opening the price page.
  Future<int> getTotalAwaitingPrice(String batchId) =>
      _totalAwaitingPrice(batchId);

  /// The computed financial picture for one batch: expenses, revenue,
  /// profit or loss, breakeven price, and an approximate FCR.
  Future<FinancialSummary> getFinancialSummary(String batchId) async {
    final totalExpenses = await _totalExpenses(batchId);
    final totalRevenue = await _totalRevenue(batchId);
    final totalHarvestedBirds = await _totalHarvested(batchId);
    final totalFeedKg = await _totalFeedKg(batchId);
    final latestAverageWeight = await _latestAverageSampleWeight(batchId);
    // Birds still available to sell: the same remaining count the batch
    // detail screen shows. Reuses the total harvested already fetched
    // above; a missing batch counts as zero rather than throwing, which
    // is how this whole method has always behaved for an unknown id.
    final batch = await _batchRepo.getById(batchId);
    final birdsInStock = remainingBirdCount(
      startingBirdCount: batch?.startingBirdCount ?? 0,
      currentMortalityTotal: await _totalMortality(batchId),
      currentHarvestTotal: totalHarvestedBirds,
    );
    // Harvested birds with no sale recorded yet still have to earn
    // their share, so they stay in the break-even denominator. A
    // gift_cull (amount 0) counts as priced and leaves the count.
    final birdsAwaitingPrice = await _totalAwaitingPrice(batchId);
    final stillToPrice = birdsStillToPrice(
      birdsInStock: birdsInStock,
      birdsAwaitingPrice: birdsAwaitingPrice,
    );

    return FinancialSummary(
      totalExpenses: totalExpenses,
      totalRevenue: totalRevenue,
      profitLoss: profitLoss(
        totalRevenue: totalRevenue,
        totalExpenses: totalExpenses,
      ),
      breakevenPricePerBird: breakevenPricePerBird(
        totalExpenses: totalExpenses,
        totalRevenue: totalRevenue,
        birdsStillToPrice: stillToPrice,
      ),
      approximateFcr: latestAverageWeight == null
          ? null
          : approximateFcr(
        totalFeedKg: totalFeedKg,
        latestAverageSampleWeight: latestAverageWeight,
        totalHarvestedBirds: totalHarvestedBirds,
      ),
      birdsInStock: birdsInStock,
      birdsAwaitingPrice: birdsAwaitingPrice,
      birdsStillToPrice: stillToPrice,
    );
  }

  /// Loads the batch, and throws if it isn't in local storage.
  Future<Batch> _loadBatch(String batchId) async {
    final batch = await _batchRepo.getById(batchId);
    if (batch == null) {
      throw const DomainException('This batch could not be found.');
    }
    return batch;
  }

  /// Throws if any birds in [batch] are still unaccounted for.
  Future<void> _checkFullyAccountedFor(Batch batch) async {
    final mortality = await _totalMortality(batch.batchId);
    final harvested = await _totalHarvested(batch.batchId);
    final canClose = canCloseBatch(
      startingBirdCount: batch.startingBirdCount,
      currentMortalityTotal: mortality,
      currentHarvestTotal: harvested,
    );
    if (canClose) return;
    final remaining = unaccountedBirdCount(
      startingBirdCount: batch.startingBirdCount,
      currentMortalityTotal: mortality,
      currentHarvestTotal: harvested,
    );
    throw DomainException(
      '$remaining birds are still unaccounted for, so this batch cannot be closed yet.',
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

  /// Total birds in harvest entries that have no sale recorded yet.
  /// These still have to earn their share, so the break-even keeps
  /// them in its denominator. A harvest with any sale — including a
  /// gift_cull at ₦0 — counts as priced.
  Future<int> _totalAwaitingPrice(String batchId) async {
    final harvests = await _harvestRepo.getByBatch(batchId);
    var awaiting = 0;
    for (final harvest in harvests) {
      final sales = await _saleRepo.getByHarvest(harvest.harvestId);
      if (sales.isEmpty) awaiting += harvest.birdCount;
    }
    return awaiting;
  }

  /// Total money spent on the batch so far, across every expense
  /// entry regardless of category.
  Future<double> _totalExpenses(String batchId) async {
    final entries = await _expenseRepo.getByBatch(batchId);
    return entries.fold<double>(0, (sum, entry) => sum + entry.amount);
  }

  /// Total money earned from the batch so far. Goes through every
  /// harvest first, since a Sale references a Harvest, not a Batch,
  /// directly.
  Future<double> _totalRevenue(String batchId) async {
    final harvests = await _harvestRepo.getByBatch(batchId);
    var total = 0.0;
    for (final harvest in harvests) {
      final sales = await _saleRepo.getByHarvest(harvest.harvestId);
      for (final sale in sales) {
        total += sale.amount;
      }
    }
    return total;
  }

  /// Total kilograms of feed given to the batch so far.
  Future<double> _totalFeedKg(String batchId) async {
    final entries = await _feedRepo.getByBatch(batchId);
    return entries.fold<double>(0, (sum, entry) => sum + entry.quantity);
  }

  /// Average bird weight from the most recent weight sample, or null
  /// if no sample has been recorded yet.
  Future<double?> _latestAverageSampleWeight(String batchId) async {
    final samples = await _weightRepo.getByBatch(batchId);
    if (samples.isEmpty) return null;
    samples.sort((a, b) => b.date.compareTo(a.date));
    final latest = samples.first;
    if (latest.sampleCount == 0) return null;
    return latest.sampleWeight / latest.sampleCount;
  }
}

/// Builds a [BatchDomain] for the currently signed-in account. Throws
/// if nobody is resolved as signed in yet.
final batchDomainProvider = Provider<BatchDomain>((ref) {
  final currentAccount = ref.watch(currentAccountProvider).value;
  if (currentAccount == null) {
    throw const DomainException('No account is currently signed in.');
  }
  return BatchDomain(
    batchRepo: ref.watch(localBatchRepositoryProvider),
    remoteBatchRepo: ref.watch(remoteBatchRepositoryProvider),
    harvestRepo: ref.watch(localHarvestRepositoryProvider),
    mortalityRepo: ref.watch(localMortalityRepositoryProvider),
    expenseRepo: ref.watch(localExpenseRepositoryProvider),
    saleRepo: ref.watch(localSaleRepositoryProvider),
    feedRepo: ref.watch(localFeedRepositoryProvider),
    weightRepo: ref.watch(localWeightRepositoryProvider),
    currentAccount: currentAccount,
  );
});