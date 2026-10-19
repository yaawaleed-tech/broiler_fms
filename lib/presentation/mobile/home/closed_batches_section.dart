import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/presentation/mobile/home/batch_card.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/badge.dart';

/// The Manager's explicit choice for the closed-batches section: true
/// expanded it, false collapsed it, null means "no choice yet, follow
/// the default".
///
/// Not autoDispose on purpose: the choice must survive opening a batch
/// and coming back within the session. It resets on app restart since
/// nothing persists it.
class ClosedSectionChoice extends Notifier<bool?> {
  @override
  bool? build() => null;

  void choose(bool expanded) => state = expanded;
}

final closedSectionChoiceProvider =
    NotifierProvider<ClosedSectionChoice, bool?>(ClosedSectionChoice.new);

/// The collapsible "Closed batches" section: a full-width tappable row
/// in the app's own card style, with the closed cards inline below it
/// once expanded. Hidden entirely when there is nothing closed — the
/// caller decides that, this widget only lays the row and cards out.
class ClosedBatchesSection extends ConsumerStatefulWidget {
  const ClosedBatchesSection({
    super.key,
    required this.closed,
    required this.startExpanded,
    this.readOnly = false,
  });

  /// The closed batches, already newest first.
  final List<Batch> closed;

  /// True when there is nothing open: the section starts expanded so
  /// the screen is never blank.
  final bool startExpanded;

  /// Staff's section. Its cards are read-only and it is titled
  /// "Past batches", because for Staff it holds closed and reassigned
  /// batches together. Manager leaves this false and gets today's
  /// behaviour exactly.
  final bool readOnly;

  @override
  ConsumerState<ClosedBatchesSection> createState() =>
      _ClosedBatchesSectionState();
}

class _ClosedBatchesSectionState
    extends ConsumerState<ClosedBatchesSection> {
  /// Anchors the first closed card so expanding near the bottom of the
  /// screen can scroll it into view.
  final _firstCardKey = GlobalKey();

  void _toggle(bool expanded) {
    ref.read(closedSectionChoiceProvider.notifier).choose(!expanded);
    if (expanded) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _firstCardKey.currentContext;
      if (context != null && mounted) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 250),
          alignment: 0.05,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final choice = ref.watch(closedSectionChoiceProvider);
    final expanded = choice ?? widget.startExpanded;
    final count = widget.closed.length;
    // One title for both, decided here so the screen does not have to
    // repeat the wording. Manager keeps "Closed batches"; Staff sees
    // "Past batches" because their section holds reassigned rows too.
    final title = widget.readOnly ? 'Past batches' : 'Closed batches';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label:
              '$title, $count, ${expanded ? 'expanded' : 'collapsed'}',
          hint: 'Double tap to ${expanded ? 'collapse' : 'expand'}',
          button: true,
          onTap: () => _toggle(expanded),
          excludeSemantics: true,
          child: InkWell(
            onTap: () => _toggle(expanded),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.hairlineStrong,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.archive_outlined,
                    size: 20,
                    color: AppColors.inkMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'RobotoSlab',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  AppBadge(
                    label: '$count',
                    tone: BadgeTone.neutral,
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.expand_more,
                      size: 22,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < widget.closed.length; i++) ...[
                const SizedBox(height: 10),
                if (i == 0)
                  Container(
                    key: _firstCardKey,
                    child: _card(widget.closed[i]),
                  )
                else
                  _card(widget.closed[i]),
              ],
            ],
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  /// One card in the section. A Staff member cannot open anything from
  /// here, so their cards carry no tap and say so when the batch is
  /// reassigned rather than merely closed.
  Widget _card(Batch batch) => BatchCard(
        batch: batch,
      muted: true,
      onTap: !widget.readOnly,
      reassigned: widget.readOnly &&
          !batch.isClosed &&
          batch.assignedStaffId == null,
    );
}
