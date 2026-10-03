import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:broiler_fms/domain/harvest/harvest_domain.dart';
import 'package:broiler_fms/domain/models/harvest.dart';
import 'package:broiler_fms/domain/sale/sale_domain.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/badge.dart';

/// Manager's list of harvests for one batch, each showing whether it
/// has already been priced. Tapping an unpriced one opens pricing.
class HarvestListScreen extends ConsumerWidget {
  const HarvestListScreen({super.key, required this.batchId});

  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Price a harvest')),
      body: StreamBuilder<List<Harvest>>(
        stream: ref.watch(harvestDomainProvider).watchByBatch(batchId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final harvests = snapshot.data!;
          if (harvests.isEmpty) {
            return const Center(child: Text('No harvests recorded yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: harvests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _HarvestRow(
              batchId: batchId,
              harvest: harvests[index],
            ),
          );
        },
      ),
    );
  }
}

/// Whether a harvest already has at least one sale recorded against
/// it. One priced harvest can, in principle, have more than one sale
/// row, but "has it been priced at all" only needs to know if the
/// list is non-empty.
final _isPricedProvider = FutureProvider.autoDispose.family<bool, String>(
      (ref, harvestId) async {
    final sales = await ref.watch(saleDomainProvider).getByHarvest(harvestId);
    return sales.isNotEmpty;
  },
);

class _HarvestRow extends ConsumerWidget {
  const _HarvestRow({required this.batchId, required this.harvest});

  final String batchId;
  final Harvest harvest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricedAsync = ref.watch(_isPricedProvider(harvest.harvestId));

    return pricedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (isPriced) {
        return InkWell(
          onTap: isPriced
              ? null
              : () => context.push(
            '/batches/$batchId/harvests/${harvest.harvestId}/price',
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border:
              Border.all(color: AppColors.hairlineStrong, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${harvest.birdCount} birds',
                        style: const TextStyle(
                          fontFamily: 'RobotoSlab',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat.yMMMd().format(harvest.date),
                        style: const TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 12,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                AppBadge(
                  label: isPriced ? 'Priced' : 'Needs price',
                  tone: isPriced ? BadgeTone.positive : BadgeTone.warning,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}