import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/logout_domain.dart';
import 'package:broiler_fms/domain/session_poll_trigger.dart';
import 'package:broiler_fms/presentation/mobile/forced_logout.dart';
import 'package:broiler_fms/presentation/mobile/router.dart';

/// The forced lockout.
///
/// The 30-second access check finds an account that was deactivated and
/// has to send the person back to the login screen. Before the fix the
/// navigation was done with a `context.go` from a widget *above*
/// `MaterialApp.router`, so go_router could not find itself in that
/// context and threw; the session poller swallowed the error, so the
/// batches disappeared and the person was left on an empty screen that
/// could never load again.
///
/// The reference below deliberately sits *outside* `MaterialApp.router`,
/// exactly like the session poller does in the app, so a context-based
/// navigation would have nowhere to find the router.
class _FakeLogoutDomain extends Fake implements LogoutDomain {
  int forcedLogOutCalls = 0;

  @override
  Future<String?> forcedLogOut() async {
    forcedLogOutCalls++;
    return null;
  }
}

void main() {
  testWidgets('signs the account out and goes to the login screen', (
    tester,
  ) async {
    final logoutDomain = _FakeLogoutDomain();
    late WidgetRef capturedRef;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          logoutDomainProvider.overrideWithValue(logoutDomain),
          currentAccountProvider.overrideWith((ref) async => null),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ),
    );

    await forceLogOut(capturedRef);
    await tester.pumpAndSettle();

    // The sign-out and the local wipe are the lockout itself.
    expect(logoutDomain.forcedLogOutCalls, 1);

    // The navigation is what makes it a lockout rather than an empty
    // screen.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Consumer)),
    );
    final router = container.read(mobileRouterProvider);
    expect(router.routeInformationProvider.value.uri.path, '/login');

    // The person is told why they are back at the login screen.
    final state = router.routeInformationProvider.value.state as dynamic;
    expect(state.extra, forcedLogoutMessage);
  });

  testWidgets('drops the cached account so the app sees nobody signed in', (
    tester,
  ) async {
    // The router's redirect reads the cached account. If it is still
    // there, the redirect sends the person straight back into the app
    // they were just locked out of.
    final logoutDomain = _FakeLogoutDomain();
    var accountReads = 0;
    late WidgetRef capturedRef;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          logoutDomainProvider.overrideWithValue(logoutDomain),
          currentAccountProvider.overrideWith((ref) async {
            accountReads++;
            return null;
          }),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Consumer)),
    );
    await container.read(currentAccountProvider.future);
    final readsBefore = accountReads;

    await forceLogOut(capturedRef);
    await tester.pumpAndSettle();

    // The provider was invalidated, so reading it again recomputes it
    // instead of handing back the cached account.
    await container.read(currentAccountProvider.future);
    expect(accountReads, greaterThan(readsBefore));
  });
}
