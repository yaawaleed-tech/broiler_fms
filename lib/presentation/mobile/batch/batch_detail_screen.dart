import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/confirm_dialog.dart';
import 'package:broiler_fms/presentation/shared/widgets/stat_card.dart';

/// Everything this screen needs about one batch, fetched together so
/// the screen shows one loading state rather than four separate ones.
class _BatchDetailData {
  const _BatchDetailData({
    required this.batch,
    required this.remaining,
    required this.mortality,
    required this.harvested,
  });

  final Batch batch;
  final int remaining;
  final int mortality;
  final int harvested;
}

final _batchDetailProvider = FutureProvider.autoDispose.family<
    _BatchDetailData, String>((ref, batchId) async {
  final batchDomain = ref.watch(batchDomainProvider);
  final batch = await batchDomain.getById(batchId);
  if (batch == null) {
    throw const DomainException('This batch could not be found.');
  }
  final remaining = await batchDomain.getRemainingBirdCount(batchId);
  final mortality = await batchDomain.getTotalMortality(batchId);
  final harvested = await batchDomain.getTotalHarvested(batchId);
  return _BatchDetailData(
    batch: batch,
    remaining: remaining,
    mortality: mortality,
    harvested: harvested,
  );
});

/// Batch detail: stat cards, a close-batch action once every bird is
/// accounted for, and the record-entry actions. Manager sees four
/// extra actions Staff does not.
class BatchDetailScreen extends ConsumerWidget {
  const BatchDetailScreen({super.key, required this.batchId});

  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(_batchDetailProvider(batchId));
    final account = ref.watch(currentAccountProvider).value;
    final isManager = account?.role == 'manager';

    return Scaffold(
      appBar: AppBar(title: const Text('Batch')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (data) => _BatchDetailBody(
          batchId: batchId,
          data: data,
          isManager: isManager,
        ),
      ),
    );
  }
}

class _BatchDetailBody extends ConsumerWidget {
  const _BatchDetailBody({
    required this.batchId,
    required this.data,
    required this.isManager,
  });

  final String batchId;
  final _BatchDetailData data;
  final bool isManager;

  bool get _readyToClose => !data.batch.isClosed && data.remaining <= 0;

  Future<void> _closeBatch(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Close this batch?',
      body: 'No more entries can be logged against this batch once it '
          'is closed. This cannot be undone.',
      confirmLabel: 'Close batch',
    );
    if (confirmed != true) return;

    try {
      await ref.read(batchDomainProvider).closeBatch(batchId);
      ref.invalidate(_batchDetailProvider(batchId));
    } on DomainException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          data.batch.batchName,
          style: const TextStyle(
            fontFamily: 'RobotoSlab',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 16),
        StatCardRow(
          cards: [
            StatCard(
              value: '${data.batch.startingBirdCount}',
              label: 'Starting',
            ),
            StatCard(value: '${data.remaining}', label: 'Remaining'),
            StatCard(value: '${data.mortality}', label: 'Mortality'),
            StatCard(value: '${data.harvested}', label: 'Harvested'),
          ],
        ),
        if (_readyToClose) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _closeBatch(context, ref),
            child: const Text('Close batch'),
          ),
        ],
        const SizedBox(height: 24),
        _ActionRow(
          label: 'Record mortality',
          onTap: () => context.push('/batches/$batchId/mortality'),
        ),
        _ActionRow(
          label: 'Record feed',
          onTap: () => context.push('/batches/$batchId/feed'),
        ),
        _ActionRow(
          label: 'Record harvest',
          onTap: () => context.push('/batches/$batchId/harvest'),
        ),
        _ActionRow(
          label: 'Record weight sample',
          onTap: () => context.push('/batches/$batchId/weight'),
        ),
        _ActionRow(
          label: 'Record vaccination',
          onTap: () => context.push('/batches/$batchId/vaccination'),
        ),
        if (isManager) ...[
          const Divider(height: 32),
          _ActionRow(
            label: 'Log expense',
            onTap: () => context.push('/batches/$batchId/expense'),
          ),
          _ActionRow(
            label: 'Price a harvest',
            onTap: () => context.push('/batches/$batchId/harvests'),
          ),
          _ActionRow(
            label: 'Assign staff',
            onTap: () => context.push('/batches/$batchId/assign-staff'),
          ),
          _ActionRow(
            label: 'View financial summary',
            onTap: () => context.push('/batches/$batchId/financial'),
          ),
        ],
      ],
    );
  }
}

/// One tappable action row, matching every mockup's action-list item.
class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(fontFamily: 'PublicSans', fontSize: 14),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}