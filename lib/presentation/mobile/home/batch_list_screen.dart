import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/logout_domain.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/presentation/shared/formatting.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/badge.dart';
import 'package:broiler_fms/presentation/shared/widgets/confirm_dialog.dart';
import 'package:broiler_fms/presentation/mobile/widgets/sync_now_button.dart';
import 'package:broiler_fms/sync/sync_providers.dart';

/// Signs this device out: run one last sync attempt, then — depending
/// on what is still in the queue — hard-block with an explanation,
/// warn about rejected rows the server will never take, or confirm
/// plainly, then sign out of Supabase, wipe the local database, drop
/// the cached account so the router's redirect starts working again,
/// and go to /login. Shown to Manager and Staff alike.
Future<void> _logOut(BuildContext context, WidgetRef ref) async {
  final logoutDomain = ref.read(logoutDomainProvider);

  final UnsyncedCounts counts;
  try {
    counts = await logoutDomain.drainAndCountUnsyncedRows();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not read the data on this phone, so logging out was '
            'cancelled ($e).',
          ),
        ),
      );
    }
    return;
  }
  if (!context.mounted) return;

  // Rows that can still reach the server: logout is impossible until
  // they do. Not a "log out anyway" dialog — a plain explanation and
  // an OK, because there is genuinely no path forward here but to
  // wait for a connection and let the app sync.
  if (counts.blocking > 0) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cannot log out yet'),
        content: Text(
          counts.blocking == 1
              ? '1 record on this phone has not reached the server yet. '
                  'Logging out is only possible once everything has '
                  'synced, which needs a connection — leave the app open '
                  'and let it sync, then try again.'
              : '${counts.blocking} records on this phone have not '
                  'reached the server yet. Logging out is only possible '
                  'once everything has synced, which needs a connection '
                  '— leave the app open and let it sync, then try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return;
  }

  // Nothing blocking: anything still counted here is a rejected row
  // the server refused for good, so only a warning — logout proceeds.
  final confirmed = await showConfirmDialog(
    context,
    title: 'Log out?',
    body: counts.total == 0
        ? 'You will need to sign in again to continue.'
        : 'This phone holds ${counts.total} records that were never uploaded '
            'to the server, because the app cannot sync yet. Logging out '
            'will permanently delete them. You will need to sign in again '
            'to continue.',
    confirmLabel: 'Log out',
  );
  if (confirmed != true || !context.mounted) return;

  try {
    final warning = await logoutDomain.logOut();
    // Everything per-user hangs off this one provider: the Domain
    // classes watch it and the router reads its future on every
    // redirect, so refreshing it is what makes /login stick instead
    // of bouncing back to the home screen.
    ref.invalidate(currentAccountProvider);
    if (!context.mounted) return;
    context.go('/login');
    if (warning != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(warning)),
      );
    }
  } on DomainException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }
}

/// The batches this signed-in account should see: Staff sees only
/// their assigned batches, Manager sees every batch in the business.
/// This choice is Presentation's to make, Domain itself has no notion
/// of role, matching the project's stance from the start.
final _visibleBatchesProvider = StreamProvider.autoDispose<List<Batch>>((
    ref,
    ) async* {
  final account = await ref.watch(currentAccountProvider.future);
  if (account == null) {
    yield [];
    return;
  }
  final batchDomain = ref.watch(batchDomainProvider);
  if (account.role == 'staff') {
    yield* batchDomain.watchForStaff(account.accountId);
    return;
  }
  final businessId = account.businessId;
  if (businessId == null) {
    yield [];
    return;
  }
  yield* batchDomain.watchAllForBusiness(businessId);
});

/// Display-only snapshot of what the sync-status pill needs: whether
/// the device currently has any network, and how many rows are still
/// waiting in the local sync queue. Both sources are local (the OS
/// connectivity API and the Drift queue table) — nothing here talks
/// to the server.
/// Home screen: a list of batches, filtered by role. Manager also sees
/// a button to register a new batch, Staff does not.
class BatchListScreen extends ConsumerWidget {
  const BatchListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(_visibleBatchesProvider);
    final account = ref.watch(currentAccountProvider).value;
    final isManager = account?.role == 'manager';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.rust,
        foregroundColor: AppColors.card,
        title: const Text(
          'My batches',
          style: TextStyle(
            fontFamily: 'RobotoSlab',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.card,
          ),
        ),
        actions: [
          const SyncNowButton(),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const _SyncStatusPill(),
                TextButton(
                  onPressed: () => _logOut(context, ref),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.card,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Log out',
                    style: TextStyle(
                      fontFamily: 'PublicSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: batchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load batches: $error')),
        data: (batches) {
          if (batches.isEmpty) {
            return const Center(child: Text('No batches yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: batches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _BatchRow(batch: batches[index]);
            },
          );
        },
      ),
      floatingActionButton: isManager
          ? FloatingActionButton.extended(
        onPressed: () => context.push('/register-batch'),
        // No floatingActionButtonTheme exists in app_theme.dart, so
        // the colours are set explicitly to match the app's primary
        // action styling — the same rust fill and cream text the
        // ElevatedButton theme uses.
        backgroundColor: AppColors.rust,
        foregroundColor: AppColors.card,
        icon: const Icon(Icons.add),
        label: const Text(
          'New batch',
          style: TextStyle(
            fontFamily: 'PublicSans',
            fontWeight: FontWeight.w600,
            color: AppColors.card,
          ),
        ),
      )
          : null,
    );
  }
}

/// The dark pill in the AppBar showing whether this device is online
/// and whether everything recorded so far has reached the server.
class _SyncStatusPill extends ConsumerWidget {
  const _SyncStatusPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(syncStatusProvider);
    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (status) {
        final Color dotColor;
        final String label;
        if (!status.isOnline) {
          dotColor = AppColors.brick;
          label = 'Offline';
        } else if (status.pendingCount == 0) {
          dotColor = AppColors.olive;
          label = 'Online · synced';
        } else {
          dotColor = AppColors.amber;
          label = 'Online · ${status.pendingCount} pending';
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'PublicSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: AppColors.card,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One row in the batch list: name · breed, day and week of the batch,
/// a status badge, and the remaining-bird count on the right. Tapping
/// the row opens batch detail.
class _BatchRow extends ConsumerWidget {
  const _BatchRow({required this.batch});

  final Batch batch;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remainingAsync = ref.watch(_remainingProvider(batch.batchId));
    final day = _dayNumber;
    final week = ((day - 1) ~/ 7) + 1;

    return InkWell(
      onTap: () => context.push('/batches/${batch.batchId}'),
      child: Container(
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
                    'Day $day · Week $week',
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
                    style: const TextStyle(
                      fontFamily: 'RobotoSlab',
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    'remaining',
                    style: const TextStyle(
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
