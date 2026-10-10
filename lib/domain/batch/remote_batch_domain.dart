import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/domain/models/financial_summary.dart';
import 'package:broiler_fms/domain/rules/financial_summary_rule.dart';
import 'package:broiler_fms/repository/batch/remote_batch_repository.dart';
import 'package:broiler_fms/repository/expense/remote_expense_repository.dart';
import 'package:broiler_fms/repository/feed/remote_feed_repository.dart';
import 'package:broiler_fms/repository/harvest/remote_harvest_repository.dart';
import 'package:broiler_fms/repository/mortality/remote_mortality_repository.dart';
import 'package:broiler_fms/repository/sale/remote_sale_repository.dart';
import 'package:broiler_fms/repository/weight/remote_weight_repository.dart';
import 'package:broiler_fms/domain/rules/bird_count_rule.dart';

/// Web-side batch reads, used by Admin. Read-only on purpose, Admin
/// never creates, assigns, or closes a batch, only Manager does,
/// through [BatchDomain] on mobile.
///
/// Also computes the same financial summary [BatchDomain] does on
/// mobile, using the identical formulas from
/// rules/financial_summary_rule.dart, but gathering its totals from
/// Supabase instead of Drift.
class RemoteBatchDomain {
  RemoteBatchDomain({
    required RemoteBatchRepository batchRepo,
    required RemoteHarvestRepository harvestRepo,
    required RemoteExpenseRepository expenseRepo,
    required RemoteSaleRepository saleRepo,
    required RemoteFeedRepository feedRepo,
    required RemoteWeightRepository weightRepo,
    required RemoteMortalityRepository mortalityRepo,
  })  : _batchRepo = batchRepo,
        _harvestRepo = harvestRepo,
        _expenseRepo = expenseRepo,
        _saleRepo = saleRepo,
        _feedRepo = feedRepo,
        _weightRepo = weightRepo,
        _mortalityRepo = mortalityRepo;

  final RemoteBatchRepository _batchRepo;
  final RemoteHarvestRepository _harvestRepo;
  final RemoteExpenseRepository _expenseRepo;
  final RemoteSaleRepository _saleRepo;
  final RemoteFeedRepository _feedRepo;
  final RemoteWeightRepository _weightRepo;
  final RemoteMortalityRepository _mortalityRepo;

  /// All batches in Admin's business.
  Future<List<Batch>> getAll() {
    return _batchRepo.getAll();
  }

  /// One batch by id, resolved with its assigned-staff and
  /// closed-by names, or null if it isn't visible to this account.
  Future<Batch?> getById(String batchId) {
    return _batchRepo.getById(batchId);
  }

  /// Map of staff account id to list of assigned batch names.
  Future<Map<String, List<String>>> getAssignedBatchesMap() {
    return _batchRepo.getAssignedBatchesMap();
  }

  /// Total birds recorded as dead in this batch so far.
  Future<int> getTotalMortality(String batchId) async {
    final entries = await _mortalityRepo.getByBatch(batchId);
    return entries.fold<int>(0, (sum, entry) => sum + entry.count);
  }

  /// Total birds already harvested from this batch so far.
  Future<int> getTotalHarvested(String batchId) => _totalHarvested(batchId);

  /// How many birds in this batch have not yet been harvested or
  /// recorded as mortality. Same formula mobile's BatchDomain uses,
  /// from rules/bird_count_rule.dart.
  Future<int> getRemainingBirdCount(Batch batch) async {
    final mortality = await getTotalMortality(batch.batchId);
    final harvested = await _totalHarvested(batch.batchId);
    return remainingBirdCount(
      startingBirdCount: batch.startingBirdCount,
      currentMortalityTotal: mortality,
      currentHarvestTotal: harvested,
    );
  }

  /// The computed financial picture for one batch: expenses, revenue,
  /// profit or loss, breakeven price, and an approximate FCR.
  Future<FinancialSummary> getFinancialSummary(String batchId) async {
    final totalExpenses = await _totalExpenses(batchId);
    final totalRevenue = await _totalRevenue(batchId);
    final totalHarvestedBirds = await _totalHarvested(batchId);
    final totalFeedKg = await _totalFeedKg(batchId);
    final latestAverageWeight = await _latestAverageSampleWeight(batchId);

    return FinancialSummary(
      totalExpenses: totalExpenses,
      totalRevenue: totalRevenue,
      profitLoss: profitLoss(
        totalRevenue: totalRevenue,
        totalExpenses: totalExpenses,
      ),
      breakevenPricePerBird: breakevenPricePerBird(
        totalExpenses: totalExpenses,
        totalHarvestedBirds: totalHarvestedBirds,
      ),
      approximateFcr: latestAverageWeight == null
          ? null
          : approximateFcr(
        totalFeedKg: totalFeedKg,
        latestAverageSampleWeight: latestAverageWeight,
        totalHarvestedBirds: totalHarvestedBirds,
      ),
    );
  }

  /// Total birds already harvested from the batch so far.
  Future<int> _totalHarvested(String batchId) async {
    final entries = await _harvestRepo.getByBatch(batchId);
    return entries.fold<int>(0, (sum, entry) => sum + entry.birdCount);
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

/// Builds a [RemoteBatchDomain] wired to the shared Supabase client.
/// Web only, since Admin is the only role that uses this class.
final remoteBatchDomainProvider = Provider<RemoteBatchDomain>((ref) {
  return RemoteBatchDomain(
    batchRepo: ref.watch(remoteBatchRepositoryProvider),
    harvestRepo: ref.watch(remoteHarvestRepositoryProvider),
    expenseRepo: ref.watch(remoteExpenseRepositoryProvider),
    saleRepo: ref.watch(remoteSaleRepositoryProvider),
    feedRepo: ref.watch(remoteFeedRepositoryProvider),
    weightRepo: ref.watch(remoteWeightRepositoryProvider),
    mortalityRepo: ref.watch(remoteMortalityRepositoryProvider),
  );
});