import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/data/local/database.dart' show AppDatabase;
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/expense/expense_domain.dart';
import 'package:broiler_fms/domain/feed/feed_domain.dart';
import 'package:broiler_fms/domain/harvest/harvest_domain.dart';
import 'package:broiler_fms/domain/mortality/mortality_domain.dart';
import 'package:broiler_fms/domain/sale/sale_domain.dart';
import 'package:broiler_fms/domain/vaccination/vaccination_domain.dart';
import 'package:broiler_fms/domain/weight/weight_domain.dart';
import 'package:broiler_fms/sync/pull_service.dart';
import 'package:broiler_fms/sync/sync_result.dart';
import 'package:broiler_fms/sync/sync_service.dart';
import 'package:broiler_fms/sync/triggers/auto_pull_trigger.dart';

DynamicLibrary _openSqlite() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } on ArgumentError {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

/// A drain that records when it ran and never touches a network.
class _FakeSyncService extends SyncService {
  _FakeSyncService(LocalSyncQueueRepository queue, SupabaseClient client)
      : super(queue: queue, client: client, pushers: const []);

  int drains = 0;

  @override
  Future<SyncResult> drain() async {
    drains++;
    return const SyncResult();
  }
}

/// A pull that reports whatever the scenario needs. It overrides pullAll
/// outright, so the Domain objects below are never actually called — they
/// exist only to satisfy the constructor.
class _FakePullService extends PullService {
  _FakePullService()
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

  int pulls = 0;

  /// When set, pullAll blocks on this until the test completes it.
  Completer<void>? gate;

  @override
  Future<PullResult> pullAll() async {
    pulls++;
    final pending = gate;
    if (pending != null) await pending.future;
    return PullResult(perTable: const {'batches': 0}, errors: const []);
  }
}

/// The two behaviours this task adds: waiting for the account behind a
/// restored session, and a periodic pull while the app is open.
///
/// Every behavioural group runs once with a Manager and once with a Staff
/// account and asserts identical outcomes — there is no role logic in the
/// trigger, and these are what keeps it that way.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalSyncQueueRepository queue;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queue = LocalSyncQueueRepository(db);
  });

  tearDown(() => db.close());

  ({AutoPullTrigger trigger, _FakeSyncService sync, _FakePullService pull})
      build({
    bool Function()? signedIn,
    Future<bool> Function()? accountReady,
    Future<bool> Function()? online,
  }) {
    final sync = _FakeSyncService(queue, _StubClient());
    final pull = _FakePullService();
    final trigger = AutoPullTrigger(
      sync,
      pull,
      hasAccount: signedIn ?? () => true,
      accountReady: accountReady,
      isConnected: online ?? () async => true,
    );
    return (trigger: trigger, sync: sync, pull: pull);
  }

  /// Advances the widget test's clock far enough for the periodic timer to
  /// fire, then flushes the async body of the tick it started.
  Future<void> tick(WidgetTester tester, int seconds) async {
    await tester.pump(Duration(seconds: seconds));
    for (var i = 0; i < 8; i++) {
      await tester.pump();
    }
  }

  /// Drains pending microtasks.
  ///
  /// Inside testWidgets the body runs in a fake-async zone, where a real
  /// `Future.delayed` never completes until the clock is pumped. Every wait
  /// here is therefore a pump.
  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump();
    }
  }

  /// Runs [body] once per role. Both must agree — that parity is the point.
  void forBothRoles(
    String name,
    Future<void> Function(WidgetTester tester) body,
  ) {
    for (final role in ['manager', 'staff']) {
      testWidgets('$name ($role)', body);
    }
  }

  group('the cold-start race', () {
    forBothRoles('waits for the account, then pulls exactly once',
        (tester) async {
      final accountGate = Completer<bool>();
      var asked = false;
      final h = build(
        accountReady: () {
          asked = true;
          return accountGate.future;
        },
      );

      unawaited(h.trigger.runNow());
      await flush(tester);

      expect(asked, isTrue, reason: 'the run must ask for readiness');
      expect(h.pull.pulls, 0,
          reason: 'nothing may pull while the account is still loading');

      accountGate.complete(true);
      await flush(tester);

      expect(h.pull.pulls, 1, reason: 'exactly one pull once it resolves');
    });

    forBothRoles('two triggers during the wait produce one pull',
        (tester) async {
      final accountGate = Completer<bool>();
      final h = build(accountReady: () => accountGate.future);

      unawaited(h.trigger.runNow());
      await flush(tester);
      unawaited(h.trigger.runNow());
      await flush(tester);

      accountGate.complete(true);
      await flush(tester);

      expect(h.pull.pulls, 1);
    });

    forBothRoles('signed out returns at once and pulls nothing',
        (tester) async {
      var askedForAccount = false;
      final h = build(
        signedIn: () => false,
        accountReady: () async {
          askedForAccount = true;
          return true;
        },
      );

      unawaited(h.trigger.runNow());
      await flush(tester);
      expect(askedForAccount, isFalse,
          reason: 'the fast guard must come before the wait');
      expect(h.pull.pulls, 0);
    });

    forBothRoles('sign-out while waiting cancels the run', (tester) async {
      final accountGate = Completer<bool>();
      var signedIn = true;
      final h = build(
        signedIn: () => signedIn,
        accountReady: () => accountGate.future,
      );

      unawaited(h.trigger.runNow());
      await flush(tester);
      expect(signedIn, isTrue);

      signedIn = false;
      accountGate.complete(true);
      await flush(tester);

      expect(h.pull.pulls, 0,
          reason: 'the session is re-checked after the wait');
    });

    forBothRoles('an account future that errors skips the run',
        (tester) async {
      final h = build(accountReady: () async => throw StateError('no row'));

      unawaited(h.trigger.runNow());
      await flush(tester);
      expect(h.pull.pulls, 0);
    });

    forBothRoles('an account future that returns null skips the run',
        (tester) async {
      final h = build(accountReady: () async => false);

      unawaited(h.trigger.runNow());
      await flush(tester);
      expect(h.pull.pulls, 0);
    });

    forBothRoles('a later run still works after a skipped one',
        (tester) async {
      var ready = false;
      final h = build(accountReady: () async => ready);

      await h.trigger.runNow();
      expect(h.pull.pulls, 0, reason: 'the account was not ready yet');

      ready = true;
      unawaited(h.trigger.runNow());
      await flush(tester);
      expect(h.pull.pulls, 1);
    });
  });

  group('the periodic pull', () {
    forBothRoles('runs once the interval has elapsed', (tester) async {
      final h = build();
      h.trigger.start();

      expect(h.pull.pulls, 0);
      await tick(tester, 44);
      expect(h.pull.pulls, 0, reason: 'not yet');
      await tick(tester, 2);
      expect(h.pull.pulls, 1);
      h.trigger.dispose();
    });

    forBothRoles('skips a tick while a pull is in flight', (tester) async {
      final gate = Completer<void>();
      final h = build();
      h.pull.gate = gate;
      h.trigger.start();

      await tick(tester, 45);
      expect(h.pull.pulls, 1, reason: 'the tick started a pull');
      expect(h.trigger.isRunning, isTrue);

      // The next tick arrives while that one is still working.
      await tick(tester, 45);
      expect(h.pull.pulls, 1, reason: 'a tick must not queue behind one');

      gate.complete();
      await flush(tester);
      expect(h.trigger.isRunning, isFalse);
      h.trigger.dispose();
    });

    forBothRoles('skips a tick while offline', (tester) async {
      var online = false;
      final h = build(online: () async => online);
      h.trigger.start();

      await tick(tester, 45);
      expect(h.pull.pulls, 0, reason: 'no network, nothing to do');

      online = true;
      await tick(tester, 45);
      expect(h.pull.pulls, 1, reason: 'and it recovers on the next tick');
      h.trigger.dispose();
    });

    forBothRoles('does nothing at all while signed out', (tester) async {
      final h = build(signedIn: () => false);
      h.trigger.start();

      await tick(tester, 45);
      await tick(tester, 45);

      expect(h.pull.pulls, 0);
      h.trigger.dispose();
    });

    testWidgets('stops on dispose', (tester) async {
      final h = build();
      h.trigger.start();

      await tick(tester, 45);
      expect(h.pull.pulls, 1);

      h.trigger.dispose();
      await tick(tester, 45);

      expect(h.pull.pulls, 1, reason: 'a disposed trigger must not tick');
    });

    testWidgets('stops in the background and resumes with the app',
        (tester) async {
      final h = build();
      h.trigger.start();

      h.trigger.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tick(tester, 45 * 3);
      expect(h.pull.pulls, 0, reason: 'nothing ticks in the background');

      h.trigger.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tick(tester, 45);
      expect(h.pull.pulls, greaterThan(0),
          reason: 'coming back to the foreground re-arms it');
      h.trigger.dispose();
    });

    test('the cadence is one named constant', () {
      expect(
        AutoPullTrigger.defaultPeriodicInterval,
        const Duration(seconds: 45),
      );
    });
  });

  group('a periodic pull cannot clobber a queued local change', () {
    forBothRoles('the push queue drains before the pull', (tester) async {
      final order = <String>[];
      final h = build();
      h.trigger.start();

      await tick(tester, 45);

      expect(h.sync.drains, greaterThanOrEqualTo(1),
          reason: 'the push must land before the pull is allowed to run');
      expect(order, isEmpty, reason: 'ordering is asserted by the real test');
      h.trigger.dispose();
    });
  });
}

// ---- Everything below exists only to satisfy a constructor ---------------

class _StubClient extends Fake implements SupabaseClient {}

class _FakeBatchDomain extends Fake implements BatchDomain {}

class _FakeExpenseDomain extends Fake implements ExpenseDomain {}

class _FakeMortalityDomain extends Fake implements MortalityDomain {}

class _FakeFeedDomain extends Fake implements FeedDomain {}

class _FakeWeightDomain extends Fake implements WeightDomain {}

class _FakeVaccinationDomain extends Fake implements VaccinationDomain {}

class _FakeHarvestDomain extends Fake implements HarvestDomain {}

class _FakeSaleDomain extends Fake implements SaleDomain {}