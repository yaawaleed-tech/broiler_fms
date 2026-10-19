import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/expense/expense_domain.dart';
import 'package:broiler_fms/domain/feed/feed_domain.dart';
import 'package:broiler_fms/domain/harvest/harvest_domain.dart';
import 'package:broiler_fms/domain/mortality/mortality_domain.dart';
import 'package:broiler_fms/domain/sale/sale_domain.dart';
import 'package:broiler_fms/domain/vaccination/vaccination_domain.dart';
import 'package:broiler_fms/domain/weight/weight_domain.dart';
import 'package:broiler_fms/presentation/mobile/widgets/sync_now_button.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/sync/pull_service.dart';
import 'package:broiler_fms/sync/sync_providers.dart';
import 'package:broiler_fms/sync/sync_result.dart';
import 'package:broiler_fms/sync/sync_service.dart';
import 'package:broiler_fms/sync/triggers/auto_pull_trigger.dart';

/// The Sync now icon, as an animation.
///
/// The bug these lock down: while a sync ran the icon was *replaced* by a
/// CircularProgressIndicator, and that spinner inherited the theme's
/// primary — which is `AppColors.rust`, the very colour of the AppBar
/// behind it. The person saw the button melt into the bar. The icon must
/// now stay in the tree, in its own cream, and turn.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Held open until the test releases it, so a sync can be caught mid-run.
  Completer<void>? gate;

  ({AutoPullTrigger trigger, _ScriptedPull pull, _ScriptedSync sync}) build() {
    final sync = _ScriptedSync();
    final pull = _ScriptedPull();
    final trigger = AutoPullTrigger(
      sync,
      pull,
      hasAccount: () => true,
      isConnected: () async => true,
      connectivity: _FakeConnectivity(),
    );
    sync.gate = () => gate;
    pull.gate = () => gate;
    return (trigger: trigger, pull: pull, sync: sync);
  }

  /// Bounded rather than pumpAndSettle: an animation left running would
  /// hang the test instead of failing it.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> mount(
    WidgetTester tester, {
    required AutoPullTrigger trigger,
    bool disableAnimations = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          autoPullTriggerProvider.overrideWithValue(trigger),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.rust,
              actions: [
                MediaQuery(
                  data: MediaQueryData(disableAnimations: disableAnimations),
                  child: const SyncNowButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> tapSync(WidgetTester tester) async {
    await tester.tap(find.byType(IconButton));
    await tester.pump();
  }

  /// Unmounts first, then lets Drift's own cancel-timer finish: it is
  /// scheduled when a stream closes, and a pending timer fails the test on
  /// an assertion unrelated to anything under test.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  }

  Future<void> spinOut(WidgetTester tester) async {
    // Comfortably past one revolution plus the minimum.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  // Material 3's Tooltip brings its own RotationTransition, Opacity and
  // DecoratedBox into the tree, so every probe is scoped to the button.
  final turning = find.descendant(
      of: find.byType(IconButton), matching: find.byType(RotationTransition));
  final dimmed = find.descendant(
      of: find.byType(IconButton), matching: find.byType(Opacity));
  final marked = find.descendant(
      of: find.byType(IconButton), matching: find.byType(DecoratedBox));
  final spinner = find.descendant(
      of: find.byType(IconButton),
      matching: find.byType(CircularProgressIndicator));

  testWidgets('while syncing the icon stays in the tree and turns',
      (tester) async {
    final h = build();
    gate = Completer<void>();
    await mount(tester, trigger: h.trigger);

    await tapSync(tester);
    expect(h.sync.drains, 1, reason: 'a sync started');

    expect(find.byIcon(Icons.cloud_sync), findsOneWidget,
        reason: 'the icon is never removed from the tree');
    expect(turning, findsOneWidget,
        reason: 'and it turns rather than being swapped out');
    expect(spinner, findsNothing,
        reason: 'nothing replaces it');

    gate!.complete();
    gate = null;
    await settle(tester);
    await unmount(tester);
    h.trigger.dispose();
  });

  testWidgets('when the sync ends the icon stops turning and is idle again',
      (tester) async {
    final h = build();
    await mount(tester, trigger: h.trigger);

    await tapSync(tester);
    expect(turning, findsOneWidget);

    await spinOut(tester);

    expect(find.byIcon(Icons.cloud_sync), findsOneWidget,
        reason: 'still there, at rest');
    expect(turning, findsNothing,
        reason: 'the rotation has stopped');
    expect(dimmed, findsNothing,
        reason: 'and the idle icon is not dimmed');
    // Any controller left running fails the test outright: the framework
    // reports an active Ticker.
    await unmount(tester);
    h.trigger.dispose();
  });

  testWidgets('a sync that finishes at once still turns for the minimum',
      (tester) async {
    // No gate: drain and pull both land on the first microtask, so the
    // whole sync is over before the next frame.
    final h = build();
    await mount(tester, trigger: h.trigger);

    await tapSync(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.cloud_sync), findsOneWidget);
    expect(turning, findsOneWidget,
        reason: 'a sync that took no time at all must still be seen to '
            'happen');

    await spinOut(tester);
    expect(turning, findsNothing);
    expect(find.byIcon(Icons.cloud_sync), findsOneWidget,
        reason: 'and it still comes to rest rather than spinning forever');

    await unmount(tester);
    h.trigger.dispose();
  });

  testWidgets('tapping while busy starts no second sync', (tester) async {
    final h = build();
    gate = Completer<void>();
    await mount(tester, trigger: h.trigger);

    await tapSync(tester);
    expect(h.sync.drains, 1);

    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(h.sync.drains, 1, reason: 'the second tap was ignored');
    expect(h.pull.pulls, 0, reason: 'and nothing extra was pulled');

    gate!.complete();
    gate = null;
    await settle(tester);
    await unmount(tester);
    h.trigger.dispose();
  });

  testWidgets('a busy that goes off and on again neither crashes nor stacks',
      (tester) async {
    final h = build();
    await mount(tester, trigger: h.trigger);

    await tapSync(tester);
    await spinOut(tester);
    expect(turning, findsNothing,
        reason: 'the first sync has come to rest');

    await tapSync(tester);
    expect(turning, findsOneWidget,
        reason: 'the second sync turns again');
    expect(find.byIcon(Icons.cloud_sync), findsOneWidget);

    await spinOut(tester);
    expect(turning, findsNothing,
        reason: 'and comes to rest once, not once per sync');
    expect(find.byIcon(Icons.cloud_sync), findsOneWidget);

    await unmount(tester);
    h.trigger.dispose();
  });

  testWidgets('a sync still running when the button goes away disposes its '
      'ticker', (tester) async {
    final h = build();
    gate = Completer<void>();
    await mount(tester, trigger: h.trigger);

    await tapSync(tester);
    expect(turning, findsOneWidget,
        reason: 'caught mid-turn');

    // Unmounted without the sync ever finishing. SingleTickerProviderStateMixin
    // throws in dispose() if the controller was not disposed, so this is the
    // whole assertion.
    await unmount(tester);

    gate!.complete();
    gate = null;
    h.trigger.dispose();
  });

  testWidgets('with animations off there is no rotation, only a still busy '
      'state', (tester) async {
    final h = build();
    gate = Completer<void>();
    await mount(tester, trigger: h.trigger, disableAnimations: true);

    await tapSync(tester);

    expect(find.byIcon(Icons.cloud_sync), findsOneWidget,
        reason: 'the icon is still shown');
    expect(turning, findsNothing,
        reason: 'but it does not turn');
    expect(spinner, findsNothing);
    expect(dimmed, findsOneWidget,
        reason: 'the busy state is a plainly dimmed icon instead');
    expect(marked, findsNWidgets(2),
        reason: 'with a static marker, so busy is still legible');

    gate!.complete();
    gate = null;
    await settle(tester);
    await unmount(tester);
    h.trigger.dispose();
  });

  testWidgets('the busy icon is the idle icon colour, not the disabled tint',
      (tester) async {
    final h = build();
    gate = Completer<void>();
    await mount(tester, trigger: h.trigger);

    final idle = tester.widget<Icon>(find.byIcon(Icons.cloud_sync));

    await tapSync(tester);
    final busy = tester.widget<Icon>(find.byIcon(Icons.cloud_sync));

    expect(busy.color, idle.color,
        reason: 'working and resting must wear the same cream');
    expect(busy.color, AppColors.card,
        reason: 'which is the AppBar foreground, not a theme fallback');
    expect(busy.color, isNot(AppColors.card.withValues(alpha: 0.5)),
        reason: 'and not the faded disabled tint the old spinner sat in');

    gate!.complete();
    gate = null;
    await settle(tester);
    await unmount(tester);
    h.trigger.dispose();
  });

  testWidgets('the tap target is the same size in both states',
      (tester) async {
    final h = build();
    gate = Completer<void>();
    await mount(tester, trigger: h.trigger);

    final idleBox = tester.getSize(find.byType(IconButton));

    await tapSync(tester);
    final busyBox = tester.getSize(find.byType(IconButton));

    expect(busyBox, idleBox, reason: 'nothing jumps in the AppBar');
    expect(busyBox.width, greaterThanOrEqualTo(48));
    expect(busyBox.height, greaterThanOrEqualTo(48));

    gate!.complete();
    gate = null;
    await settle(tester);
    await unmount(tester);
    h.trigger.dispose();
  });

  testWidgets('a busy sync is announced, and the tooltip is kept',
      (tester) async {
    final h = build();
    gate = Completer<void>();
    final semantics = tester.ensureSemantics();
    // Disposed here rather than in addTearDown: the framework verifies
    // handles are gone before teardown callbacks run, so a handle left to
    // tearDown still fails the test.
    try {
      await mount(tester, trigger: h.trigger);

      expect(find.byTooltip('Sync now'), findsOneWidget);

      await tapSync(tester);
      expect(find.bySemanticsLabel('Syncing'), findsOneWidget,
          reason: 'a screen reader is told the same thing the eye is');
      expect(find.byTooltip('Sync now'), findsOneWidget,
          reason: 'the tooltip survives');
    } finally {
      semantics.dispose();
      gate?.complete();
      gate = null;
      await settle(tester);
      await unmount(tester);
      h.trigger.dispose();
    }
  });
}

/// A pull that can be held open by the test.
class _ScriptedPull extends PullService {
  _ScriptedPull()
      : super(
          batches: _FakeBatchDomain(),
          expenses: _FakeExpenseDomain(),
          mortality: _FakeMortalityDomain(),
          feed: _FakeFeedDomain(),
          weight: _FakeWeightDomain(),
          vaccination: _FakeVaccinationDomain(),
          harvest: _FakeHarvestDomain(),
          sales: _FakeSaleDomain(),
        );

  Completer<void>? Function()? gate;

  int pulls = 0;

  @override
  Future<PullResult> pullAll() async {
    pulls++;
    final pending = gate?.call();
    if (pending != null) await pending.future;
    return const PullResult(perTable: {'batches': 0}, errors: []);
  }
}

/// A drain that can be held open by the test.
class _ScriptedSync extends Fake implements SyncService {
  Completer<void>? Function()? gate;

  int drains = 0;

  @override
  Future<SyncResult> drain() async {
    drains++;
    final pending = gate?.call();
    if (pending != null) await pending.future;
    return const SyncResult();
  }
}

/// The connectivity plugin, stubbed so a trigger never touches the real one
/// and leaves timers behind.
class _FakeConnectivity extends Fake implements Connectivity {
  @override
  Stream<List<ConnectivityResult>> onConnectivityChanged = Stream.empty();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      const [ConnectivityResult.wifi];
}

class _FakeBatchDomain extends Fake implements BatchDomain {}

class _FakeExpenseDomain extends Fake implements ExpenseDomain {}

class _FakeMortalityDomain extends Fake implements MortalityDomain {}

class _FakeFeedDomain extends Fake implements FeedDomain {}

class _FakeWeightDomain extends Fake implements WeightDomain {}

class _FakeVaccinationDomain extends Fake implements VaccinationDomain {}

class _FakeHarvestDomain extends Fake implements HarvestDomain {}

class _FakeSaleDomain extends Fake implements SaleDomain {}
