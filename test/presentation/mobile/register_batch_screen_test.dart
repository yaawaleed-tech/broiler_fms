import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:broiler_fms/presentation/mobile/batch/register_batch_screen.dart';

/// The Manager's register-batch form. Proves the Review button stays
/// disabled until the form is valid, and that registering needs no
/// domain write to get that far — the button only flips local state.
///
/// No BatchDomain is overridden because nothing on this path reaches
/// it; the test would fail loudly (unimplemented provider) if it did.
Future<void> mount(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RegisterBatchScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Finder reviewButton() => find.widgetWithText(ElevatedButton, 'Review');

bool reviewEnabled(WidgetTester tester) =>
    tester.widget<ElevatedButton>(reviewButton()).onPressed != null;

void main() {
  testWidgets('the Review button starts disabled on an empty form',
      (tester) async {
    // Proves a blank form cannot be submitted (use case: Manager must
    // name the batch and give a bird count first).
    await mount(tester);
    expect(reviewEnabled(tester), isFalse);
  });

  testWidgets('a name alone is not enough without a bird count',
      (tester) async {
    // Proves the count is required, not just the name.
    await mount(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Batch name'),
      'House 1',
    );
    await tester.pumpAndSettle();
    expect(reviewEnabled(tester), isFalse);
  });

  testWidgets('a name and a positive count enable Review', (tester) async {
    // Proves the happy path enables the Review step (use case: Manager
    // fills the form and proceeds to review).
    await mount(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Batch name'),
      'House 1',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Starting bird count'),
      '100',
    );
    await tester.pumpAndSettle();
    expect(reviewEnabled(tester), isTrue);
  });

  testWidgets('a count of zero keeps Review disabled', (tester) async {
    // Proves the parsed count must be strictly positive.
    await mount(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Batch name'),
      'House 1',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Starting bird count'),
      '0',
    );
    await tester.pumpAndSettle();
    expect(reviewEnabled(tester), isFalse);
  });

  testWidgets('Review shows the step with the entered values',
      (tester) async {
    // Proves the review step echoes what was typed (use case: Manager
    // checks the batch before confirming).
    await mount(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Batch name'),
      'House 1',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Starting bird count'),
      '100',
    );
    await tester.pumpAndSettle();
    await tester.tap(reviewButton());
    await tester.pumpAndSettle();
    expect(find.text('Review new batch'), findsOneWidget);
    expect(find.text('House 1'), findsWidgets);
    expect(find.text('100'), findsWidgets);
  });
}
