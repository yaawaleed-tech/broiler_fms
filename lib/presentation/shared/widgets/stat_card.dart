import 'package:flutter/material.dart';

import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';

/// One number-and-label card, e.g. "50 / Starting count". Always used
/// in a row of two or three, never alone, matching every mockup's
/// .info-card usage.
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.value, required this.label});

  /// Already formatted for display, e.g. "50" or "₦12,000". Formatting
  /// (currency, rounding, a dash for null) is the caller's job, this
  /// widget only lays the text out.
  final String value;

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairlineStrong, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'RobotoSlab',
              fontWeight: FontWeight.w700,
              fontSize: 26,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 12,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays out two or more [StatCard]s in an evenly spaced row, matching
/// every mockup's .card-row. Each card gets equal width.
class StatCardRow extends StatelessWidget {
  const StatCardRow({super.key, required this.cards});

  final List<StatCard> cards;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}