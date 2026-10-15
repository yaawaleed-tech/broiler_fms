import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:broiler_fms/domain/batch/remote_batch_domain.dart';
import 'package:broiler_fms/domain/harvest/remote_harvest_domain.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/domain/models/financial_summary.dart';
import 'package:broiler_fms/domain/models/harvest.dart';
import 'package:broiler_fms/domain/models/sale.dart';
import 'package:broiler_fms/domain/sale/remote_sale_domain.dart';
import 'package:broiler_fms/presentation/shared/formatting.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/badge.dart';
import 'package:broiler_fms/presentation/shared/widgets/stat_card.dart';

final _countFormat = NumberFormat('#,###');

/// One harvest entry together with its sales, which is exactly what
/// the harvest table needs: the bird count, whether it has been
/// priced, who bought it, and what it earned.
class _HarvestRowData {
  const _HarvestRowData({required this.harvest, required this.sales});

  final Harvest harvest;
  final List<Sale> sales;
}

/// Everything the batch detail screen shows, loaded once. [batch] is
/// null when the id doesn't exist or isn't visible to this account.
class _BatchViewData {
  const _BatchViewData({
    required this.batch,
    required this.summary,
    required this.mortality,
    required this.remaining,
    required this.harvestRows,
  });

  final Batch? batch;
  final FinancialSummary? summary;
  final int mortality;
  final int remaining;
  final List<_HarvestRowData> harvestRows;
}

Future<_HarvestRowData> _loadHarvestRow(
  RemoteSaleDomain saleDomain,
  Harvest harvest,
) async {
  final sales = await saleDomain.getByHarvest(harvest.harvestId);
  return _HarvestRowData(harvest: harvest, sales: sales);
}

/// First non-null buyer name across the harvest's sales, or null if
/// nobody is named yet.
String? _buyerFor(List<Sale> sales) {
  for (final sale in sales) {
    if (sale.buyerName != null) return sale.buyerName;
  }
  return null;
}

final _batchViewProvider = FutureProvider.autoDispose.family<_BatchViewData, String>((
  ref,
  batchId,
) async {
  final domain = ref.watch(remoteBatchDomainProvider);
  final batch = await domain.getById(batchId);
  if (batch == null) {
    return const _BatchViewData(
      batch: null,
      summary: null,
      mortality: 0,
      remaining: 0,
      harvestRows: [],
    );
  }

  // All of these start together and are awaited at the end, so the
  // batch's totals, stats, and harvest table load in parallel.
  final summaryFuture = domain.getFinancialSummary(batchId);
  final mortalityFuture = domain.getTotalMortality(batchId);
  final remainingFuture = domain.getRemainingBirdCount(batch);
  final harvests = await ref
      .watch(remoteHarvestDomainProvider)
      .getByBatch(batchId);
  harvests.sort((a, b) => b.date.compareTo(a.date));

  final saleDomain = ref.watch(remoteSaleDomainProvider);
  final harvestRows = await Future.wait([
    for (final harvest in harvests) _loadHarvestRow(saleDomain, harvest),
  ]);

  return _BatchViewData(
    batch: batch,
    summary: await summaryFuture,
    mortality: await mortalityFuture,
    remaining: await remainingFuture,
    harvestRows: harvestRows,
  );
});

/// Admin's read-only detail view for one batch: title with who closed
/// and who runs it, bird-count stats, the same financial summary
/// Manager sees on mobile (identical rules from
/// rules/financial_summary_rule.dart), and every harvest entry.
class BatchViewScreen extends ConsumerWidget {
  const BatchViewScreen({super.key, required this.batchId});

  final String batchId;

  String _subtitleFor(Batch batch) {
    final dateFormat = DateFormat.yMMMd();
    final closedPart = batch.isClosed
        ? (batch.closedByName != null
              ? 'Closed by ${batch.closedByName} on '
                    '${dateFormat.format(batch.closedAt ?? batch.createdAt)}'
              : 'Closed on ${dateFormat.format(batch.closedAt ?? batch.createdAt)}')
        : 'Open';
    final assignedPart = batch.assignedStaffName != null
        ? 'Assigned to ${batch.assignedStaffName}'
        : 'Not assigned';
    return '$closedPart · $assignedPart';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_batchViewProvider(batchId));

    return Scaffold(
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (data) {
          final batch = data.batch;
          if (batch == null || data.summary == null) {
            return const Center(child: Text('Batch not found.'));
          }
          return _buildBody(context, ref, data, batch, data.summary!);
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    _BatchViewData data,
    Batch batch,
    FinancialSummary summary,
  ) {
    final isProfit = summary.profitLoss >= 0;
    final dateFormat = DateFormat.yMMMd();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.go('/batches'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.rust,
            ),
            child: const Text('← Back to batches'),
          ),
        ),
        // Reloads this screen's data from Supabase.
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: () => ref.invalidate(_batchViewProvider(batchId)),
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          batch.batchName,
          style: const TextStyle(
            fontFamily: 'RobotoSlab',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _subtitleFor(batch),
          style: const TextStyle(
            fontFamily: 'PublicSans',
            fontSize: 13,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 20),
        StatCardRow(
          cards: [
            StatCard(
              value: _countFormat.format(batch.startingBirdCount),
              label: 'Starting count',
            ),
            StatCard(
              value: _countFormat.format(data.remaining),
              label: 'Remaining birds',
            ),
            StatCard(
              value: _countFormat.format(data.mortality),
              label: 'Mortality',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.hairlineStrong, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Financial summary',
                style: TextStyle(
                  fontFamily: 'RobotoSlab',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              _summaryRow(
                'Total expenses',
                AppFormat.money(summary.totalExpenses),
              ),
              const Divider(height: 1),
              _summaryRow(
                'Total revenue',
                AppFormat.money(summary.totalRevenue),
              ),
              const Divider(height: 1),
              _summaryRow(
                'Profit/Loss',
                '${summary.profitLoss >= 0 ? '+' : '-'}'
                '${AppFormat.money(summary.profitLoss.abs())}',
                color: isProfit ? AppColors.olive : AppColors.brick,
                emphasize: true,
              ),
              const Divider(height: 1),
              _summaryRow(
                'Breakeven / bird to sell',
                summary.breakevenPricePerBird == null
                    ? '—'
                    : AppFormat.money(
                        summary.breakevenPricePerBird!,
                        decimals: 2,
                      ),
              ),
              const Divider(height: 1),
              _summaryRow(
                'FCR (approx.)',
                summary.approximateFcr == null
                    ? '—'
                    : summary.approximateFcr!.toStringAsFixed(2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Harvest entries',
          style: TextStyle(
            fontFamily: 'RobotoSlab',
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        if (data.harvestRows.isEmpty)
          const Text(
            'No harvests recorded yet.',
            style: TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 13,
              color: AppColors.inkMuted,
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Card(
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(
                  color: AppColors.hairlineStrong,
                  width: 1.5,
                ),
              ),
              child: DataTable(
                headingTextStyle: const TextStyle(
                  fontFamily: 'PublicSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.inkMuted,
                ),
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Birds'), numeric: true),
                  DataColumn(label: Text('Buyer')),
                  DataColumn(label: Text('Amount'), numeric: true),
                  DataColumn(label: Text('Status')),
                ],
                rows: [
                  for (final row in data.harvestRows)
                    DataRow(
                      cells: [
                        DataCell(
                          Text(
                            dateFormat.format(row.harvest.date),
                            style: const TextStyle(
                              fontFamily: 'PublicSans',
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _countFormat.format(row.harvest.birdCount),
                            style: const TextStyle(
                              fontFamily: 'PublicSans',
                              fontSize: 13,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _buyerFor(row.sales) ?? '—',
                            style: TextStyle(
                              fontFamily: 'PublicSans',
                              fontSize: 13,
                              color: _buyerFor(row.sales) == null
                                  ? AppColors.inkMuted
                                  : AppColors.ink,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            row.sales.isEmpty
                                ? '—'
                                : '₦${_countFormat.format(row.sales.fold<double>(0, (sum, sale) => sum + sale.amount))}',
                            style: TextStyle(
                              fontFamily: 'PublicSans',
                              fontSize: 13,
                              color: row.sales.isEmpty
                                  ? AppColors.inkMuted
                                  : AppColors.ink,
                            ),
                          ),
                        ),
                        DataCell(
                          AppBadge(
                            label: row.sales.isEmpty ? 'Needs price' : 'Priced',
                            tone: row.sales.isEmpty
                                ? BadgeTone.warning
                                : BadgeTone.positive,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    Color color = AppColors.ink,
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 13,
              color: AppColors.inkMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 13,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
