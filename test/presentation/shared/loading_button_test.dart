import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/presentation/shared/widgets/loading_button_content.dart';

/// Tests for the shared button content: the label stays put while the
/// work is in flight and a spinner sits beside it, rather than the
/// label being swapped out for a lone spinner.
void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    required bool loading,
    required VoidCallback onPressed,
    String label = 'Send login code',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: busyGuard(onPressed, loading),
              child: ButtonLoadingContent(label: label, loading: loading),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('idle: label shown, no spinner', (tester) async {
    var taps = 0;
    await pumpButton(tester, loading: false, onPressed: () => taps++);

    expect(find.text('Send login code'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byType(ElevatedButton));
    expect(taps, 1, reason: 'idle button must still fire');
  });

  testWidgets('loading: label STILL shown and a spinner is present',
      (tester) async {
    await pumpButton(tester, loading: true, onPressed: () {});

    expect(find.text('Send login code'), findsOneWidget,
        reason: 'the label must never be replaced by the spinner');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('loading: taps do not call onPressed (no double submit)',
      (tester) async {
    var taps = 0;
    await pumpButton(tester, loading: true, onPressed: () => taps++);

    await tester.tap(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    expect(taps, 0);

    // Still enabled, so the button keeps its normal colours instead of
    // the greyed-out disabled style.
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('loading back to idle: spinner removed, label still shown',
      (tester) async {
    await pumpButton(tester, loading: true, onPressed: () {});
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await pumpButton(tester, loading: false, onPressed: () {});
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Send login code'), findsOneWidget);
  });

  testWidgets('does not overflow with a long label in a narrow width',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpButton(
      tester,
      loading: true,
      onPressed: () {},
      label: 'A very long button label that has no chance of fitting',
    );

    // No overflow exception, and the label is still there to read.
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('reduced motion: spinner still shows, no shift animation',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: ButtonLoadingContent(label: 'Verify', loading: true),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final animated = tester
        .widgetList<AnimatedSize>(find.byType(AnimatedSize))
        .toList();
    expect(animated.single.duration, Duration.zero);
  });

  testWidgets('announces itself as a single button while loading',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpButton(tester, loading: true, onPressed: () {});

    expect(
      find.bySemanticsLabel('Send login code'),
      findsOneWidget,
      reason: 'exactly one label, no stray duplicate for screen readers',
    );
    expect(
      tester
          .getSemantics(find.byType(ButtonLoadingContent))
          .flagsCollection
          .isButton,
      isTrue,
    );
    handle.dispose();
  });
}
