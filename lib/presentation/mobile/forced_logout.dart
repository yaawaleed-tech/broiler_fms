import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/logout_domain.dart';
import 'package:broiler_fms/domain/session_poll_trigger.dart';
import 'package:broiler_fms/presentation/mobile/router.dart';

/// Signs the account out and sends the person back to the login screen.
///
/// Called when the 30-second access check finds this account, or the
/// Admin above it, deactivated. The sign-out and the local wipe are the
/// lockout itself; the navigation is what makes it a lockout rather than
/// an empty screen — without it the batches disappear and the person is
/// left staring at a list that can never load again.
///
/// Navigation goes through the router instance, not a `context.go`.
///
/// The caller here is the session poller, whose widget sits *above*
/// `MaterialApp.router` and therefore above the `InheritedGoRouter`
/// go_router installs inside the Navigator: `GoRouter.of(ancestor)`
/// throws "No GoRouter found in context", and the poller swallows that
/// throw, so the redirect silently never happened. A router read from the
/// provider needs no context at all, so it works from anywhere.
///
/// Lives in its own file, rather than in `main.dart`, so a test can call
/// it: `main.dart` is the app entry point and nothing imports it.
Future<void> forceLogOut(WidgetRef ref) async {
  try {
    await ref.read(logoutDomainProvider).forcedLogOut();
  } catch (_) {
    // Forced means forced: the lockout proceeds regardless.
  }
  // Drop the cached account, so the router's redirect sees nobody signed
  // in and lets the login screen through.
  ref.invalidate(currentAccountProvider);
  ref.read(mobileRouterProvider).go('/login', extra: forcedLogoutMessage);
}
