import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/logout_domain.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/badge.dart';
import 'package:broiler_fms/presentation/shared/widgets/confirm_dialog.dart';

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
        title: const Text('Batches'),
        actions: [
          TextButton(
            onPressed: () => _logOut(context, ref),
            child: const Text('Log out'),
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
          ? FloatingActionButton(
        onPressed: () => context.push('/register-batch'),
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}

/// One row in the batch list: name, breed, and a remaining-bird count,
/// tapping it opens batch detail.
class _BatchRow extends ConsumerWidget {
  const _BatchRow({required this.batch});

  final Batch batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  Text(
                    batch.batchName,
                    style: const TextStyle(
                      fontFamily: 'RobotoSlab',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.ink,
                    ),
                  ),
                  if (batch.breed != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      batch.breed!,
                      style: const TextStyle(
                        fontFamily: 'PublicSans',
                        fontSize: 12.5,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _RemainingBadge(batch: batch),
          ],
        ),
      ),
    );
  }
}

/// Fetches and shows this one batch's remaining-bird count, or a
/// closed badge if the batch is already closed.
class _RemainingBadge extends ConsumerWidget {
  const _RemainingBadge({required this.batch});

  final Batch batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (batch.isClosed) {
      return const AppBadge(label: 'Closed', tone: BadgeTone.neutral);
    }
    final remainingAsync = ref.watch(_remainingProvider(batch.batchId));
    return remainingAsync.when(
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (remaining) {
        final tone = remaining <= 0 ? BadgeTone.warning : BadgeTone.positive;
        final label = remaining <= 0 ? 'Ready to close' : '$remaining left';
        return AppBadge(label: label, tone: tone);
      },
    );
  }
}

final _remainingProvider = FutureProvider.autoDispose.family<int, String>(
      (ref, batchId) => ref.watch(batchDomainProvider).getRemainingBirdCount(batchId),
);