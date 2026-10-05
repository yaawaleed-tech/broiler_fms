import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/account/remote_account_domain.dart';
import 'package:broiler_fms/domain/web_auth_domain_provider.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/badge.dart';
import 'package:broiler_fms/presentation/shared/widgets/confirm_dialog.dart';
import 'package:go_router/go_router.dart';

final _adminsProvider = FutureProvider.autoDispose<List<Account>>(
      (ref) => ref.watch(remoteAccountDomainProvider).getAdmins(),
);

Future<void> _updateStatus(
    WidgetRef ref,
    BuildContext context,
    String accountId,
    String status,
    ) async {
  try {
    await ref.read(remoteAccountDomainProvider).updateStatus(accountId, status);
    ref.invalidate(_adminsProvider);
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
  final confirmed = await showConfirmDialog(
    context,
    title: 'Deactivate ${account.name}?',
    body: 'This Admin will no longer be able to sign in, and their '
        'business will have no one to manage it until reactivated.',
    confirmLabel: 'Deactivate',
  );
  if (confirmed != true) return;
  if (!context.mounted) return;
  await _updateStatus(ref, context, account.accountId, 'inactive');
}

/// Super Admin's entire app: one page, Admin accounts only. One
/// Admin account per business, Super Admin never sees into a
/// business's own data, by design.
class AdminAccountsScreen extends ConsumerWidget {
  const AdminAccountsScreen({super.key});

  Future<void> _addAdmin(WidgetRef ref, BuildContext context) async {
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
                await ref
                    .read(remoteAccountDomainProvider)
                    .createAdmin(name: name, email: email);
                ref.invalidate(_adminsProvider);
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
              title: const Text('Add Admin'),
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

  Future<void> _logOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      body: 'You will need to sign in again to continue.',
      confirmLabel: 'Log out',
    );
    if (confirmed != true) return;

    await ref.read(authDomainProvider).logOut();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(_adminsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin accounts'),
        actions: [
          TextButton(
            onPressed: () => _logOut(context, ref),
            child: const Text('Log out'),
          ),
        ],
      ),
      body: adminsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (admins) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => _addAdmin(ref, context),
                  child: const Text('Add Admin'),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: admins.isEmpty
                    ? const Center(child: Text('No Admins yet.'))
                    : ListView.separated(
                  itemCount: admins.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _AdminRow(account: admins[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminRow extends ConsumerWidget {
  const _AdminRow({required this.account});

  final Account account;

  BadgeTone get _tone => switch (account.status) {
    'active' => BadgeTone.positive,
    'pending' => BadgeTone.warning,
    _ => BadgeTone.neutral,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                Text(
                  account.businessId == null
                      ? 'Not yet registered'
                      : 'Business registered',
                  style: const TextStyle(
                    fontFamily: 'PublicSans',
                    fontSize: 11.5,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          AppBadge(label: account.status, tone: _tone),
          const SizedBox(width: 12),
          if (account.status == 'active')
            TextButton(
              onPressed: () => _confirmDeactivate(ref, context, account),
              child: const Text('Deactivate'),
            ),
          if (account.status == 'inactive')
            TextButton(
              onPressed: () =>
                  _updateStatus(ref, context, account.accountId, 'active'),
              child: const Text('Reactivate'),
            ),
        ],
      ),
    );
  }
}