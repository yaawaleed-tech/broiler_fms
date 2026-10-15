import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/account/remote_account_domain.dart';
import 'package:broiler_fms/domain/session_poll_trigger.dart';
import 'package:broiler_fms/domain/web_auth_domain_provider.dart';
import 'package:broiler_fms/domain/web_current_account_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/badge.dart';
import 'package:broiler_fms/presentation/shared/widgets/confirm_dialog.dart';
import 'package:broiler_fms/presentation/shared/widgets/session_poller.dart';
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
              final email = emailController.text.trim().toLowerCase();
              // Both fields are required; say so instead of doing nothing.
              if (name.isEmpty || email.isEmpty) {
                setDialogState(() {
                  errorMessage = 'Enter a name and an email address.';
                });
                return;
              }
              // Same simple rule as the login screen.
              if (!email.contains('@')) {
                setDialogState(() {
                  errorMessage = 'Enter a valid email address.';
                });
                return;
              }

              // New: check email doesn't already exist among accounts
              final alreadyExists = await ref
                  .read(remoteAccountDomainProvider)
                  .emailExists(
                    email: email,
                    // excludingAccountId: null for create; future edit
                    // flows can pass the existing account's accountId
                  );
              if (alreadyExists) {
                setDialogState(() {
                  errorMessage = 'An account with this email already exists';
                  isSaving = false;
                });
                return;
              }

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
              } catch (e) {
                // Show business rules as written; hide raw database text.
                setDialogState(() {
                  errorMessage = e is DomainException
                      ? e.message
                      : 'Could not add the account. Try again.';
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
    if (!context.mounted) return;

    try {
      await ref.read(authDomainProvider).logOut();
      ref.invalidate(webCurrentAccountProvider);
      if (context.mounted) context.go('/login');
    } on DomainException catch (e) {
      ref.invalidate(webCurrentAccountProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
        context.go('/login');
      }
    } catch (e) {
      // signOut can throw a raw AuthException/AuthRetryableFetchException,
      // not just DomainException — surface it instead of swallowing it.
      ref.invalidate(webCurrentAccountProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not log out: $e')),
        );
        context.go('/login');
      }
    }
  }

  /// Forced logout from the session poller: the same core as [_logOut]
  /// (end the session, drop the cached account, go to login with an
  /// explanation) but no confirm dialog — losing access is not
  /// voluntary, and the message travels on the route, not a snackbar.
  Future<void> _forceLogOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authDomainProvider).logOut();
    } catch (_) {
      // Forced means forced: the session is unusable either way, so a
      // failing sign-out must not stop the lockout.
    }
    ref.invalidate(webCurrentAccountProvider);
    if (context.mounted) {
      context.go('/login', extra: forcedLogoutMessage);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(_adminsProvider);

    return SessionPoller(
      onAccessLost: () => _forceLogOut(context, ref),
      child: Scaffold(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Admin accounts',
                    style: TextStyle(
                      fontFamily: 'RobotoSlab',
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: AppColors.ink,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _addAdmin(ref, context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rust,
                      foregroundColor: AppColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('+ Add admin'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'One Admin account per business. Business profiles, staff, batches, and finances are managed entirely within each business and are not visible here.',
                style: TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 13.5,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: admins.isEmpty
                    ? const Center(child: Text('No Admins yet.'))
                    : SingleChildScrollView(
                  child: Card(
                    color: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(
                          color: AppColors.hairlineStrong, width: 1.5),
                    ),
                    child: DataTable(
                      headingTextStyle: const TextStyle(
                        fontFamily: 'PublicSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppColors.inkMuted,
                      ),
                      columns: const [
                        DataColumn(label: Text('NAME')),
                        DataColumn(label: Text('EMAIL')),
                        DataColumn(label: Text('BUSINESS')),
                        DataColumn(label: Text('STATUS')),
                        DataColumn(label: Text('ACTIONS')),
                      ],
                      rows: admins.map((account) {
                        final tone = switch (account.status) {
                          'active' => BadgeTone.positive,
                          'pending' => BadgeTone.warning,
                          _ => BadgeTone.neutral,
                        };
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
                              Text(
                                account.businessId == null
                                    ? 'Not yet registered'
                                    : (account.businessName ??
                                    'Business registered'),
                                style: const TextStyle(
                                  fontFamily: 'PublicSans',
                                  fontSize: 13,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            DataCell(
                              AppBadge(label: account.status, tone: tone),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (account.status != 'inactive')
                                    TextButton(
                                      onPressed: () => _confirmDeactivate(
                                          ref, context, account),
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
                                            : 'active'),
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
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
