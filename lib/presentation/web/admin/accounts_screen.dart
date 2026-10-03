import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/account/remote_account_domain.dart';
import 'package:broiler_fms/domain/business/business_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/badge.dart';
import 'package:broiler_fms/presentation/shared/widgets/confirm_dialog.dart';

class _AccountsData {
  const _AccountsData({required this.businessId, required this.accounts});

  final String businessId;
  final List<Account> accounts;
}

final _accountsProvider = FutureProvider.autoDispose<_AccountsData>((
    ref,
    ) async {
  final business = await ref.watch(businessDomainProvider).getOwnBusiness();
  if (business == null) {
    return const _AccountsData(businessId: '', accounts: []);
  }
  final accounts = await ref
      .watch(remoteAccountDomainProvider)
      .getAccountsForBusiness(business.businessId);
  return _AccountsData(businessId: business.businessId, accounts: accounts);
});

/// Admin's Manager + Staff management page: one Manager panel, one
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
      appBar: AppBar(title: const Text('Accounts')),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (data) {
          final manager = data.accounts
              .where((a) => a.role == 'manager' && a.status != 'inactive')
              .firstOrNull;
          final staff = data.accounts.where((a) => a.role == 'staff').toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _SectionHeader(
                title: 'Manager',
                onAdd: manager == null
                    ? () => _addAccount(ref, context, data.businessId, 'manager')
                    : null,
                addLabel: 'Add Manager',
              ),
              const SizedBox(height: 12),
              if (manager == null)
                const Text(
                  'This business needs exactly one Manager.',
                  style: TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 13,
                    color: AppColors.inkMuted,
                  ),
                )
              else
                _AccountRow(
                  account: manager,
                  tone: _toneFor(manager.status),
                  onDeactivate: manager.status == 'active'
                      ? () => _confirmDeactivate(ref, context, manager)
                      : null,
                  onReactivate: manager.status == 'inactive'
                      ? () => _updateStatus(
                    ref,
                    context,
                    manager.accountId,
                    'active',
                  )
                      : null,
                ),
              const SizedBox(height: 32),
              _SectionHeader(
                title: 'Staff',
                onAdd: () => _addAccount(ref, context, data.businessId, 'staff'),
                addLabel: 'Add Staff',
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
                for (final account in staff) ...[
                  _AccountRow(
                    account: account,
                    tone: _toneFor(account.status),
                    onDeactivate: account.status != 'inactive'
                        ? () => _confirmDeactivate(ref, context, account)
                        : null,
                    onReactivate: account.status == 'inactive'
                        ? () => _updateStatus(
                      ref,
                      context,
                      account.accountId,
                      'active',
                    )
                        : null,
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onAdd,
    required this.addLabel,
  });

  final String title;
  final VoidCallback? onAdd;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'RobotoSlab',
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.ink,
          ),
        ),
        if (onAdd != null)
          OutlinedButton(onPressed: onAdd, child: Text(addLabel)),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.tone,
    required this.onDeactivate,
    required this.onReactivate,
  });

  final Account account;
  final BadgeTone tone;
  final VoidCallback? onDeactivate;
  final VoidCallback? onReactivate;

  @override
  Widget build(BuildContext context) {
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
                Text(
                  account.name,
                  style: const TextStyle(
                    fontFamily: 'PublicSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  account.email,
                  style: const TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 12,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          AppBadge(label: account.status, tone: tone),
          const SizedBox(width: 12),
          if (onDeactivate != null)
            TextButton(onPressed: onDeactivate, child: const Text('Deactivate')),
          if (onReactivate != null)
            TextButton(onPressed: onReactivate, child: const Text('Reactivate')),
        ],
      ),
    );
  }
}