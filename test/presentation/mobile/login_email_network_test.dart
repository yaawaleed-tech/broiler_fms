import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/domain/auth_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/mobile_auth_domain_provider.dart';
import 'package:broiler_fms/presentation/mobile/login/email_screen.dart';

/// The screen half of the no-internet fix.
///
/// The domain turns a dead network into a DomainException; these prove
/// the login screen then actually shows it, stops spinning, stays put,
/// and remains usable — the four things that were missing when a tap
/// looked like it had been ignored.
void main() {
  const noInternet =
      'No internet connection. Check your network and try again.';

  late _FakeAuthDomain authDomain;

  setUp(() {
    authDomain = _FakeAuthDomain();
  });

  /// Mounts the real screen inside a real router, so a successful send
  /// really navigates and a failed one really does not — which is the
  /// difference this fix is about.
  Future<void> mount(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const EmailScreen(),
        ),
        GoRoute(
          path: '/login/code',
          builder: (context, state) => const Scaffold(body: Text('code screen')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authDomainProvider.overrideWithValue(authDomain)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// True once the app has moved on to the code screen.
  bool navigatedAway(WidgetTester tester) =>
      find.text('code screen').evaluate().isNotEmpty;

  Future<void> typeEmailAndTap(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'sam@example.com');
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
  }

  testWidgets('a network failure shows the message and stops the spinner',
      (tester) async {
    authDomain.error = const DomainException(noInternet);
    await mount(tester);

    await typeEmailAndTap(tester);
    await tester.pumpAndSettle();

    expect(find.text(noInternet), findsOneWidget,
        reason: 'the user must be told why nothing happened');
    expect(find.byType(CircularProgressIndicator), findsNothing,
        reason: 'the spinner must stop, or the button looks stuck');
    expect(navigatedAway(tester), isFalse,
        reason: 'a failed send must not navigate anywhere');
  });

  testWidgets('the spinner is showing while the call is in flight',
      (tester) async {
    final gate = Completer<void>();
    authDomain.gate = gate;
    await mount(tester);

    await typeEmailAndTap(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Send login code'), findsOneWidget,
        reason: 'the label stays, so the button still reads as itself');

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('the button is usable again after a failure', (tester) async {
    authDomain.error = const DomainException(noInternet);
    await mount(tester);

    await typeEmailAndTap(tester);
    await tester.pumpAndSettle();
    expect(authDomain.calls, 1);

    // Second tap, this time the network behaves.
    authDomain.error = null;
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(authDomain.calls, 2,
        reason: 'the loading flag reset, so the tap was not swallowed');
    expect(navigatedAway(tester), isTrue,
        reason: 'and the retry now succeeds and moves on');
  });

  testWidgets('the message is cleared when a retry starts', (tester) async {
    authDomain.error = const DomainException(noInternet);
    await mount(tester);

    await typeEmailAndTap(tester);
    await tester.pumpAndSettle();
    expect(find.text(noInternet), findsOneWidget);

    final gate = Completer<void>();
    authDomain.error = null;
    authDomain.gate = gate;
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text(noInternet), findsNothing,
        reason: 'a stale error must not sit under a fresh attempt');
    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('a second tap while loading does not send twice',
      (tester) async {
    final gate = Completer<void>();
    authDomain.gate = gate;
    await mount(tester);

    await typeEmailAndTap(tester);
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(authDomain.calls, 1, reason: 'no double submit');

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('an invalid email never reaches the network', (tester) async {
    await mount(tester);

    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(authDomain.calls, 0);
    expect(find.text('Enter a valid email address.'), findsOneWidget,
        reason: 'validation still explains itself rather than failing quietly');
  });
}

/// A stand-in for AuthDomain that records its calls and can be told to
/// fail or to hang, which is all the screen depends on.
class _FakeAuthDomain extends Fake implements AuthDomain {
  int calls = 0;

  /// Thrown by the next send, or null for a clean one.
  DomainException? error;

  /// When set, the call waits on this before returning.
  Completer<void>? gate;

  @override
  Future<void> sendLoginCode(String email) async {
    calls++;
    final pending = gate;
    if (pending != null) await pending.future;
    final failure = error;
    if (failure != null) throw failure;
  }
}