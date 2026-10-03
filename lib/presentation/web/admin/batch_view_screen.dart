import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/batch/remote_batch_domain.dart';
import 'package:broiler_fms/domain/models/financial_summary.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/stat_card.dart';

final _financialSummaryProvider =
FutureProvider.autoDispose.family<FinancialSummary, String>(
      (ref, batchId) =>
      ref.watch(remoteBatchDomainProvider).getFinancialSummary(batchId),
);

/// Admin's read-only financial view for one batch. Same calculation
/// and same display shape as Manager's financial summary screen on
/// mobile, reading from Supabase instead of Drift.
class BatchViewScreen extends ConsumerWidget {
  const BatchViewScreen({super.key, required this.batchId});

  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(_financialSummaryProvider(batchId));

    return Scaffold(
      appBar: AppBar(title: const Text('Batch')),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (summary) => _buildBody(summary),
      ),
    );
  }

  Widget _buildBody(FinancialSummary summary) {
    final isProfit = summary.profitLoss >= 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          StatCardRow(
            cards: [
              StatCard(
                value: '₦${summary.totalExpenses.toStringAsFixed(0)}',
                label: 'Total expenses',
              ),
              StatCard(
                value: '₦${summary.totalRevenue.toStringAsFixed(0)}',
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
                  '₦${summary.profitLoss.abs().toStringAsFixed(0)}',
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
                value: '₦${summary.breakevenPricePerBird.toStringAsFixed(2)}',
                label: 'Breakeven price / bird',
              ),
              StatCard(
                value: summary.approximateFcr == null
                    ? '—'
                    : summary.approximateFcr!.toStringAsFixed(2),
                label: 'FCR (approx.)',
              ),
            ],
          ),
        ],
      ),
    );
  }
}