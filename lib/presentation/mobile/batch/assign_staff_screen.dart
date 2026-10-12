import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/domain/account/account_domain.dart';
import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/presentation/mobile/batch/batch_detail_screen.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/badge.dart';
import 'package:broiler_fms/presentation/shared/widgets/confirm_dialog.dart';
import 'package:broiler_fms/presentation/shared/widgets/review_step.dart';

/// The batch this screen is assigning staff to. Needed for the AppBar
/// subtitle, the review step's "Batch" row, and working out who is
/// currently assigned.
final _batchProvider = FutureProvider.autoDispose.family<Batch?, String>((
    ref,
    batchId,
    ) {
  return ref.watch(batchDomainProvider).getById(batchId);
});

/// Manager picks one Staff account to assign to a batch, from the
/// cached Staff pool, works offline.
///
/// Tapping a staff member goes to a review step before anything is
/// saved, matching how every entry flow in the app works. Removing an
/// existing assignment skips that: it is only ever a confirmation
/// dialog, since there is nothing to double-check beyond the name in
/// the question.
class AssignStaffScreen extends ConsumerStatefulWidget {
  const AssignStaffScreen({super.key, required this.batchId});

  final String batchId;

  @override
  ConsumerState<AssignStaffScreen> createState() => _AssignStaffScreenState();
}

class _AssignStaffScreenState extends ConsumerState<AssignStaffScreen> {
  /// The staff member picked in the list and waiting to be confirmed on
  /// the review step. Null while still on the list.
  Account? _selectedStaff;

  bool _showingReview = false;
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _confirm() async {
    final staff = _selectedStaff;
    if (staff == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(batchDomainProvider).assignStaff(
            widget.batchId,
            staff.accountId,
          );
      if (!mounted) return;
      _leaveAndRefresh();
    } on DomainException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removeAssignment(String? staffName) async {
    final whom = staffName ?? 'the current staff member';
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove assignment?',
      body: 'Remove $whom from this batch? They will no longer be able to '
          'record entries for it.',
      confirmLabel: 'Remove',
    );
    if (confirmed != true) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(batchDomainProvider).assignStaff(widget.batchId, null);
      if (!mounted) return;
      _leaveAndRefresh();
    } on DomainException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Leaves the screen after a successful change, refreshing batch
  /// detail on the way out so its "Assigned to" row shows the new state
  /// the moment it comes back into view.
  ///
  /// Normally that is a pop back to batch detail, which is how both
  /// entry points arrive: the detail screen's own link, or the
  /// post-registration "Assign now" prompt, which replaces itself with
  /// this screen so the batch list is underneath. The [canPop] branch
  /// is only a safety net for a future caller that pushes this screen
  /// with nothing behind it, where popping would be a no-op.
  void _leaveAndRefresh() {
    ref.invalidate(batchDetailProvider(widget.batchId));
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(currentAccountProvider).value;
    final businessId = account?.businessId;
    final batchAsync = ref.watch(_batchProvider(widget.batchId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.rust,
        foregroundColor: AppColors.card,
        title: _AssignStaffTitle(
          batch: batchAsync.value,
          title: _showingReview ? 'Review assignment' : 'Assign staff',
        ),
      ),
      body: businessId == null
          ? const Center(child: Text('No business linked to this account.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: _showingReview
                  ? _buildReview(batchAsync.value)
                  : _buildStaffList(businessId, batchAsync.value),
            ),
    );
  }

  Widget _buildStaffList(String businessId, Batch? batch) {
    final assignedStaffId = batch?.assignedStaffId;

    return StreamBuilder<List<Account>>(
      stream: ref.watch(accountDomainProvider).watchStaffPool(businessId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final staffList = snapshot.data!;
        final assignedName = assignedStaffId == null
            ? null
            : staffList
                .where((staff) => staff.accountId == assignedStaffId)
                .firstOrNull
                ?.name;

        // The remove action stays reachable even when the pool comes
        // back empty: the batch can be assigned to someone whose
        // account is no longer active, and the Manager still needs a
        // way to clear that.
        if (staffList.isEmpty && assignedStaffId == null) {
          return const Center(child: Text('No active Staff accounts yet.'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (assignedStaffId != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed:
                      _isSaving ? null : () => _removeAssignment(assignedName),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brick,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  child: const Text(
                    'Remove current assignment',
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: AppColors.brick,
                    ),
                  ),
                ),
              ),
            if (staffList.isEmpty)
              const Center(child: Text('No active Staff accounts yet.'))
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: staffList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final staff = staffList[index];
                    final isAssigned = staff.accountId == assignedStaffId;
                    return _StaffRow(
                      name: staff.name,
                      isCurrentlyAssigned: isAssigned,
                      // Tapping the person already on the batch is a
                      // no-op: there is nothing to change, and the
                      // remove action is right above the list.
                      onTap: isAssigned
                          ? null
                          : () => setState(() {
                                _selectedStaff = staff;
                                _showingReview = true;
                                _errorMessage = null;
                              }),
                    );
                  },
                ),
              ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 12.5,
                  color: AppColors.brick,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildReview(Batch? batch) {
    final staff = _selectedStaff;
    if (staff == null) return const SizedBox.shrink();

    return ReviewStep(
      title: '',
      entries: [
        ReviewEntry('Batch', batch?.batchName ?? '—'),
        ReviewEntry('Assign to', staff.name),
      ],
      onEdit: () => setState(() => _showingReview = false),
      onConfirm: _isSaving ? () {} : _confirm,
      confirmLabel: _isSaving ? 'Saving...' : 'Confirm and save',
      note: 'Check this looks right before saving.',
    );
  }
}

/// One staff member in the picker: their name, plus a badge marking
/// whoever is on the batch right now. Built as a card like the other
/// lists in the app rather than a stock radio tile.
class _StaffRow extends StatelessWidget {
  const _StaffRow({
    required this.name,
    required this.isCurrentlyAssigned,
    this.onTap,
  });

  final String name;
  final bool isCurrentlyAssigned;

  /// Null for the currently assigned row — tapping it does nothing.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.hairlineStrong, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontFamily: 'RobotoSlab',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.ink,
                ),
              ),
            ),
            if (isCurrentlyAssigned)
              const AppBadge(
                label: 'Currently assigned',
                tone: BadgeTone.positive,
              ),
          ],
        ),
      ),
    );
  }
}

/// The AppBar title: "Assign staff" / "Review assignment" with the
/// batch's name underneath, e.g. "Batch 7".
class _AssignStaffTitle extends StatelessWidget {
  const _AssignStaffTitle({required this.batch, required this.title});

  final Batch? batch;
  final String title;

  @override
  Widget build(BuildContext context) {
    final batchName = batch?.batchName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'RobotoSlab',
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.card,
          ),
        ),
        if (batchName != null && batchName.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            'Batch $batchName',
            style: const TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 12,
              color: AppColors.parchment,
            ),
          ),
        ],
      ],
    );
  }
}
