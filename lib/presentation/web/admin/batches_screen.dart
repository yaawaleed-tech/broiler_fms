import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:broiler_fms/domain/batch/remote_batch_domain.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/domain/models/financial_summary.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/badge.dart';

/// One row of the batches table: the batch itself plus everything
/// that has to be computed for it (remaining birds and the financial
/// summary), so each row is loaded once and the table only lays out
/// plain values.
class _BatchRowData {
  const _BatchRowData({
    required this.batch,
    required this.remaining,
    required this.summary,
  });

  final Batch batch;
  final int remaining;
  final FinancialSummary summary;
}

final _moneyFormat = NumberFormat('#,###');

/// Loads every batch once, then computes its remaining count and
/// financial summary concurrently across all batches. Each batch costs
/// its own set of Supabase queries (roughly seven), which is fine at
/// the scale this screen is used at.
final _batchesProvider =
    FutureProvider.autoDispose<List<_BatchRowData>>((ref) async {
      final domain = ref.watch(remoteBatchDomainProvider);
      final batches = await domain.getAll();
      return Future.wait([
        for (final batch in batches)
          () async {
            final remainingFuture = domain.getRemainingBirdCount(batch);
            final summaryFuture = domain.getFinancialSummary(batch.batchId);
            return _BatchRowData(
              batch: batch,
              remaining: await remainingFuture,
              summary: await summaryFuture,
            );
          }(),
      ]);
    });

/// Admin's read-only table of every batch in the business: status,
/// assignment, bird counts, and money made so far. Tapping "View"
/// opens that batch's detail screen.
class BatchesScreen extends ConsumerWidget {
  const BatchesScreen({super.key});

  /// Closed batches are settled, batches with zero birds left are
  /// waiting for their final financial actions, everything else is
  /// still running.
  ({String label, BadgeTone tone}) _statusFor(_BatchRowData row) {
    if (row.batch.isClosed) {
      return (label: 'Closed', tone: BadgeTone.neutral);
    }
    if (row.remaining == 0) {
      return (label: 'Ready to close', tone: BadgeTone.warning);
    }
    return (label: 'Active', tone: BadgeTone.positive);
  }

  String _formatSigned(double amount) {
    final sign = amount >= 0 ? '+' : '-';
    return '$sign₦${_moneyFormat.format(amount.abs())}';
  }

  DataRow _buildRow(BuildContext context, _BatchRowData row) {
    final status = _statusFor(row);
    final isProfit = row.summary.profitLoss >= 0;
    final assignedStaffName = row.batch.assignedStaffName;

    return DataRow(
      cells: [
        DataCell(
          Text(
            row.batch.batchName,
            style: const TextStyle(
              fontFamily: 'PublicSans',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.ink,
            ),
          ),
        ),
        DataCell(AppBadge(label: status.label, tone: status.tone)),
        DataCell(
          Text(
            assignedStaffName ?? 'Unassigned',
            style: TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 13,
              color: assignedStaffName == null
                  ? AppColors.inkMuted
                  : AppColors.ink,
            ),
          ),
        ),
        DataCell(
          Text(
            _moneyFormat.format(row.batch.startingBirdCount),
            style: const TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 13,
              color: AppColors.ink,
            ),
          ),
        ),
        DataCell(
          Text(
            _moneyFormat.format(row.remaining),
            style: const TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 13,
              color: AppColors.ink,
            ),
          ),
        ),
        DataCell(
          Text(
            _formatSigned(row.summary.profitLoss),
            style: TextStyle(
              fontFamily: 'PublicSans',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isProfit ? AppColors.olive : AppColors.brick,
            ),
          ),
        ),
        DataCell(
          TextButton(
            onPressed: () => context.push('/batches/${row.batch.batchId}'),
            child: const Text('View →'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(_batchesProvider);

    return Scaffold(
      body: batchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('No batches yet.'));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Batches',
                style: TextStyle(
                  fontFamily: 'RobotoSlab',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Read-only view of every batch in this business.',
                style: TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 13,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 24),
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
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Assigned staff')),
                      DataColumn(label: Text('Starting'), numeric: true),
                      DataColumn(label: Text('Remaining'), numeric: true),
                      DataColumn(label: Text('Profit/Loss so far'), numeric: true),
                      DataColumn(label: Text('View')),
                    ],
                    rows: [for (final row in rows) _buildRow(context, row)],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
