import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/badge.dart';

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
      appBar: AppBar(title: const Text('Batches')),
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