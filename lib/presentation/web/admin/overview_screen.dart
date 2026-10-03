import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/domain/account/remote_account_domain.dart';
import 'package:broiler_fms/domain/business/business_domain.dart';
import 'package:broiler_fms/domain/models/business.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/stat_card.dart';

class _OverviewData {
  const _OverviewData({
    required this.business,
    required this.staffCount,
    required this.hasActiveManager,
    required this.pendingInviteCount,
  });

  final Business? business;
  final int staffCount;
  final bool hasActiveManager;
  final int pendingInviteCount;
}

final _overviewProvider =
FutureProvider.autoDispose<_OverviewData>((ref) async {
  final business = await ref.watch(businessDomainProvider).getOwnBusiness();
  if (business == null) {
    return const _OverviewData(
      business: null,
      staffCount: 0,
      hasActiveManager: false,
      pendingInviteCount: 0,
    );
  }

  final accounts = await ref
      .watch(remoteAccountDomainProvider)
      .getAccountsForBusiness(business.businessId);

  final staffCount =
      accounts.where((a) => a.role == 'staff' && a.status != 'inactive').length;
  final hasActiveManager =
  accounts.any((a) => a.role == 'manager' && a.status == 'active');
  final pendingInviteCount = accounts.where((a) => a.status == 'pending').length;

  return _OverviewData(
    business: business,
    staffCount: staffCount,
    hasActiveManager: hasActiveManager,
    pendingInviteCount: pendingInviteCount,
  );
});

/// Admin's landing page: business details and three summary counts.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_overviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Overview')),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (data) => _buildBody(context, data),
      ),
    );
  }

  Widget _buildBody(BuildContext context, _OverviewData data) {
    final business = data.business;
    if (business == null) {
      return const Center(child: Text('No business found.'));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                business.name,
                style: const TextStyle(
                  fontFamily: 'RobotoSlab',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: AppColors.ink,
                ),
              ),
              OutlinedButton(
                onPressed: () => context.push('/edit-business'),
                child: const Text('Edit'),
              ),
            ],
          ),
          if (business.address != null) ...[
            const SizedBox(height: 4),
            Text(
              business.address!,
              style: const TextStyle(
                fontFamily: 'PublicSans',
                fontSize: 13.5,
                color: AppColors.inkMuted,
              ),
            ),
          ],
          const SizedBox(height: 24),
          StatCardRow(
            cards: [
              StatCard(value: '${data.staffCount}', label: 'Staff accounts'),
              StatCard(
                value: data.hasActiveManager ? 'Active' : 'None',
                label: 'Manager status',
              ),
              StatCard(
                value: '${data.pendingInviteCount}',
                label: 'Pending invites',
              ),
            ],
          ),
        ],
      ),
    );
  }
}