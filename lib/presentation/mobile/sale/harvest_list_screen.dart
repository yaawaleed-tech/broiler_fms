import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:broiler_fms/domain/harvest/harvest_domain.dart';
import 'package:broiler_fms/domain/models/harvest.dart';
import 'package:broiler_fms/domain/models/sale.dart';
import 'package:broiler_fms/domain/sale/sale_domain.dart';
import 'package:broiler_fms/presentation/shared/formatting.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/badge.dart';

/// The sales recorded against one harvest, not just whether any exist.
///
/// Public so the price-harvest screen can invalidate it after saving,
/// so the row it pops back to already shows the new sale expanded.
/// Returns the whole list rather than a bool: one harvest can in
/// principle carry more than one sale row, even though SaleDomain
/// normally refuses the second, so the caller renders whatever it
/// gets rather than assuming a single sale.
final salesProvider = FutureProvider.autoDispose.family<List<Sale>, String>((
    ref,
    harvestId,
  ) {
  return ref.watch(saleDomainProvider).getByHarvest(harvestId);
});

/// Manager's list of harvests for one batch. An unpriced harvest opens
/// the pricing screen; a priced one expands in place to show the full
/// breakdown, so the sale details are readable without navigating away.
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

class _HarvestRow extends ConsumerStatefulWidget {
  const _HarvestRow({required this.batchId, required this.harvest});

  final String batchId;
  final Harvest harvest;

  @override
  ConsumerState<_HarvestRow> createState() => _HarvestRowState();
}

class _HarvestRowState extends ConsumerState<_HarvestRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final harvest = widget.harvest;
    final salesAsync = ref.watch(salesProvider(harvest.harvestId));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairlineStrong, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            // Unpriced opens pricing. Priced toggles the breakdown.
            onTap: () {
              salesAsync.maybeWhen(
                data: (sales) {
                  if (sales.isEmpty) {
                    context.push(
                      '/batches/${widget.batchId}'
                      '/harvests/${harvest.harvestId}/price',
                    );
                  } else {
                    setState(() => _isExpanded = !_isExpanded);
                  }
                },
                orElse: () {},
              );
            },
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(_isExpanded ? 0 : 8),
              bottom: Radius.circular(_isExpanded ? 0 : 8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppFormat.count(harvest.birdCount)} birds',
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
                  _StatusPill(
                    salesAsync: salesAsync,
                    isExpanded: _isExpanded,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            salesAsync.maybeWhen(
              data: (sales) => _SaleBreakdown(sales: sales),
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

/// The right-hand status: a "Priced" / "Needs price" badge, plus the
/// expand/collapse chevron once it's priced. While the sale lookup is
/// still in flight it falls back to a small spinner in the same slot so
/// the row keeps its height and never pops in.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.salesAsync, required this.isExpanded});

  final AsyncValue<List<Sale>> salesAsync;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return salesAsync.when(
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (sales) {
        final isPriced = sales.isNotEmpty;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBadge(
              label: isPriced ? 'Priced' : 'Needs price',
              tone: isPriced ? BadgeTone.positive : BadgeTone.warning,
            ),
            if (isPriced)
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 20,
                color: AppColors.inkMuted,
              ),
          ],
        );
      },
    );
  }
}

/// The expanded section showing the full pricing breakdown for a
/// priced harvest. Each sale renders as its own labelled block — the
/// domain blocks a second sale, but the storage layer doesn't enforce
/// it, so a list is rendered rather than assuming exactly one.
class _SaleBreakdown extends StatelessWidget {
  const _SaleBreakdown({required this.sales});

  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, color: AppColors.hairline),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final sale in sales) ...[
                Text(
                  _dispositionLabel(sale),
                  style: const TextStyle(
                    fontFamily: 'RobotoSlab',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                if (sale.disposition == 'gift_cull')
                  const _DetailRow(
                    label: 'Amount',
                    value: '₦0',
                  )
                else ...[
                  _DetailRow(
                    label: 'Pricing method',
                    value: sale.pricingMethod == 'per_kg'
                        ? 'Per Kg'
                        : 'Flat Total',
                  ),
                  if (sale.pricingMethod == 'per_kg')
                    _DetailRow(
                      label: 'Weight sold',
                      value: '${AppFormat.quantity(sale.weightSold ?? 0)} kg',
                    ),
                  _DetailRow(
                    label: sale.pricingMethod == 'per_kg'
                        ? 'Price per kg'
                        : 'Price per bird',
                    value: AppFormat.money(sale.pricePerUnit ?? 0),
                  ),
                  _DetailRow(
                    label: 'Amount',
                    value: AppFormat.money(sale.amount),
                  ),
                ],
                if (sale != sales.last) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _dispositionLabel(Sale sale) =>
      sale.disposition == 'gift_cull' ? 'Gift / Cull' : 'Sale';
}

/// One label/value line inside the expanded breakdown.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 12.5,
              color: AppColors.inkMuted,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'PublicSans',
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
