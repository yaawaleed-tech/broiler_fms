import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/domain/web_current_account_domain.dart';
import 'package:broiler_fms/presentation/web/admin/accounts_screen.dart';
import 'package:broiler_fms/presentation/web/admin/admin_shell.dart';
import 'package:broiler_fms/presentation/web/admin/batch_view_screen.dart';
import 'package:broiler_fms/presentation/web/admin/batches_screen.dart';
import 'package:broiler_fms/presentation/web/admin/edit_business_screen.dart';
import 'package:broiler_fms/presentation/web/admin/overview_screen.dart';
import 'package:broiler_fms/presentation/web/admin/register_business_screen.dart';
import 'package:broiler_fms/presentation/web/login/code_screen.dart';
import 'package:broiler_fms/presentation/web/login/email_screen.dart';
import 'package:broiler_fms/presentation/web/superadmin/admin_accounts_screen.dart';

/// Web's route tree. Admin and Super Admin share login. '/' is Super
/// Admin's whole app (no sidebar); Admin is redirected from '/' to
/// '/overview', which lives inside AdminShell's sidebar.
final webRouterProvider = Provider<GoRouter>((ref) {
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final account = await ref.read(webCurrentAccountProvider.future);
    final isLoggingIn = state.matchedLocation.startsWith('/login');
    final isRegisteringBusiness =
        state.matchedLocation == '/register-business';

    if (account == null) {
      return isLoggingIn ? null : '/login';
    }
    if (isLoggingIn) return '/';

    final needsBusiness =
        account.role == 'admin' && account.businessId == null;
    if (needsBusiness && !isRegisteringBusiness) {
      return '/register-business';
    }
    if (!needsBusiness && isRegisteringBusiness) {
      return '/';
    }

    // Admin's home lives at /overview, inside the sidebar shell.
    // Super Admin's home is '/' itself, with no shell.
    if (account.role == 'admin' && state.matchedLocation == '/') {
      return '/overview';
    }
    return null;
  }

  return GoRouter(
    initialLocation: '/',
    redirect: redirect,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final message = state.extra as String?;
          return EmailScreen(message: message);
        },
      ),
      GoRoute(
        path: '/login/code',
        builder: (context, state) {
          final email = state.extra as String;
          return CodeScreen(email: email);
        },
      ),
      GoRoute(
        path: '/register-business',
        builder: (context, state) => const RegisterBusinessScreen(),
      ),
      GoRoute(
        path: '/edit-business',
        builder: (context, state) => const EditBusinessScreen(),
      ),
      // Super Admin's whole app. No sidebar, matching the mockup.
      GoRoute(
        path: '/',
        builder: (context, state) => const AdminAccountsScreen(),
      ),
      // Admin's app, wrapped in the persistent sidebar.
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/overview',
            builder: (context, state) => const OverviewScreen(),
          ),
          GoRoute(
            path: '/accounts',
            builder: (context, state) => const AccountsScreen(),
          ),
          GoRoute(
            path: '/batches',
            builder: (context, state) => const BatchesScreen(),
          ),
          GoRoute(
            path: '/batches/:batchId',
            builder: (context, state) {
              final batchId = state.pathParameters['batchId']!;
              return BatchViewScreen(batchId: batchId);
            },
          ),
        ],
      ),
    ],
  );
});