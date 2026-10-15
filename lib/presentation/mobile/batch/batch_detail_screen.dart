import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/domain/account/account_domain.dart';
import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/presentation/shared/formatting.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/confirm_dialog.dart';
import 'package:broiler_fms/presentation/shared/widgets/stat_card.dart';
import 'package:broiler_fms/presentation/mobile/widgets/sync_now_button.dart';

/// The cached Staff pool, so the batch's assigned Staff member can be
/// named on screen. [Batch.assignedStaffName] is only ever filled in
/// by the Supabase embed on the web side, so on mobile the name is
/// matched against this already-cached pool instead of a second query.
final _staffPoolProvider = StreamProvider.autoDispose<List<Account>>((ref) {
  final businessId = ref.watch(currentAccountProvider).value?.businessId;
  if (businessId == null) return Stream.value(const <Account>[]);
  return ref.watch(accountDomainProvider).watchStaffPool(businessId);
});

/// Everything this screen needs about one batch, fetched together so
/// the screen shows one loading state rather than four separate ones.
///
/// Public so the assign-staff screen can invalidate it after changing
/// an assignment, so returning here shows the new state at once rather
/// than a stale one.
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

final batchDetailProvider = FutureProvider.autoDispose.family<
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

/// Batch detail: stat cards, the fully-accounted-for banner once every
/// bird has been recorded as dead or harvested (with the close-batch
/// action inside it), and the record-entry actions. Manager sees four
/// extra actions Staff does not. Once the batch is closed every action
/// row is locked out.
class BatchDetailScreen extends ConsumerWidget {
  const BatchDetailScreen({super.key, required this.batchId});

  final String batchId;

  /// The batch's current day number, counting the start date as day 1.
  int _dayNumber(Batch batch) {
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

  String _subtitle(Batch batch) {
    final day = _dayNumber(batch);
    final parts = <String>[
      if (batch.breed != null && batch.breed!.isNotEmpty) batch.breed!,
      'Day $day',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(batchDetailProvider(batchId));
    final account = ref.watch(currentAccountProvider).value;
    final isManager = account?.role == 'manager';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.rust,
        foregroundColor: AppColors.card,
        actions: [SyncNowButton(batchId: batchId)],
        title: detailAsync.when(
          loading: () => const Text(
            'Batch',
            style: TextStyle(
              fontFamily: 'RobotoSlab',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: AppColors.card,
            ),
          ),
          error: (_, _) => const Text(
            'Batch',
            style: TextStyle(
              fontFamily: 'RobotoSlab',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: AppColors.card,
            ),
          ),
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.batch.batchName,
                style: const TextStyle(
                  fontFamily: 'RobotoSlab',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.card,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _subtitle(data.batch),
                style: const TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 12,
                  color: AppColors.parchment,
                ),
              ),
            ],
          ),
        ),
      ),
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

  /// The banner shows once every bird is accounted for — including on
  /// an already closed batch, where closing is obviously done with.
  bool get _showFullyAccounted =>
      data.batch.isClosed || data.remaining <= 0;

  /// The close button only exists while the batch is fully accounted
  /// for but not yet closed, and only a Manager ever sees it.
  bool get _showCloseButton =>
      !data.batch.isClosed && data.remaining <= 0 && isManager;

  /// The five key entry actions lock on close, and also lock for a
  /// Manager the moment a batch has a Staff member assigned — that
  /// batch is the Staff member's to record entries for.
  bool get _lockKeyActions =>
      data.batch.isClosed || (isManager && data.batch.assignedStaffId != null);

  /// The reopen button: a closed batch is the only case it makes sense
  /// in, and only Manager ever sees it.
  bool get _showReopenButton =>
      data.batch.isClosed && isManager;

  /// Resolves the batch's assigned Staff member from the cached pool.
  ///
  /// Null means nobody is assigned, or the batch is assigned to someone
  /// who is no longer an active Staff account and so is not in the pool
  /// at all — the row renders both as "Not assigned", since from the
  /// Manager's side there is nobody to record entries for it either
  /// way. Falls back to 'Loading…' while the pool itself is still
  /// resolving, so a slow cache doesn't flash "Not assigned".
  String? _assignedStaffName(WidgetRef ref) {
    final staffId = data.batch.assignedStaffId;
    if (staffId == null) return null;
    final poolAsync = ref.watch(_staffPoolProvider);
    final pool = poolAsync.value;
    if (pool == null) return 'Loading…';
    return pool.where((staff) => staff.accountId == staffId).firstOrNull?.name;
  }

  Future<void> _closeBatch(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Close this batch?',
      body: 'No more entries can be logged against this batch once it '
          'is closed.',
      confirmLabel: 'Close batch',
    );
    if (confirmed != true) return;

    try {
      await ref.read(batchDomainProvider).closeBatch(batchId);
      ref.invalidate(batchDetailProvider(batchId));
    } on DomainException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _reopenBatch(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reopen this batch?',
      body: 'Entries can be recorded against this batch again while it is '
          'open. You can close it again afterwards at any time.',
      confirmLabel: 'Reopen batch',
    );
    if (confirmed != true) return;

    try {
      await ref.read(batchDomainProvider).reopenBatch(batchId);
      ref.invalidate(batchDetailProvider(batchId));
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
    // Locked out on close, and for a Manager once the batch belongs to
    // an assigned Staff member, on top of Domain refusing the writes.
    final isClosed = data.batch.isClosed;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StatCardRow(
          cards: [
            StatCard(
              value: AppFormat.count(data.batch.startingBirdCount),
              label: 'Starting count',
            ),
            StatCard(
              value: AppFormat.count(data.remaining),
              label: 'Remaining',
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatCardRow(
          cards: [
            StatCard(
              value: AppFormat.count(data.mortality),
              label: 'Mortality so far',
            ),
            StatCard(
              value: AppFormat.count(data.harvested),
              label: 'Harvested so far',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _AssignedToRow(
          staffName: _assignedStaffName(ref),
          onAssign: isManager
              ? () => context.push('/batches/$batchId/assign-staff')
              : null,
          isLocked: isClosed,
        ),
        if (_showFullyAccounted) ...[
          const SizedBox(height: 16),
          _FullyAccountedBanner(
            onClose: _showCloseButton
                ? () => _closeBatch(context, ref)
                : null,
            onReopen: _showReopenButton
                ? () => _reopenBatch(context, ref)
                : null,
          ),
        ],
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppColors.hairline),
        const SizedBox(height: 12),
        _ActionRow(
          emoji: '💀',
          label: 'Record mortality',
          onTap: _lockKeyActions
              ? null
              : () => context.push('/batches/$batchId/mortality'),
        ),
        _ActionRow(
          emoji: '🌽',
          label: 'Record feed used',
          onTap: _lockKeyActions
              ? null
              : () => context.push('/batches/$batchId/feed'),
        ),
        _ActionRow(
          emoji: '📦',
          label: 'Record harvest',
          onTap: _lockKeyActions
              ? null
              : () => context.push('/batches/$batchId/harvest'),
        ),
        _ActionRow(
          emoji: '⚖️',
          label: 'Record weight sample',
          onTap: _lockKeyActions
              ? null
              : () => context.push('/batches/$batchId/weight'),
        ),
        _ActionRow(
          emoji: '💉',
          label: 'Record vaccination',
          onTap: _lockKeyActions
              ? null
              : () => context.push('/batches/$batchId/vaccination'),
        ),
        if (isManager) ...[
          const Divider(height: 32),
          // Money and pricing outlive the birds: these three stay
          // enabled on a closed batch on purpose.
          _ActionRow(
            emoji: '💸',
            label: 'Log expense',
            onTap: () => context.push('/batches/$batchId/expense'),
          ),
          _ActionRow(
            emoji: '🏷️',
            label: 'Price a harvest',
            onTap: () => context.push('/batches/$batchId/harvests'),
          ),
          // Reassigning someone to a closed batch makes no sense.
          _ActionRow(
            emoji: '👥',
            label: 'Assign staff',
            onTap: isClosed
                ? null
                : () => context.push('/batches/$batchId/assign-staff'),
          ),
          _ActionRow(
            emoji: '📊',
            label: 'View financial summary',
            onTap: () => context.push('/batches/$batchId/financial'),
          ),
        ],
      ],
    );
  }
}

/// The olive "fully accounted for" panel shown once nothing is left
/// alive in the batch. While the batch is not yet closed it carries
/// the close-batch button; once closed it shows the reopen-batch button
/// instead, which only Manager ever sees.
class _FullyAccountedBanner extends StatelessWidget {
  const _FullyAccountedBanner({required this.onClose, this.onReopen});

  /// Null once the batch is already closed — hides the button.
  final VoidCallback? onClose;

  /// Only set on a closed batch, for Manager. Null otherwise.
  final VoidCallback? onReopen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.oliveBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.olive, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fully accounted for',
            style: TextStyle(
              fontFamily: 'RobotoSlab',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.olive,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mortality and harvest now cover every bird in this batch.',
            style: TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 13,
              color: AppColors.ink,
              height: 1.4,
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(height: 12),
            _BannerButton(
              label: 'Close batch',
              onPressed: onClose!,
            ),
          ],
          if (onReopen != null) ...[
            const SizedBox(height: 12),
            _BannerButton(
              label: 'Reopen batch',
              onPressed: onReopen!,
            ),
          ],
        ],
      ),
    );
  }
}

/// One full-width outlined button inside the banner, shared by the
/// close and reopen actions so the two look identical. No mockup
/// reference for the reopen button, so it copies the close styling.
class _BannerButton extends StatelessWidget {
  const _BannerButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.card,
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink, width: 1.5),
        ),
        child: Text(label),
      ),
    );
  }
}

/// The "Assigned to" row sitting under the stat cards: a muted label
/// with the Staff member's name under it, and the assign / reassign
/// link on the right.
///
/// Only Manager gets the link — Staff cannot reassign the batch they
/// are on, so for them the row is read-only and the link is simply
/// absent rather than a dead control. On a closed batch Manager still
/// sees the link, but greyed out and inert, exactly like the "Assign
/// staff" action row further down, since a closed batch has nobody to
/// record entries for.
class _AssignedToRow extends StatelessWidget {
  const _AssignedToRow({
    required this.staffName,
    this.onAssign,
    this.isLocked = false,
  });

  /// Null when nobody is assigned (or the assigned person is no longer
  /// in the active Staff pool), which the row shows as "Not assigned".
  final String? staffName;

  /// Null for Staff, who never see the link.
  final VoidCallback? onAssign;

  /// True on a closed batch: the link stays visible but greyed out and
  /// does nothing, matching the locked action rows' treatment.
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final assigned = staffName != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairlineStrong, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assigned to',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 12,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  staffName ?? 'Not assigned',
                  style: const TextStyle(
                    fontFamily: 'RobotoSlab',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          if (onAssign != null)
            Opacity(
              opacity: isLocked ? 0.45 : 1,
              child: TextButton(
                onPressed: isLocked ? null : onAssign,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.rust,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  assigned ? 'Assign / reassign' : 'Assign',
                  style: const TextStyle(
                    fontFamily: 'PublicSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.rust,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One tappable action row: an emoji in a soft circle, then the label,
/// inside a card-sized bordered box, matching the action list on every
/// mockup. Greyed out and untappable once [onTap] is null (closed
/// batch).
class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.emoji, required this.label, this.onTap});

  final String emoji;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.hairlineStrong, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.parchment,
                    shape: BoxShape.circle,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'PublicSans',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
