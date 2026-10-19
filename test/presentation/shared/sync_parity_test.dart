import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' show ClientException;
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;

import 'package:broiler_fms/data/local/database.dart'
    show
        AccountsCompanion,
        AppDatabase,
        BatchesCompanion,
        BusinessesCompanion;
import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/expense/expense_domain.dart';
import 'package:broiler_fms/domain/feed/feed_domain.dart';
import 'package:broiler_fms/domain/harvest/harvest_domain.dart';
import 'package:broiler_fms/domain/mortality/mortality_domain.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/domain/sale/sale_domain.dart';
import 'package:broiler_fms/domain/vaccination/vaccination_domain.dart';
import 'package:broiler_fms/domain/weight/weight_domain.dart';
import 'package:broiler_fms/presentation/mobile/home/batch_list_screen.dart';
import 'package:broiler_fms/presentation/mobile/widgets/sync_now_button.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/sync/pull_service.dart';
import 'package:broiler_fms/sync/sync_providers.dart';
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

/// Pull-to-refresh and the Sync now button, as one action.
///
/// Both live on the batch list: the button is in the AppBar, the
/// indicator sits over the list below it. Every scenario here drives both
/// and asserts the person ends up reading the same sentence either way.
///
/// The bug these lock down: the two paths used to be separate. The button
/// said what actually happened; the drag turned every "did not run" into
/// "No internet connection", including the five runNow returns that have
/// nothing to do with the network — most often a periodic pull that was
/// already in flight, which is why it showed up next to a pill reading
/// "Online".
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }
  TestWidgetsFlutterBinding.ensureInitialized();

  const noInternet =
      'No internet connection. Check your network and try again.';
  const couldNotReachServer =
      "Couldn't reach the server. We'll sync when you're back online.";
  const accountNotReady =
      "Your account isn't ready yet. Try again in a moment.";

  late AppDatabase db;
  late LocalBatchRepository batches;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    batches = LocalBatchRepository(db);
    await db.into(db.businesses).insert(
          BusinessesCompanion.insert(businessId: 'biz-1', name: 'Sunny Farm'),
        );
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            accountId: 'acc-1',
            businessId: const Value('biz-1'),
            role: 'manager',
            name: 'Mia',
            email: 'mia@example.com',
          ),
        );
    await db.into(db.batches).insert(
          BatchesCompanion.insert(
            batchId: 'b1',
            businessId: 'biz-1',
            assignedStaffId: const Value('acc-1'),
            batchName: 'House b1',
            startingBirdCount: 100,
            startDate: DateTime(2026, 1, 1),
            isClosed: const Value(false),
            createdAt: Value(DateTime(2026, 1, 1)),
            closedAt: const Value(null),
          ),
        );
  });

  tearDown(() => db.close());

  Account account(String role) => Account(
        accountId: 'acc-1',
        businessId: 'biz-1',
        role: role,
        name: 'Mia',
        email: 'mia@example.com',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
      );

  /// Every run here needs its own connectivity source, because a trigger
  /// that is [AutoPullTrigger.start]ed subscribes to the real plugin and
  /// that leaves timers the test framework then complains about.
  _FakeConnectivity connectivity() => _FakeConnectivity();

  ({AutoPullTrigger trigger, _ScriptedPull pull, _ScriptedSync sync}) build({
    bool signedIn = true,
    Future<bool> Function()? accountReady,
    Future<bool> Function()? isConnected,
    Connectivity? rawConnectivity,
  }) {
    final sync = _ScriptedSync();
    final pull = _ScriptedPull();
    final trigger = AutoPullTrigger(
      sync,
      pull,
      hasAccount: () => signedIn,
      accountReady: accountReady,
      isConnected: isConnected ?? () async => true,
      connectivity: rawConnectivity ?? connectivity(),
    );
    return (trigger: trigger, pull: pull, sync: sync);
  }

  /// Bounded rather than pumpAndSettle: a spinner left running would hang
  /// the test instead of failing it.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> mount(
    WidgetTester tester, {
    required String role,
    required AutoPullTrigger trigger,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          autoPullTriggerProvider.overrideWithValue(trigger),
          currentAccountProvider.overrideWith((ref) async => account(role)),
          batchDomainProvider
              .overrideWith((ref) => _StubBatchDomain(batches)),
          // The real pill combines a connectivity stream and a Drift
          // watch; while either is pending it spins forever and
          // pumpAndSettle would never return.
          syncStatusProvider.overrideWith(
            (ref) => Stream<SyncStatus>.value(
              const SyncStatus(isOnline: true, pendingCount: 0),
            ),
          ),
        ],
        child: const MaterialApp(home: BatchListScreen()),
      ),
    );
    await settle(tester);
  }

  /// Unmounts first, then lets Drift's own cancel-timer finish: it is
  /// scheduled when the batch stream is cancelled, and a pending timer
  /// fails the test on an assertion unrelated to anything under test.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  }

  Future<void> dragToRefresh(WidgetTester tester) async {
    await tester.fling(find.byType(ListView), const Offset(0, 320), 1000);
    await settle(tester);
  }

  Future<void> tapSyncButton(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(SyncNowButton),
        matching: find.byType(IconButton),
      ),
    );
    await settle(tester);
  }

  /// The text currently on the newest snackbar, or null if there is none.
  String? snackbarText(WidgetTester tester) {
    final bars = tester.widgetList<SnackBar>(find.byType(SnackBar));
    if (bars.isEmpty) return null;
    final content = bars.last.content;
    return content is Text ? content.data : null;
  }

  /// Lets a snackbar time out and animate away, so the next capture is
  /// unambiguous.
  Future<void> clearSnackbars(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
  }

  /// Drives both paths in turn and asserts they say the same thing.
  Future<void> expectBothPathsSay(
    WidgetTester tester, {
    required String role,
    required void Function(_ScriptedPull pull, _ScriptedSync sync) script,
    required Object? expected,
    Future<bool> Function()? accountReady,
  }) async {
    final h = build(accountReady: accountReady);
    script(h.pull, h.sync);
    await mount(tester, role: role, trigger: h.trigger);

    await dragToRefresh(tester);
    final fromPull = snackbarText(tester);

    await clearSnackbars(tester);
    await tapSyncButton(tester);
    final fromButton = snackbarText(tester);

    expect(fromPull, expected, reason: 'pull-to-refresh');
    expect(fromButton, expected, reason: 'the Sync now button');
    expect(fromPull, fromButton,
        reason: 'the two paths must not drift apart again');

    await unmount(tester);
    h.trigger.dispose();
  }

  void forBothRoles(
    String name,
    Future<void> Function(WidgetTester tester, String role) body,
  ) {
    for (final role in ['manager', 'staff']) {
      testWidgets('$name ($role)', (tester) async => body(tester, role));
    }
  }

  group('both paths say the same thing', () {
    forBothRoles('nothing changed', (tester, role) async {
      await expectBothPathsSay(
        tester,
        role: role,
        script: (pull, sync) {},
        expected: 'Already up to date.',
      );
    });

    forBothRoles('rows went up and came down', (tester, role) async {
      await expectBothPathsSay(
        tester,
        role: role,
        script: (pull, sync) {
          sync.behaviour = () async => const SyncResult(pushed: 2);
          pull.behaviour =
              () async => const PullResult(perTable: {'batches': 3}, errors: []);
        },
        expected: '2 entries sent, 3 changes received',
      );
    });

    forBothRoles('some tables could not be refreshed', (tester, role) async {
      await expectBothPathsSay(
        tester,
        role: role,
        script: (pull, sync) {
          pull.behaviour = () async => const PullResult(
            perTable: {'batches': 1},
            errors: ['sales: permission denied'],
          );
        },
        expected: "1 of 2 data tables couldn't be refreshed "
            'from the server.',
      );
    });

    forBothRoles('every table failed', (tester, role) async {
      await expectBothPathsSay(
        tester,
        role: role,
        script: (pull, sync) {
          pull.behaviour = () async => const PullResult(
            perTable: {},
            errors: ['batches: x', 'sales: y'],
          );
        },
        expected: couldNotReachServer,
      );
    });

    forBothRoles('the server rejected a row', (tester, role) async {
      await expectBothPathsSay(
        tester,
        role: role,
        script: (pull, sync) {
          sync.behaviour =
              () async => const SyncResult(pushed: 4, rejected: 1);
        },
        expected: '1 entry was rejected by the server and will never '
            'upload. Open the batch to check its counts.',
      );
    });
  });

  group('nothing that is not a network failure may claim the network',
      () {
    forBothRoles('a pull already in flight', (tester, role) async {
      // The reported bug. A periodic or reconnect-triggered pull is going
      // when the person drags down; the old code joined it, got a null,
      // and blamed the network while the pill beside it said "Online".
      final h = build();
      h.pull.gate = Completer<void>();
      await mount(tester, role: role, trigger: h.trigger);

      unawaited(h.trigger.syncNow());
      await tester.pump();
      expect(h.trigger.isRunning, isTrue);

      await dragToRefresh(tester);
      expect(h.pull.pulls, 1, reason: 'the drag joined, not doubled');

      h.pull.gate!.complete();
      await settle(tester);

      expect(snackbarText(tester), isNot(equals(noInternet)),
          reason: 'a joined run is not evidence about the network');
      expect(h.pull.pulls, 1);

      await unmount(tester);
      h.trigger.dispose();
    });

    forBothRoles('a pull in flight reports the result it produced',
        (tester, role) async {
      final h = build();
      h.pull.gate = Completer<void>();
      h.pull.behaviour =
          () async => const PullResult(perTable: {'batches': 0}, errors: []);
      await mount(tester, role: role, trigger: h.trigger);

      unawaited(h.trigger.syncNow());
      await tester.pump();

      await dragToRefresh(tester);
      h.pull.gate!.complete();
      await settle(tester);

      // The button's own wording for a completed run, not a guess.
      expect(snackbarText(tester), 'Already up to date.');
      await unmount(tester);
      h.trigger.dispose();
    });

    forBothRoles('an account that is not ready yet', (tester, role) async {
      // The 12-second wait in sync_providers returns false on timeout;
      // this is the same shape.
      await expectBothPathsSay(
        tester,
        role: role,
        script: (pull, sync) {},
        accountReady: () async => false,
        expected: accountNotReady,
      );
    });
  });

  testWidgets('an unreadable account says so, never no-internet',
      (tester) async {
    // The 12-second wait landing in sync_providers returns false; this is
    // the same shape.
    final h = build(accountReady: () async => false);
    await mount(tester, role: 'manager', trigger: h.trigger);

    await dragToRefresh(tester);
    expect(snackbarText(tester), accountNotReady);
    expect(snackbarText(tester), isNot(equals(noInternet)));

    await clearSnackbars(tester);
    await tapSyncButton(tester);
    expect(snackbarText(tester), accountNotReady);
    expect(snackbarText(tester), isNot(equals(noInternet)));

    await unmount(tester);
    h.trigger.dispose();
  });

  testWidgets('nobody signed in says nothing at all', (tester) async {
    final h = build(signedIn: false);
    await mount(tester, role: 'manager', trigger: h.trigger);

    await dragToRefresh(tester);
    expect(snackbarText(tester), isNull);

    await tapSyncButton(tester);
    expect(snackbarText(tester), isNull);

    await unmount(tester);
    h.trigger.dispose();
  });

  group('a genuine network failure does say so', () {
    forBothRoles('a socket that never opened', (tester, role) async {
      await expectBothPathsSay(
        tester,
        role: role,
        script: (pull, sync) {
          sync.behaviour = () async =>
              throw const SocketException('Connection refused');
        },
        expected: noInternet,
      );
    });

    forBothRoles('an http client that gave up', (tester, role) async {
      await expectBothPathsSay(
        tester,
        role: role,
        script: (pull, sync) {
          sync.behaviour =
              () async => throw ClientException('Connection closed');
        },
        expected: noInternet,
      );
    });

    forBothRoles('a request that timed out', (tester, role) async {
      await expectBothPathsSay(
        tester,
        role: role,
        script: (pull, sync) {
          sync.behaviour = () async =>
              throw TimeoutException('timed out', const Duration(seconds: 1));
        },
        expected: noInternet,
      );
    });

    forBothRoles('a failure that is not the network keeps its own words',
        (tester, role) async {
      await expectBothPathsSay(
        tester,
        role: role,
        script: (pull, sync) {
          sync.behaviour =
              () async => throw StateError('the queue table is gone');
        },
        expected: 'Sync failed: Bad state: the queue table is gone',
      );
    });
  });

  testWidgets(
      'connectivity reports none but the request succeeds, so the sync '
      'succeeds', (tester) async {
    // The exact false-offline case, and the one a connectivity gate would
    // have refused. connectivity_plus reports radio status, not whether a
    // request will get through — its own API docs say so — so a manual
    // sync never consults it.
    final h = build(isConnected: () async => false);
    await mount(tester, role: 'manager', trigger: h.trigger);

    await dragToRefresh(tester);
    expect(h.pull.pulls, 1, reason: 'the request was attempted');
    expect(snackbarText(tester), 'Already up to date.',
        reason: 'the outcome, not the radio, is what gets reported');
    expect(snackbarText(tester), isNot(equals(noInternet)));

    await clearSnackbars(tester);
    await tapSyncButton(tester);
    expect(snackbarText(tester), 'Already up to date.');

    await unmount(tester);
    h.trigger.dispose();
  });

  group('single flight', () {
    forBothRoles('a drag during a run starts no second run',
        (tester, role) async {
      final h = build();
      h.pull.gate = Completer<void>();
      await mount(tester, role: role, trigger: h.trigger);

      await tapSyncButton(tester);
      expect(h.trigger.isRunning, isTrue, reason: 'the button is running');

      await dragToRefresh(tester);
      expect(h.pull.pulls, 1, reason: 'the drag joined the button');

      h.pull.gate!.complete();
      await settle(tester);
      expect(h.pull.pulls, 1);
      expect(h.sync.drains, 1);

      await unmount(tester);
      h.trigger.dispose();
    });

    forBothRoles('a button press during a drag starts no second run',
        (tester, role) async {
      final h = build();
      h.pull.gate = Completer<void>();
      await mount(tester, role: role, trigger: h.trigger);

      unawaited(h.trigger.syncNow());
      await tester.pump();

      await tapSyncButton(tester);
      expect(h.pull.pulls, 1);

      h.pull.gate!.complete();
      await settle(tester);
      expect(h.pull.pulls, 1);
      expect(h.sync.drains, 1);

      await unmount(tester);
      h.trigger.dispose();
    });
  });

  group('automatic runs stay silent', () {
    forBothRoles('an automatic run shows no snackbar', (tester, role) async {
      final h = build();
      await mount(tester, role: role, trigger: h.trigger);

      await h.trigger.runNow();
      await settle(tester);

      expect(h.pull.pulls, 1, reason: 'it ran');
      expect(snackbarText(tester), isNull,
          reason: 'nobody asked, so nobody is told');

      await unmount(tester);
      h.trigger.dispose();
    });

    forBothRoles('an app start shows no snackbar', (tester, role) async {
      final h = build();
      await mount(tester, role: role, trigger: h.trigger);

      h.trigger.onAppStart();
      await settle(tester);

      expect(h.pull.pulls, 1);
      expect(snackbarText(tester), isNull);

      await unmount(tester);
      h.trigger.dispose();
    });

    forBothRoles('a periodic pull shows no snackbar', (tester, role) async {
      final h = build(rawConnectivity: connectivity());
      h.trigger.start();
      await mount(tester, role: role, trigger: h.trigger);

      await tester.pump(AutoPullTrigger.defaultPeriodicInterval);
      await settle(tester);

      expect(h.pull.pulls, 1, reason: 'the tick ran');
      expect(snackbarText(tester), isNull,
          reason: 'an automatic run has nobody to tell');

      await unmount(tester);
      h.trigger.dispose();
    });
  });

  testWidgets('the drain is awaited before the pull on both paths',
      (tester) async {
    // A pull landing while a push is still in flight could overwrite a
    // row that has not been sent yet, so the order matters as much as the
    // message.
    final h = build();
    h.sync.gate = Completer<void>();
    await mount(tester, role: 'manager', trigger: h.trigger);

    unawaited(h.trigger.syncNow());
    await tester.pump();
    expect(h.sync.drains, 1);
    expect(h.pull.pulls, 0, reason: 'nothing pulls until the drain lands');

    h.sync.gate!.complete();
    await settle(tester);
    expect(h.pull.pulls, 1);

    await unmount(tester);
    h.trigger.dispose();
  });
}

/// A pull that runs whatever it has been told to, and can be held open.
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

  int pulls = 0;
  Completer<void>? gate;

  Future<PullResult> Function() behaviour = () async =>
      const PullResult(perTable: {'batches': 0}, errors: []);

  @override
  Future<PullResult> pullAll() async {
    pulls++;
    final pending = gate;
    if (pending != null) await pending.future;
    return behaviour();
  }
}

/// A drain that runs whatever it has been told to, and can be held open.
class _ScriptedSync extends Fake implements SyncService {
  int drains = 0;
  Completer<void>? gate;

  Future<SyncResult> Function() behaviour =
      () async => const SyncResult();

  @override
  Future<SyncResult> drain() async {
    drains++;
    final pending = gate;
    if (pending != null) await pending.future;
    return behaviour();
  }
}

/// The connectivity plugin, stubbed so a started trigger never touches the
/// real one and leaves timers behind.
class _FakeConnectivity extends Fake implements Connectivity {
  @override
  Stream<List<ConnectivityResult>> onConnectivityChanged = Stream.empty();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      const [ConnectivityResult.wifi];
}

/// Answers the two list queries the batch list screen makes, and nothing
/// else — [Fake] covers the rest.
class _StubBatchDomain extends Fake implements BatchDomain {
  _StubBatchDomain(this._repo);

  final LocalBatchRepository _repo;

  @override
  Stream<List<Batch>> watchForStaff(String staffId) =>
      _repo.watchForStaff(staffId);

  @override
  Stream<List<Batch>> watchAllForBusiness(String businessId) =>
      _repo.watchAllForBusiness(businessId);

  /// Answered for real, because a card left waiting on this shows a
  /// CircularProgressIndicator that never stops.
  @override
  Future<int> getRemainingBirdCount(String batchId) async => 100;
}

class _FakeBatchDomain extends Fake implements BatchDomain {}

class _FakeExpenseDomain extends Fake implements ExpenseDomain {}

class _FakeMortalityDomain extends Fake implements MortalityDomain {}

class _FakeFeedDomain extends Fake implements FeedDomain {}

class _FakeWeightDomain extends Fake implements WeightDomain {}

class _FakeVaccinationDomain extends Fake implements VaccinationDomain {}

class _FakeHarvestDomain extends Fake implements HarvestDomain {}

class _FakeSaleDomain extends Fake implements SaleDomain {}
