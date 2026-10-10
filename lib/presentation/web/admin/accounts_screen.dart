import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/account/remote_account_domain.dart';
import 'package:broiler_fms/domain/batch/remote_batch_domain.dart';
import 'package:broiler_fms/domain/business/business_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/badge.dart';
import 'package:broiler_fms/presentation/shared/widgets/confirm_dialog.dart';

class _AccountsData {
  const _AccountsData({
    required this.businessId,
    required this.accounts,
    required this.assignedBatchesMap,
  });

  final String businessId;
  final List<Account> accounts;
  final Map<String, List<String>> assignedBatchesMap;
}

final _accountsProvider = FutureProvider.autoDispose<_AccountsData>((
    ref,
    ) async {
  final business = await ref.watch(businessDomainProvider).getOwnBusiness();
  if (business == null) {
    return const _AccountsData(businessId: '', accounts: [], assignedBatchesMap: {});
  }
  final accounts = await ref
      .watch(remoteAccountDomainProvider)
      .getAccountsForBusiness(business.businessId);
  final assignedBatchesMap = await ref
      .watch(remoteBatchDomainProvider)
      .getAssignedBatchesMap();
  return _AccountsData(
    businessId: business.businessId,
    accounts: accounts,
    assignedBatchesMap: assignedBatchesMap,
  );
});

/// Admin's Manager + Staff management page: one Manager table, one
/// Staff table, each with add/deactivate/reactivate actions.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  BadgeTone _toneFor(String status) => switch (status) {
    'active' => BadgeTone.positive,
    'pending' => BadgeTone.warning,
    _ => BadgeTone.neutral,
  };

  Future<void> _updateStatus(
      WidgetRef ref,
      BuildContext context,
      String accountId,
      String status,
      ) async {
    try {
      await ref.read(remoteAccountDomainProvider).updateStatus(
        accountId,
        status,
      );
      ref.invalidate(_accountsProvider);
    } on DomainException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _reactivateManager(
      WidgetRef ref,
      BuildContext context,
      Account manager,
      String businessId,
      ) async {
    try {
      await ref.read(remoteAccountDomainProvider).reactivateManager(
        accountId: manager.accountId,
        businessId: businessId,
        targetStatus: manager.authUserId == null ? 'pending' : 'active',
      );
      ref.invalidate(_accountsProvider);
    } on DomainException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _confirmDeactivate(
      WidgetRef ref,
      BuildContext context,
      Account account,
      ) async {
    final isManager = account.role == 'manager';
    final confirmed = await showConfirmDialog(
      context,
      title: 'Deactivate ${account.name}?',
      body: isManager
          ? 'Nobody will be able to register batches or log expenses '
          'until a new Manager is added.'
          : 'This Staff member will no longer be able to sign in.',
      confirmLabel: 'Deactivate',
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    await _updateStatus(ref, context, account.accountId, 'inactive');
  }

  Future<void> _addAccount(
      WidgetRef ref,
      BuildContext context,
      String businessId,
      String role,
      ) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String? errorMessage;
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              if (name.isEmpty || email.isEmpty) return;

              setDialogState(() {
                isSaving = true;
                errorMessage = null;
              });

              try {
                await ref.read(remoteAccountDomainProvider).createStaffOrManager(
                  businessId: businessId,
                  role: role,
                  name: name,
                  email: email,
                );
                ref.invalidate(_accountsProvider);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              } on DomainException catch (e) {
                setDialogState(() {
                  errorMessage = e.message;
                  isSaving = false;
                });
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.parchment,
              title: Text(role == 'manager' ? 'Add Manager' : 'Add Staff'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          fontFamily: 'PublicSans',
                          fontSize: 12.5,
                          color: AppColors.brick,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : submit,
                  child: Text(isSaving ? 'Adding...' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_accountsProvider);

    return Scaffold(
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (data) {
          final managers =
              data.accounts.where((a) => a.role == 'manager').toList();
          final hasActiveOrPendingManager =
              managers.any((m) => m.status != 'inactive');
          final staff = data.accounts.where((a) => a.role == 'staff').toList();
          final activeOrPendingStaffCount =
              staff.where((a) => a.status != 'inactive').length;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Accounts',
                style: TextStyle(
                  fontFamily: 'RobotoSlab',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Manager',
                    style: TextStyle(
                      fontFamily: 'RobotoSlab',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: AppColors.ink,
                    ),
                  ),
                  if (!hasActiveOrPendingManager)
                    OutlinedButton(
                      onPressed: () => _addAccount(ref, context, data.businessId, 'manager'),
                      child: const Text('Add Manager'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (managers.isEmpty)
                const Text(
                  'This business needs exactly one Manager.',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 13,
                    color: AppColors.inkMuted,
                  ),
                )
              else
                Card(
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.hairlineStrong, width: 1.5),
                  ),
                  child: DataTable(
                    headingTextStyle: const TextStyle(
                      fontFamily: 'PublicSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.inkMuted,
                    ),
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: managers.map((manager) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              manager.name,
                              style: const TextStyle(
                                fontFamily: 'PublicSans',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              manager.email,
                              style: const TextStyle(
                                fontFamily: 'PublicSans',
                                fontSize: 13,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ),
                          DataCell(
                            AppBadge(label: manager.status, tone: _toneFor(manager.status)),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (manager.status != 'inactive')
                                  TextButton(
                                    onPressed: () => _confirmDeactivate(ref, context, manager),
                                    child: const Text('Deactivate'),
                                  ),
                                if (manager.status == 'inactive')
                                  TextButton(
                                    onPressed: () => _reactivateManager(
                                      ref,
                                      context,
                                      manager,
                                      data.businessId,
                                    ),
                                    child: const Text('Reactivate'),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Staff ($activeOrPendingStaffCount/18)',
                    style: const TextStyle(
                      fontFamily: 'RobotoSlab',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: AppColors.ink,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _addAccount(ref, context, data.businessId, 'staff'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rust,
                      foregroundColor: AppColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('+ Add staff'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (staff.isEmpty)
                const Text(
                  'No Staff accounts yet.',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 13,
                    color: AppColors.inkMuted,
                  ),
                )
              else
                Card(
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.hairlineStrong, width: 1.5),
                  ),
                  child: DataTable(
                    headingTextStyle: const TextStyle(
                      fontFamily: 'PublicSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.inkMuted,
                    ),
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Assigned batches')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: staff.map((account) {
                      final assignedBatches = data.assignedBatchesMap[account.accountId];
                      final assignedStr = (assignedBatches == null || assignedBatches.isEmpty)
                          ? 'None'
                          : assignedBatches.join(', ');
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              account.name,
                              style: const TextStyle(
                                fontFamily: 'PublicSans',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              account.email,
                              style: const TextStyle(
                                fontFamily: 'PublicSans',
                                fontSize: 13,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ),
                          DataCell(
                            AppBadge(label: account.status, tone: _toneFor(account.status)),
                          ),
                          DataCell(
                            Text(
                              assignedStr,
                              style: const TextStyle(
                                fontFamily: 'PublicSans',
                                fontSize: 13,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (account.status != 'inactive')
                                  TextButton(
                                    onPressed: () => _confirmDeactivate(ref, context, account),
                                    child: const Text('Deactivate'),
                                  ),
                                if (account.status == 'inactive')
                                  TextButton(
                                    onPressed: () => _updateStatus(
                                      ref,
                                      context,
                                      account.accountId,
                                      account.authUserId == null
                                          ? 'pending'
                                          : 'active',
                                    ),
                                    child: const Text(
                                      'Reactivate',
                                      style: TextStyle(color: AppColors.rust),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}