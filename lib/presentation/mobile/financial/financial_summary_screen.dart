import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/models/financial_summary.dart';
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
/// has already computed.
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
        data: (summary) => _buildBody(summary),
      ),
    );
  }

  Widget _buildBody(FinancialSummary summary) {
    final isProfit = summary.profitLoss >= 0;

    return ListView(
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
            ],
          ),
        ),
        const SizedBox(height: 16),
        StatCardRow(
          cards: [
            StatCard(
              value: summary.breakevenPricePerBird == null
                  ? '—'
                  : AppFormat.money(
                      summary.breakevenPricePerBird!,
                      decimals: 2,
                    ),
              label: 'Breakeven / bird to sell',
            ),
            StatCard(
              value: summary.approximateFcr == null
                  ? '—'
                  : AppFormat.twoDecimals(summary.approximateFcr!),
              label: 'FCR (approx.)',
            ),
          ],
        ),
      ],
    );
  }
}