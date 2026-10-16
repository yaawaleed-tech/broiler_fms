import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/presentation/shared/formatting.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/badge.dart';

/// One row in the batch list: name · breed, a second line, a status
/// badge, and the remaining-bird count on the right. Tapping the row
/// opens batch detail.
///
/// Open cards use the full-strength styling. Closed cards inside the
/// "Closed batches" section pass [muted]: same layout, quieter border
/// and text, with the second line reading "Closed {d MMM} · ran
/// {N} days" when the close date is on the device. The "Closed" chip
/// itself never changes.
class BatchCard extends ConsumerWidget {
  const BatchCard({super.key, required this.batch, this.muted = false});

  final Batch batch;

  /// True for closed cards in the closed section. Only ever set on a
  /// batch that is actually closed.
  final bool muted;

  /// The batch's current day number, counting the start date as day 1.
  /// Week is derived from it, both shown on the list mockup.
  int get _dayNumber {
    final today = DateTime.now();
    final start = DateTime(
      batch.startDate.year,
      batch.startDate.month,
      batch.startDate.day,
    );
    final days = DateTime(today.year, today.month, today.day)
            .difference(start)
            .inDays +
        1;
    return days < 1 ? 1 : days;
  }

  /// "Closed 10 Oct · ran 9 days", or null when the close date is not
  /// on the device — the card then keeps the Day/Week line instead.
  String? get _closedLine {
    final closedAt = batch.closedAt;
    if (closedAt == null) return null;
    final start = DateTime(
      batch.startDate.year,
      batch.startDate.month,
      batch.startDate.day,
    );
    final end = DateTime(closedAt.year, closedAt.month, closedAt.day);
    final days = end.difference(start).inDays;
    final ran = days < 1 ? 1 : days;
    return 'Closed ${DateFormat('d MMM').format(closedAt)} · '
        'ran $ran ${ran == 1 ? 'day' : 'days'}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remainingAsync = ref.watch(_remainingProvider(batch.batchId));
    final day = _dayNumber;
    final week = ((day - 1) ~/ 7) + 1;
    final secondLine = (muted && batch.isClosed)
        ? (_closedLine ?? 'Day $day · Week $week')
        : 'Day $day · Week $week';
    // Muted cards keep the name readable and only quiet the chrome
    // around it: a hairline border and a muted remaining count.
    final border = muted ? AppColors.hairline : AppColors.hairlineStrong;
    final emphasis = muted ? AppColors.inkMuted : AppColors.ink;

    return InkWell(
      onTap: () => context.push('/batches/${batch.batchId}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: batch.batchName,
                          style: const TextStyle(
                            fontFamily: 'RobotoSlab',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.ink,
                          ),
                        ),
                        if (batch.breed != null)
                          TextSpan(
                            text: ' · ${batch.breed}',
                            style: const TextStyle(
                              fontFamily: 'PublicSans',
                              fontSize: 13.5,
                              color: AppColors.inkMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    secondLine,
                    style: const TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 12.5,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatusBadge(batch: batch, remainingAsync: remainingAsync),
                ],
              ),
            ),
            const SizedBox(width: 12),
            remainingAsync.when(
              loading: () => const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (remaining) => Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormat.count(remaining),
                    style: TextStyle(
                      fontFamily: 'RobotoSlab',
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: emphasis,
                    ),
                  ),
                  const Text(
                    'remaining',
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontSize: 11,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The status pill for one batch row: Closed once closed, Ready to
/// close when nothing is left alive, Active otherwise.
class _StatusBadge extends ConsumerWidget {
  const _StatusBadge({required this.batch, required this.remainingAsync});

  final Batch batch;
  final AsyncValue<int> remainingAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (batch.isClosed) {
      return const AppBadge(label: 'Closed', tone: BadgeTone.neutral);
    }
    return remainingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (remaining) {
        if (remaining <= 0) {
          return const AppBadge(label: 'Ready to close', tone: BadgeTone.warning);
        }
        return const AppBadge(label: 'Active', tone: BadgeTone.positive);
      },
    );
  }
}

final _remainingProvider = FutureProvider.autoDispose.family<int, String>(
      (ref, batchId) => ref.watch(batchDomainProvider).getRemainingBirdCount(batchId),
);
