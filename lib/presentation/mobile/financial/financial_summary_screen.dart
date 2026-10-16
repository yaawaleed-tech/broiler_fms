import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/models/financial_summary.dart';
import 'package:broiler_fms/domain/rules/financial_summary_rule.dart';
import 'package:broiler_fms/presentation/mobile/financial/profit_simulator.dart';
import 'package:broiler_fms/presentation/shared/formatting.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/stat_card.dart';

/// Public so the "Sync now" button can invalidate it after a Manager's
/// pull, exactly as batchDetailProvider is public for the same reason.
/// Without this, a pull landing while this screen is open would change
/// the data underneath it and the figures would stay stale until the
/// screen was rebuilt.
final financialSummaryProvider =
    FutureProvider.autoDispose.family<FinancialSummary, String>(
      (ref, batchId) =>
      ref.watch(batchDomainProvider).getFinancialSummary(batchId),
);

/// Manager's read-only financial picture for one batch: expenses,
/// revenue, profit or loss, breakeven price, and an approximate FCR.
/// Nothing on this screen is editable, it only displays what Domain
/// has already computed — except the profit simulator, which is a
/// calculator over the same loaded figures and saves nothing.
class FinancialSummaryScreen extends ConsumerWidget {
  const FinancialSummaryScreen({super.key, required this.batchId});

  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(financialSummaryProvider(batchId));

    return Scaffold(
      appBar: AppBar(title: const Text('Financial summary')),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (summary) => _buildBody(ref, summary),
      ),
    );
  }

  Widget _buildBody(WidgetRef ref, FinancialSummary summary) {
    final isProfit = summary.profitLoss >= 0;

    return GestureDetector(
      // Tapping outside a simulator field dismisses the keyboard.
      onTap: () => FocusScope.of(ref.context).unfocus(),
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(financialSummaryProvider(batchId).future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16),
          children: [
            StatCardRow(
              cards: [
                StatCard(
                  value: AppFormat.money(summary.totalExpenses),
                  label: 'Total expenses',
                ),
                StatCard(
                  value: AppFormat.money(summary.totalRevenue),
                  label: 'Total revenue',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isProfit ? AppColors.oliveBg : AppColors.brickBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isProfit ? AppColors.olive : AppColors.brick,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isProfit ? 'Profit' : 'Loss',
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 12,
                      color: isProfit ? AppColors.olive : AppColors.brick,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormat.money(summary.profitLoss.abs()),
                    style: TextStyle(
                      fontFamily: 'RobotoSlab',
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: isProfit ? AppColors.olive : AppColors.brick,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _CostRecoveryBar(summary: summary),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatCard(
                        value: summary.breakevenPricePerBird == null
                            ? '—'
                            : AppFormat.money(
                                summary.breakevenPricePerBird!,
                                decimals: 2,
                              ),
                        label: 'Break-even price',
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Lowest price per bird that covers your costs',
                        style: TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 11.5,
                          color: AppColors.inkMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    value: summary.approximateFcr == null
                        ? '—'
                        : AppFormat.twoDecimals(summary.approximateFcr!),
                    label: 'FCR (approx.)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Where you stand',
              style: TextStyle(
                fontFamily: 'RobotoSlab',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            _WhereYouStand(summary: summary),
            const SizedBox(height: 16),
            ProfitSimulator(summary: summary),
          ],
        ),
      ),
    );
  }
}

/// How much of the batch's cost has been earned back: a thin progress
/// bar plus a one-line caption. Hidden entirely when nothing has been
/// spent yet.
class _CostRecoveryBar extends StatelessWidget {
  const _CostRecoveryBar({required this.summary});

  final FinancialSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.totalExpenses <= 0) {
      return const Text(
        'No expenses recorded yet',
        style: TextStyle(
          fontFamily: 'PublicSans',
          fontSize: 12,
          color: AppColors.inkMuted,
        ),
      );
    }
    final fill = (summary.totalRevenue / summary.totalExpenses)
        .clamp(0.0, 1.0);
    final caption = summary.totalRevenue >= summary.totalExpenses
        ? 'Costs covered: ${AppFormat.money(summary.totalRevenue)} '
            'earned against ${AppFormat.money(summary.totalExpenses)} spent'
        : '${AppFormat.money(summary.totalRevenue)} earned back out of '
            '${AppFormat.money(summary.totalExpenses)} spent';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fill,
            minHeight: 6,
            backgroundColor: AppColors.hairline,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.olive),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          caption,
          style: const TextStyle(
            fontFamily: 'PublicSans',
            fontSize: 12,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    );
  }
}

/// The "Where you stand" card: birds in stock, birds harvested but not
/// priced yet, and a guidance sentence driven by [breakevenGuidance].
class _WhereYouStand extends StatelessWidget {
  const _WhereYouStand({required this.summary});

  final FinancialSummary summary;

  static String _birds(int count) =>
      '${AppFormat.count(count)} ${count == 1 ? 'bird' : 'birds'}';

  static String _harvestedBirds(int count) =>
      '${AppFormat.count(count)} harvested ${count == 1 ? 'bird' : 'birds'}';

  String _guidanceText(BreakevenGuidance guidance) {
    final atleast = AppFormat.money(guidance.atLeastPerBird);
    switch (guidance.state) {
      case BreakevenGuidanceState.noBirdsLeft:
        return 'No birds left to sell. Nothing more to break even on.';
      case BreakevenGuidanceState.costsCovered:
        return 'Costs covered. Every bird from here is profit.';
      case BreakevenGuidanceState.needsPricing:
        if (guidance.birdsInStock <= 0) {
          return 'Price the ${_harvestedBirds(guidance.birdsAwaitingPrice)}. '
              'They need to bring in at least $atleast per bird to cover '
              'all costs.';
        }
        return 'Price the ${_harvestedBirds(guidance.birdsAwaitingPrice)}, '
            'then sell the ${_birds(guidance.birdsInStock)} still in '
            'stock. Together they need to bring in at least $atleast per '
            'bird to cover all costs.';
      case BreakevenGuidanceState.sellRemaining:
        return 'Sell your remaining ${_birds(guidance.birdsInStock)} for '
            'at least $atleast each to cover all costs.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final guidance = breakevenGuidance(
      totalExpenses: summary.totalExpenses,
      totalRevenue: summary.totalRevenue,
      birdsInStock: summary.birdsInStock,
      birdsAwaitingPrice: summary.birdsAwaitingPrice,
      breakevenPricePerBird: summary.breakevenPricePerBird,
    );
    final covered =
        guidance.state == BreakevenGuidanceState.costsCovered;

    return Container(
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
          _StandRow(
            label: 'Birds in stock',
            value: AppFormat.count(summary.birdsInStock),
          ),
          if (summary.birdsAwaitingPrice > 0) ...[
            const SizedBox(height: 8),
            _StandRow(
              label: 'Harvested, not priced yet',
              value: AppFormat.count(summary.birdsAwaitingPrice),
              valueColor: AppColors.amber,
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: covered ? AppColors.oliveBg : AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: covered ? AppColors.olive : AppColors.hairlineStrong,
                width: 1.5,
              ),
            ),
            child: Text(
              _guidanceText(guidance),
              style: TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 13.5,
                height: 1.45,
                color: covered ? AppColors.olive : AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: const ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'What is break-even?',
                style: TextStyle(
                  fontFamily: 'PublicSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.ink,
                ),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Break-even is the price each remaining bird must sell '
                    'for so the whole batch ends with no profit and no '
                    'loss. It goes up when birds die or when you sell '
                    'below it, and comes down when you sell above it.',
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 12.5,
                      height: 1.45,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One label/value line in the "Where you stand" card.
class _StandRow extends StatelessWidget {
  const _StandRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
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
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: valueColor ?? AppColors.ink,
          ),
        ),
      ],
    );
  }
}
