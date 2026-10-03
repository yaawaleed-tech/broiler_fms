import 'package:flutter/material.dart';

import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';

/// One label/value pair shown on a review step, e.g. ("Bird count", "50").
/// The caller is responsible for formatting [value] as a display string
/// before handing it in, same convention as StatCard's value field.
class ReviewEntry {
  const ReviewEntry(this.label, this.value);

  final String label;
  final String value;
}

/// The shared "review before you save" screen used across every write
/// flow in the app: five mobile record types, pricing a harvest, and
/// the three web account-creation modals.
///
/// This widget only displays the review. Switching between the form
/// and this review is each screen's own job, since the forms
/// themselves differ entirely by entity, there's nothing generic to
/// share there.
class ReviewStep extends StatelessWidget {
  const ReviewStep({
    super.key,
    required this.title,
    required this.entries,
    required this.onEdit,
    required this.onConfirm,
    this.confirmLabel = 'Confirm',
    this.editLabel = 'Edit',
    this.note,
  });

  final String title;
  final List<ReviewEntry> entries;
  final VoidCallback onEdit;
  final VoidCallback onConfirm;
  final String confirmLabel;
  final String editLabel;

  /// An optional warning shown below the review rows, e.g. "This entry
  /// cannot be edited once saved," matching Staff's review screen.
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'RobotoSlab',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 14),
        _ReviewRows(entries: entries),
        if (note != null) ...[
          const SizedBox(height: 12),
          Text(
            note!,
            style: const TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 12.5,
              color: AppColors.inkMuted,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onEdit,
                child: Text(editLabel),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: onConfirm,
                child: Text(confirmLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The bordered box of label/value rows, one per [ReviewEntry], each
/// separated by a hairline, matching every mockup's .review-row list.
class _ReviewRows extends StatelessWidget {
  const _ReviewRows({required this.entries});

  final List<ReviewEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairlineStrong, width: 1.5),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            _ReviewRow(
              entry: entries[i],
              showDivider: i < entries.length - 1,
            ),
        ],
      ),
    );
  }
}

/// One label/value line, with a bottom hairline unless it's the last
/// row in the box.
class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.entry, required this.showDivider});

  final ReviewEntry entry;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
          bottom: BorderSide(color: AppColors.hairline, width: 1),
        )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            entry.label,
            style: const TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 13.5,
              color: AppColors.inkMuted,
            ),
          ),
          Text(
            entry.value,
            style: const TextStyle(
              fontFamily: 'PublicSans',
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}