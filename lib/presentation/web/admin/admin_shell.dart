import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/domain/session_poll_trigger.dart';
import 'package:broiler_fms/domain/web_auth_domain_provider.dart';
import 'package:broiler_fms/domain/web_current_account_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/confirm_dialog.dart';
import 'package:broiler_fms/presentation/shared/widgets/session_poller.dart';

/// The persistent sidebar shared by every Admin page. go_router's
/// ShellRoute keeps this on screen while [child] swaps underneath it,
/// matching every web mockup's sidebar + content layout, rather than
/// mobile's full-screen push navigation.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

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
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 220,
            color: AppColors.parchment,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Broiler FMS',
                    style: TextStyle(
                      fontFamily: 'RobotoSlab',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _NavItem(
                  label: 'Overview',
                  isSelected: location == '/overview',
                  onTap: () => context.go('/overview'),
                ),
                _NavItem(
                  label: 'Accounts',
                  isSelected: location == '/accounts',
                  onTap: () => context.go('/accounts'),
                ),
                _NavItem(
                  label: 'Batches',
                  isSelected: location.startsWith('/batches'),
                  onTap: () => context.go('/batches'),
                ),
                const Spacer(),
                _NavItem(
                  label: 'Log out',
                  isSelected: false,
                  onTap: () => _logOut(context, ref),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: SessionPoller(
              onAccessLost: () => _forceLogOut(context, ref),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? AppColors.oliveBg : Colors.transparent,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'PublicSans',
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13.5,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}