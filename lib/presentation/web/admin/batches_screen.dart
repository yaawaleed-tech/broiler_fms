import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:broiler_fms/domain/batch/remote_batch_domain.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/badge.dart';

/// Admin's read-only list of every batch in the business. Tapping a
/// row opens that batch's financial summary.
class BatchesScreen extends ConsumerWidget {
  const BatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batches')),
      body: FutureBuilder<List<Batch>>(
        future: ref.watch(remoteBatchDomainProvider).getAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final batches = snapshot.data!;
          if (batches.isEmpty) {
            return const Center(child: Text('No batches yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: batches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final batch = batches[index];
              return InkWell(
                onTap: () => context.push('/batches/${batch.batchId}'),
                child: Container(
                  padding: const EdgeInsets.all(14),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              batch.batchName,
                              style: const TextStyle(
                                fontFamily: 'RobotoSlab',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              DateFormat.yMMMd().format(batch.startDate),
                              style: const TextStyle(
                                fontFamily: 'PublicSans',
                                fontSize: 12,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppBadge(
                        label: batch.isClosed ? 'Closed' : 'Active',
                        tone: batch.isClosed
                            ? BadgeTone.neutral
                            : BadgeTone.positive,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}