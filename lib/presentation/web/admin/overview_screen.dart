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
    required this.managerStatus,
    required this.pendingInviteCount,
  });

  final Business? business;
  final int staffCount;

  /// 'Active', 'Pending' (invited but not yet logged in), or 'None'
  /// (no Manager, or the only one is inactive).
  final String managerStatus;
  final int pendingInviteCount;
}

final _overviewProvider =
FutureProvider.autoDispose<_OverviewData>((ref) async {
  final business = await ref.watch(businessDomainProvider).getOwnBusiness();
  if (business == null) {
    return const _OverviewData(
      business: null,
      staffCount: 0,
      managerStatus: 'None',
      pendingInviteCount: 0,
    );
  }

  final accounts = await ref
      .watch(remoteAccountDomainProvider)
      .getAccountsForBusiness(business.businessId);

  final staffCount =
      accounts.where((a) => a.role == 'staff' && a.status != 'inactive').length;
  final managers = accounts.where((a) => a.role == 'manager');
  final currentManager = managers.where((m) => m.status == 'active').firstOrNull
      ?? managers.where((m) => m.status == 'pending').firstOrNull;
  final managerStatus = switch (currentManager?.status) {
    'active' => 'Active',
    'pending' => 'Pending',
    _ => 'None', // no manager row, or every manager row is inactive
  };
  final pendingInviteCount = accounts.where((a) => a.status == 'pending').length;

  return _OverviewData(
    business: business,
    staffCount: staffCount,
    managerStatus: managerStatus,
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
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (data) => _buildBody(context, ref, data),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, _OverviewData data) {
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
              const Text(
                'Business overview',
                style: TextStyle(
                  fontFamily: 'RobotoSlab',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: AppColors.ink,
                ),
              ),
              OutlinedButton(
                onPressed: () => context.push('/edit-business'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.hairlineStrong, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('Edit business profile'),
              ),
              // Reloads this screen's data from Supabase.
              IconButton(
                onPressed: () => ref.invalidate(_overviewProvider),
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                color: AppColors.ink,
              ),
            ],
          ),
          const SizedBox(height: 24),
          StatCardRow(
            cards: [
              StatCard(value: '${data.staffCount}', label: 'Staff accounts'),
              StatCard(
                value: data.managerStatus,
                label: 'Manager account',
              ),
              StatCard(
                value: '${data.pendingInviteCount}',
                label: 'Pending invites',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            color: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.hairlineStrong, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Business profile',
                    style: TextStyle(
                      fontFamily: 'RobotoSlab',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ProfileRow(label: 'Business name', value: business.name),
                  const Divider(height: 24, color: AppColors.hairline),
                  _ProfileRow(label: 'Address', value: business.address ?? '—'),
                  const Divider(height: 24, color: AppColors.hairline),
                  _ProfileRow(label: 'Phone', value: business.phone ?? '—'),
                  const Divider(height: 24, color: AppColors.hairline),
                  _ProfileRow(label: 'Business type', value: business.businessType ?? '—'),
                  const Divider(height: 24, color: AppColors.hairline),
                  _ProfileRow(label: 'Description', value: business.description ?? '—'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'PublicSans',
              fontSize: 13.5,
              color: AppColors.inkMuted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'PublicSans',
              fontWeight: FontWeight.w500,
              fontSize: 13.5,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}