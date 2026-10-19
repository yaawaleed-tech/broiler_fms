import 'dart:async';
import 'dart:ffi';
import 'dart:io';

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

/// Pull-to-refresh on the batch list.
///
/// The indicator sits above the one ListView both roles render, so a
/// Manager and a Staff member must behave identically. Every test runs
/// twice, once per role, and asserts the same thing both times.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }
  TestWidgetsFlutterBinding.ensureInitialized();

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
  });

  tearDown(() => db.close());

  Future<void> putBatch(
    String id, {
    String? assignedStaffId,
    bool closed = false,
  }) async {
    await db.into(db.batches).insert(
          BatchesCompanion.insert(
            batchId: id,
            businessId: 'biz-1',
            assignedStaffId: Value(assignedStaffId),
            batchName: 'House $id',
            startingBirdCount: 100,
            startDate: DateTime(2026, 1, 1),
            isClosed: Value(closed),
            createdAt: Value(DateTime(2026, 1, 1)),
            closedAt: const Value(null),
          ),
        );
  }

  Account account(String role) => Account(
        accountId: 'acc-1',
        businessId: 'biz-1',
        role: role,
        name: 'Mia',
        email: 'mia@example.com',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
      );

  ({AutoPullTrigger trigger, _CountingPull pull, _CountingSync sync}) harness() {
    final sync = _CountingSync();
    final pull = _CountingPull();
    final trigger = AutoPullTrigger(
      sync,
      pull,
      hasAccount: () => true,
      isConnected: () async => true,
    );
    return (trigger: trigger, pull: pull, sync: sync);
  }

  /// Bounded rather than pumpAndSettle: any spinner left running would
  /// otherwise hang the test instead of failing it.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
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
          // watch; while either is pending it spins forever, and
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

  /// Tears the tree down and lets Drift's own cancel-timer finish, which
  /// otherwise leaves a pending timer and fails the test on an assertion
  /// that has nothing to do with the thing under test.
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

  const noInternet =
      'No internet connection. Check your network and try again.';

  /// Runs [body] once per role, over the same data, so the two can be
  /// compared directly.
  void forBothRoles(
    String name,
    Future<void> Function(WidgetTester tester, String role) body,
  ) {
    for (final role in ['manager', 'staff']) {
      testWidgets('$name ($role)', (tester) async {
        // One batch the signed-in account can see either way: Manager sees
        // every batch in the business, Staff sees the ones assigned to it.
        await putBatch('b1', assignedStaffId: 'acc-1');
        await body(tester, role);
      });
    }
  }

  forBothRoles('the list carries a refresh indicator', (tester, role) async {
    final h = harness();
    await mount(tester, role: role, trigger: h.trigger);

    expect(find.byType(RefreshIndicator), findsOneWidget);
    await unmount(tester);
    h.trigger.dispose();
  });

  forBothRoles('dragging runs a pull and the indicator finishes',
      (tester, role) async {
    final h = harness();
    await mount(tester, role: role, trigger: h.trigger);

    await dragToRefresh(tester);

    expect(h.pull.pulls, 1, reason: 'a pull ran');
    expect(h.sync.drains, 1,
        reason: 'the push queue drains first, exactly as every other pass');
    expect(find.byType(RefreshIndicator), findsOneWidget);
    await unmount(tester);
    h.trigger.dispose();
  });

  forBothRoles('a pull already running is joined, never doubled',
      (tester, role) async {
    final h = harness();
    h.pull.gate = Completer<void>();
    await mount(tester, role: role, trigger: h.trigger);

    unawaited(h.trigger.refreshNow());
    await tester.pump();
    expect(h.trigger.isRunning, isTrue);

    await dragToRefresh(tester);
    expect(h.pull.pulls, 1, reason: 'the second ask joins the first');

    h.pull.gate!.complete();
    await settle(tester);
    await unmount(tester);
    h.trigger.dispose();
  });

  forBothRoles('a failed pull shows the no-internet snackbar',
      (tester, role) async {
    final h = harness();
    h.pull.failEverything = true;
    await mount(tester, role: role, trigger: h.trigger);

    await dragToRefresh(tester);

    expect(find.text(noInternet), findsOneWidget);
    await unmount(tester);
    h.trigger.dispose();
  });

  forBothRoles('a successful pull shows no snackbar', (tester, role) async {
    final h = harness();
    await mount(tester, role: role, trigger: h.trigger);

    await dragToRefresh(tester);

    expect(find.text(noInternet), findsNothing);
    await unmount(tester);
    h.trigger.dispose();
  });

  forBothRoles('the indicator still works on an empty list',
      (tester, role) async {
    await db.delete(db.batches).go();
    final h = harness();
    await mount(tester, role: role, trigger: h.trigger);

    expect(find.text('No batches yet.'), findsOneWidget);

    await dragToRefresh(tester);
    expect(h.pull.pulls, 1,
        reason: 'AlwaysScrollable keeps even an empty list draggable');
    await unmount(tester);
    h.trigger.dispose();
  });
}

/// A pull that records its calls and can be told to fail or to block.
class _CountingPull extends PullService {
  _CountingPull()
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
  bool failEverything = false;

  @override
  Future<PullResult> pullAll() async {
    pulls++;
    final pending = gate;
    if (pending != null) await pending.future;
    if (failEverything) {
      return const PullResult(
        perTable: {},
        errors: ['batches: offline', 'expenses: offline'],
      );
    }
    return PullResult(perTable: const {'batches': 0}, errors: const []);
  }
}

/// Counts drains without a queue or a network.
class _CountingSync extends Fake implements SyncService {
  int drains = 0;

  @override
  Future<SyncResult> drain() async {
    drains++;
    return const SyncResult();
  }
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
  /// CircularProgressIndicator that never stops, and pumpAndSettle would
  /// then wait forever.
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