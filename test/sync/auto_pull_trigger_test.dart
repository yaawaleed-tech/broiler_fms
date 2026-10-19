import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/data/local/database.dart'
    show AccountsCompanion, AppDatabase, BusinessesCompanion;
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/expense/expense_domain.dart';
import 'package:broiler_fms/domain/feed/feed_domain.dart';
import 'package:broiler_fms/domain/harvest/harvest_domain.dart';
import 'package:broiler_fms/domain/mortality/mortality_domain.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/domain/models/expense.dart';
import 'package:broiler_fms/domain/models/feed.dart';
import 'package:broiler_fms/domain/models/harvest.dart';
import 'package:broiler_fms/domain/models/mortality.dart';
import 'package:broiler_fms/domain/models/sale.dart';
import 'package:broiler_fms/domain/models/vaccination.dart';
import 'package:broiler_fms/domain/models/weight_sample.dart';
import 'package:broiler_fms/domain/sale/sale_domain.dart';
import 'package:broiler_fms/domain/vaccination/vaccination_domain.dart';
import 'package:broiler_fms/domain/weight/weight_domain.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/repository/batch/remote_batch_repository.dart';
import 'package:broiler_fms/repository/expense/local_expense_repository.dart';
import 'package:broiler_fms/repository/expense/remote_expense_repository.dart';
import 'package:broiler_fms/repository/feed/local_feed_repository.dart';
import 'package:broiler_fms/repository/feed/remote_feed_repository.dart';
import 'package:broiler_fms/repository/harvest/local_harvest_repository.dart';
import 'package:broiler_fms/repository/harvest/remote_harvest_repository.dart';
import 'package:broiler_fms/repository/mortality/local_mortality_repository.dart';
import 'package:broiler_fms/repository/mortality/remote_mortality_repository.dart';
import 'package:broiler_fms/repository/sale/local_sale_repository.dart';
import 'package:broiler_fms/repository/sale/remote_sale_repository.dart';
import 'package:broiler_fms/repository/vaccination/local_vaccination_repository.dart';
import 'package:broiler_fms/repository/vaccination/remote_vaccination_repository.dart';
import 'package:broiler_fms/repository/weight/local_weight_repository.dart';
import 'package:broiler_fms/repository/weight/remote_weight_repository.dart';
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

/// Stands in for the plugin's event stream, which no unit test can reach.
class _FakeConnectivity extends Fake implements Connectivity {
  final _changes = StreamController<List<ConnectivityResult>>.broadcast();

  /// What checkConnectivity() reports. Set to false to model a phone with
  /// no network, so the default (non-injected) gate can be exercised.
  bool connected = true;

  int checks = 0;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    checks++;
    return connected
        ? const [ConnectivityResult.wifi]
        : const [ConnectivityResult.none];
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _changes.stream;

  void emit(List<ConnectivityResult> results) => _changes.add(results);

  Future<void> close() => _changes.close();
}

/// A clock the test moves by hand, so the 60-second throttle can be checked
/// without waiting a minute for it.
class _Clock {
  DateTime value = DateTime(2026, 1, 1, 12);

  DateTime now() => value;

  void advance(Duration d) => value = value.add(d);
}

/// Records the order in which the trigger reached for things, which is how
/// the tests prove the push lands before the pull.
class _Journal {
  final List<String> entries = [];
  void add(String what) => entries.add(what);
  void clear() => entries.clear();
}

/// SyncService whose drain is counted rather than performed, so a test can
/// assert ordering without a queue behind it.
class _FakeSyncService extends SyncService {
  _FakeSyncService({
    required super.queue,
    required super.client,
    required super.pushers,
    required this.journal,
    this.delay = Duration.zero,
    this.throwOnDrain,
  });

  final _Journal journal;
  final Duration delay;
  final Object? throwOnDrain;

  int drains = 0;

  @override
  Future<SyncResult> drain() async {
    drains++;
    journal.add('drain');
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (throwOnDrain != null) throw throwOnDrain!;
    return const SyncResult();
  }
}

/// A PullService that reports whatever the scenario needs without reaching a
/// database or a network. It overrides pullAll outright, so the Domains it
/// was constructed with only have to satisfy the signature.
class _FakePullService extends PullService {
  _FakePullService({
    required super.batches,
    required super.expenses,
    required super.mortality,
    required super.feed,
    required super.weight,
    required super.vaccination,
    required super.harvest,
    required super.sales,
    required this.journal,
    this.rows = 0,
    this.throwOnPull,
    this.delay = Duration.zero,
    this.result,
  });

  final _Journal journal;
  int rows;
  final Object? throwOnPull;
  final Duration delay;

  /// When set, returned instead of the normal all-tables-landed result.
  /// Lets a test model a partial or total table failure, and lets a test
  /// flip a failing run into a succeeding one mid-scenario.
  PullResult? result;

  int pulls = 0;

  @override
  Future<PullResult> pullAll() async {
    pulls++;
    journal.add('pull');
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (throwOnPull != null) throw throwOnPull!;
    return result ?? PullResult(perTable: {'batches': rows}, errors: const []);
  }
}

class _StubRemoteBatchRepository extends RemoteBatchRepository {
  _StubRemoteBatchRepository(super.client);
  @override
  Future<List<Batch>> getAll() async => const [];
}

/// Counts real remote fetches, so "only one pass happened" is a fact.
class _Fetches {
  int batchCalls = 0;
}

class _CountingRemoteBatchRepository extends RemoteBatchRepository {
  _CountingRemoteBatchRepository(super.client, this._fetches);

  final _Fetches _fetches;

  @override
  Future<List<Batch>> getAll() async {
    _fetches.batchCalls++;
    return const [];
  }
}


class _EmptyExpenseRepo extends RemoteExpenseRepository {
  _EmptyExpenseRepo(super.client);
  @override
  Future<List<Expense>> getAll() async => const [];
}

class _EmptyMortalityRepo extends RemoteMortalityRepository {
  _EmptyMortalityRepo(super.client);
  @override
  Future<List<Mortality>> getAll() async => const [];
}

class _EmptyFeedRepo extends RemoteFeedRepository {
  _EmptyFeedRepo(super.client);
  @override
  Future<List<Feed>> getAll() async => const [];
}

class _EmptyWeightRepo extends RemoteWeightRepository {
  _EmptyWeightRepo(super.client);
  @override
  Future<List<WeightSample>> getAll() async => const [];
}

class _EmptyVaccinationRepo extends RemoteVaccinationRepository {
  _EmptyVaccinationRepo(super.client);
  @override
  Future<List<Vaccination>> getAll() async => const [];
}

class _EmptyHarvestRepo extends RemoteHarvestRepository {
  _EmptyHarvestRepo(super.client);
  @override
  Future<List<Harvest>> getAll() async => const [];
}

class _EmptySaleRepo extends RemoteSaleRepository {
  _EmptySaleRepo(super.client);
  @override
  Future<List<Sale>> getAll() async => const [];
}

/// The automatic pull: one throttle and one in-flight guard shared by app
/// start, app resume and reconnect, with no role logic anywhere.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  // WidgetsBinding is needed for addObserver / removeObserver.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalSyncQueueRepository queue;
  late SupabaseClient client;
  late _Clock clock;
  late _Journal journal;
  late _FakeConnectivity connectivity;
  late bool signedIn;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queue = LocalSyncQueueRepository(db);
    client = SupabaseClient('https://example.supabase.co', 'anon-key');
    addTearDown(client.dispose);
    clock = _Clock();
    journal = _Journal();
    connectivity = _FakeConnectivity();
    addTearDown(connectivity.close);
    signedIn = true;

    await db
        .into(db.businesses)
        .insert(
          BusinessesCompanion.insert(businessId: 'biz-1', name: 'Sunny Farm'),
        );
    await db
        .into(db.accounts)
        .insert(
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

  Account account(String role) => Account(
        accountId: 'acc-1',
        businessId: 'biz-1',
        role: role,
        name: 'Mia',
        email: 'mia@example.com',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
      );

  ({AutoPullTrigger trigger, _FakeSyncService sync, _FakePullService pull})
      build({
    String role = 'manager',
    int rows = 0,
    Duration pullDelay = Duration.zero,
    Object? throwOnDrain,
    Object? throwOnPull,
    bool start = true,
    bool connected = true,
    bool injectIsConnected = true,
    PullResult? pullResult,
  }) {
    final sync = _FakeSyncService(
      queue: queue,
      client: client,
      pushers: const [],
      journal: journal,
      delay: pullDelay,
      throwOnDrain: throwOnDrain,
    );
    final acct = account(role);
    // Real Domains over an in-memory database and empty remotes. The fake
    // subclass overrides pullAll, so these are never actually called.
    final pull = _FakePullService(
      batches: BatchDomain(
        batchRepo: LocalBatchRepository(db),
        remoteBatchRepo: _StubRemoteBatchRepository(client),
        harvestRepo: LocalHarvestRepository(db),
        mortalityRepo: LocalMortalityRepository(db),
        expenseRepo: LocalExpenseRepository(db),
        saleRepo: LocalSaleRepository(db),
        feedRepo: LocalFeedRepository(db),
        weightRepo: LocalWeightRepository(db),
        currentAccount: acct,
      ),
      expenses: ExpenseDomain(
        expenseRepo: LocalExpenseRepository(db),
        remoteExpenseRepo: _EmptyExpenseRepo(client),
        batchRepo: LocalBatchRepository(db),
        currentAccount: acct,
      ),
      mortality: MortalityDomain(
        mortalityRepo: LocalMortalityRepository(db),
        remoteMortalityRepo: _EmptyMortalityRepo(client),
        batchRepo: LocalBatchRepository(db),
        harvestRepo: LocalHarvestRepository(db),
        currentAccount: acct,
      ),
      feed: FeedDomain(
        feedRepo: LocalFeedRepository(db),
        remoteFeedRepo: _EmptyFeedRepo(client),
        batchRepo: LocalBatchRepository(db),
        currentAccount: acct,
      ),
      weight: WeightDomain(
        weightRepo: LocalWeightRepository(db),
        remoteWeightRepo: _EmptyWeightRepo(client),
        batchRepo: LocalBatchRepository(db),
        currentAccount: acct,
      ),
      vaccination: VaccinationDomain(
        vaccinationRepo: LocalVaccinationRepository(db),
        remoteVaccinationRepo: _EmptyVaccinationRepo(client),
        batchRepo: LocalBatchRepository(db),
        currentAccount: acct,
      ),
      harvest: HarvestDomain(
        harvestRepo: LocalHarvestRepository(db),
        remoteHarvestRepo: _EmptyHarvestRepo(client),
        batchRepo: LocalBatchRepository(db),
        mortalityRepo: LocalMortalityRepository(db),
        currentAccount: acct,
      ),
      sales: SaleDomain(
        saleRepo: LocalSaleRepository(db),
        remoteSaleRepo: _EmptySaleRepo(client),
        harvestRepo: LocalHarvestRepository(db),
        currentAccount: acct,
      ),
      journal: journal,
      rows: rows,
      delay: pullDelay,
      throwOnPull: throwOnPull,
      result: pullResult,
    );
    final trigger = AutoPullTrigger(
      sync,
      pull,
      connectivity: connectivity,
      now: clock.now,
      hasAccount: () => signedIn,
      // The real default reads connectivity.checkConnectivity(); injection
      // keeps each scenario independent of the fake's own state.
      isConnected:
          injectIsConnected ? () async => connected : null,
    );
    if (start) trigger.start();
    addTearDown(trigger.dispose);
    return (trigger: trigger, sync: sync, pull: pull);
  }

  group('ordering', () {
    test('the push runs before the pull, and both run', () async {
      final h = build();
      await h.trigger.runNow();
      expect(journal.entries, ['drain', 'pull']);
      expect(h.sync.drains, 1);
      expect(h.pull.pulls, 1);
    });
  });

  group('no role logic', () {
    test('a Manager account gets the same run as a Staff account', () async {
      final manager = build(role: 'manager');
      await manager.trigger.runNow();
      final managerEntries = List<String>.from(journal.entries);

      journal.clear();
      final staff = build(role: 'staff');
      await staff.trigger.runNow();

      expect(journal.entries, managerEntries,
          reason: 'the trigger does the same thing for either role');
      expect(staff.sync.drains, 1);
      expect(staff.pull.pulls, 1);
    });

    test('the trigger source contains no role comparison', () {
      final source =
          File('lib/sync/triggers/auto_pull_trigger.dart').readAsStringSync();
      expect(source, isNot(contains('role ==')),
          reason: 'no role check anywhere in the trigger');
    });
  });

  group('throttle', () {
    test('a second run inside 60 s is skipped', () async {
      final h = build();
      await h.trigger.runNow();
      clock.advance(const Duration(seconds: 59));
      await h.trigger.runNow();
      expect(h.pull.pulls, 1, reason: 'still inside the throttle window');
    });

    test('a run after 60 s is allowed again', () async {
      final h = build();
      await h.trigger.runNow();
      clock.advance(const Duration(seconds: 60));
      await h.trigger.runNow();
      expect(h.pull.pulls, 2);
    });

    test('the throttle is counted from the end of a successful run', () async {
      final h = build(pullDelay: const Duration(milliseconds: 30));
      final first = h.trigger.runNow();
      // 30 s pass while the first run is still working.
      clock.advance(const Duration(seconds: 30));
      await first;
      // The window opened when the run finished, so the 60 s starts there
      // and only 0 s of it have gone.
      await h.trigger.runNow();
      expect(h.pull.pulls, 1,
          reason: 'measured from the successful finish, not the start');

      clock.advance(const Duration(seconds: 60));
      await h.trigger.runNow();
      expect(h.pull.pulls, 2, reason: 'the window has now fully elapsed');
    });

    test('all three triggers share one throttle', () async {
      final h = build();
      h.trigger.onAppStart();
      await pumpEventQueue();

      // Resume, then reconnect: both inside the window, so neither runs.
      h.trigger.didChangeAppLifecycleState(AppLifecycleState.resumed);
      connectivity.emit([ConnectivityResult.wifi]);
      await pumpEventQueue();

      expect(h.pull.pulls, 1, reason: 'one run served all three moments');
    });

    test('reconnect after the window does run again', () async {
      final h = build();
      await h.trigger.runNow();
      clock.advance(const Duration(seconds: 61));
      connectivity.emit([ConnectivityResult.wifi]);
      await pumpEventQueue();
      expect(h.pull.pulls, 2);
    });

    test('losing connectivity runs nothing', () async {
      final h = build();
      await h.trigger.runNow();
      clock.advance(const Duration(seconds: 61));
      connectivity.emit([ConnectivityResult.none]);
      await pumpEventQueue();
      expect(h.pull.pulls, 1, reason: 'nothing to pull without a network');
    });
  });

  group('lifecycle', () {
    test('resume runs, pause does not', () async {
      final h = build();
      h.trigger.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(h.pull.pulls, 1);

      clock.advance(const Duration(seconds: 61));
      h.trigger.didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();
      expect(h.pull.pulls, 1, reason: 'pausing is not a moment to sync');
    });

    test('dispose detaches the connectivity listener', () async {
      final h = build(start: false);
      h.trigger.start();
      h.trigger.dispose();
      clock.advance(const Duration(seconds: 61));
      connectivity.emit([ConnectivityResult.wifi]);
      await pumpEventQueue();
      expect(h.pull.pulls, 0,
          reason: 'the subscription was cancelled, so nothing is listening');
    });

    test('a real lifecycle resume reaches the trigger, and stops after dispose',
        () async {
      final h = build(start: false);
      h.trigger.start();
      final binding = TestWidgetsFlutterBinding.instance;

      // Through the binding, not by calling the method directly: this is
      // the path a real resume takes.
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(h.pull.pulls, 1, reason: 'registered, so resume reached it');

      clock.advance(const Duration(seconds: 61));
      h.trigger.dispose();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(h.pull.pulls, 1,
          reason: 'detached, so a later resume reaches nobody');
    });
  });

  group('overlap', () {
    test('a second call while one is running is skipped', () async {
      final h = build(pullDelay: const Duration(milliseconds: 20));
      final first = h.trigger.runNow();
      final second = h.trigger.runNow();
      await Future.wait([first, second]);
      expect(h.pull.pulls, 1, reason: 'the second call did not start a pass');
    });

    test('a manual pull in flight is joined, not duplicated', () async {
      // The real PullService here, not the fake: the single-flight that
      // stops a second pass is the real one, and the batch table is counted
      // at the remote end so "one fetch" is a fact, not a claim.
      final fetches = _Fetches();
      final acct = account('staff');
      final real = PullService(
        batches: BatchDomain(
          batchRepo: LocalBatchRepository(db),
          remoteBatchRepo: _CountingRemoteBatchRepository(client, fetches),
          harvestRepo: LocalHarvestRepository(db),
          mortalityRepo: LocalMortalityRepository(db),
          expenseRepo: LocalExpenseRepository(db),
          saleRepo: LocalSaleRepository(db),
          feedRepo: LocalFeedRepository(db),
          weightRepo: LocalWeightRepository(db),
          currentAccount: acct,
        ),
        expenses: ExpenseDomain(
          expenseRepo: LocalExpenseRepository(db),
          remoteExpenseRepo: _EmptyExpenseRepo(client),
          batchRepo: LocalBatchRepository(db),
          currentAccount: acct,
        ),
        mortality: MortalityDomain(
          mortalityRepo: LocalMortalityRepository(db),
          remoteMortalityRepo: _EmptyMortalityRepo(client),
          batchRepo: LocalBatchRepository(db),
          harvestRepo: LocalHarvestRepository(db),
          currentAccount: acct,
        ),
        feed: FeedDomain(
          feedRepo: LocalFeedRepository(db),
          remoteFeedRepo: _EmptyFeedRepo(client),
          batchRepo: LocalBatchRepository(db),
          currentAccount: acct,
        ),
        weight: WeightDomain(
          weightRepo: LocalWeightRepository(db),
          remoteWeightRepo: _EmptyWeightRepo(client),
          batchRepo: LocalBatchRepository(db),
          currentAccount: acct,
        ),
        vaccination: VaccinationDomain(
          vaccinationRepo: LocalVaccinationRepository(db),
          remoteVaccinationRepo: _EmptyVaccinationRepo(client),
          batchRepo: LocalBatchRepository(db),
          currentAccount: acct,
        ),
        harvest: HarvestDomain(
          harvestRepo: LocalHarvestRepository(db),
          remoteHarvestRepo: _EmptyHarvestRepo(client),
          batchRepo: LocalBatchRepository(db),
          mortalityRepo: LocalMortalityRepository(db),
          currentAccount: acct,
        ),
        sales: SaleDomain(
          saleRepo: LocalSaleRepository(db),
          remoteSaleRepo: _EmptySaleRepo(client),
          harvestRepo: LocalHarvestRepository(db),
          currentAccount: acct,
        ),
      );
      final sync = _FakeSyncService(
        queue: queue,
        client: client,
        pushers: const [],
        journal: journal,
      );
      final trigger = AutoPullTrigger(
        sync,
        real,
        connectivity: connectivity,
        now: clock.now,
        hasAccount: () => signedIn,
      );
      addTearDown(trigger.dispose);

      final manual = real.pullAll();
      final automatic = trigger.runNow();
      await Future.wait([manual, automatic]);

      expect(fetches.batchCalls, 1,
          reason: 'the trigger joined the pull already running');
    });
  });

  group('no signed-in account', () {
    test('nothing runs and nothing is pulled', () async {
      signedIn = false;
      final h = build();
      h.trigger.onAppStart();
      h.trigger.didChangeAppLifecycleState(AppLifecycleState.resumed);
      connectivity.emit([ConnectivityResult.wifi]);
      await pumpEventQueue();

      expect(h.sync.drains, 0);
      expect(h.pull.pulls, 0);
    });

    test('a run requested directly is skipped too', () async {
      signedIn = false;
      final h = build();
      await h.trigger.runNow();
      expect(h.pull.pulls, 0);
    });
  });

  group('failures are silent', () {
    test('a throwing drain neither escapes nor stops the next run', () async {
      final failing = build(throwOnDrain: Exception('offline'));
      await expectLater(failing.trigger.runNow(), completes,
          reason: 'a failed run is swallowed');

      clock.advance(const Duration(seconds: 61));
      final ok = build();
      await ok.trigger.runNow();
      expect(ok.pull.pulls, 1, reason: 'the next trigger tried again');
    });

    test('a throwing pull is swallowed too', () async {
      final h = build(throwOnPull: Exception('server down'));
      await expectLater(h.trigger.runNow(), completes);
    });

    test('a throwing run leaves no window, so the next one retries', () async {
      final h = build(throwOnPull: Exception('server down'));
      await h.trigger.runNow();
      await h.trigger.runNow();
      expect(h.pull.pulls, 2,
          reason: 'a run that threw never opened the throttle window');
    });
  });

  group('onChangesArrived', () {
    test('reports when rows actually arrived', () async {
      final h = build(rows: 3);
      final reported = <int>[];
      h.trigger.onChangesArrived = reported.add;
      await h.trigger.runNow();
      expect(reported, [3]);
    });

    test('says nothing when nothing changed', () async {
      final h = build(rows: 0);
      final reported = <int>[];
      h.trigger.onChangesArrived = reported.add;
      await h.trigger.runNow();
      expect(reported, isEmpty,
          reason: 'no refresh is due when the pull brought nothing');
    });

    test('says nothing when the run failed', () async {
      final h = build(rows: 5, throwOnPull: Exception('nope'));
      final reported = <int>[];
      h.trigger.onChangesArrived = reported.add;
      await h.trigger.runNow();
      expect(reported, isEmpty);
    });
  });

  group('the 60 s throttle does not touch a manual pull', () {
    test('a manual pullAll is never throttled', () async {
      final h = build();
      await h.trigger.runNow();
      // A manual pull straight afterwards, with no clock movement at all.
      final manual = await h.pull.pullAll();
      expect(manual.updated, 0);
      expect(h.pull.pulls, 2,
          reason: 'the throttle lives in the trigger, not in pullAll');
    });
  });

  group('connection gate', () {
    test('app start while offline does not drain and does not pull', () async {
      final h = build(connected: false);
      h.trigger.onAppStart();
      await pumpEventQueue();
      expect(h.sync.drains, 0, reason: 'no push without a network');
      expect(h.pull.pulls, 0, reason: 'and no pull either');
      expect(journal.entries, isEmpty);
    });

    test('app resume while offline does not drain and does not pull',
        () async {
      final h = build(connected: false);
      h.trigger.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(h.sync.drains, 0);
      expect(h.pull.pulls, 0);
      expect(journal.entries, isEmpty);
    });

    test('app start while online drains then pulls', () async {
      final h = build(connected: true);
      h.trigger.onAppStart();
      await pumpEventQueue();
      expect(journal.entries, ['drain', 'pull']);
      expect(h.sync.drains, 1);
      expect(h.pull.pulls, 1);
    });

    test('app resume while online drains then pulls', () async {
      final h = build(connected: true);
      h.trigger.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(journal.entries, ['drain', 'pull']);
      expect(h.sync.drains, 1);
      expect(h.pull.pulls, 1);
    });

    test('an offline start leaves the throttle window untouched', () async {
      final offline = build(connected: false);
      offline.trigger.onAppStart();
      await pumpEventQueue();
      expect(offline.pull.pulls, 0, reason: 'nothing ran while offline');
      expect(offline.sync.drains, 0);

      // With the network back, and no clock movement at all: had the
      // blocked attempt spent the window, this would be throttled.
      final online = build(connected: true);
      online.trigger.onAppStart();
      await pumpEventQueue();
      expect(online.pull.pulls, 1,
          reason: 'the offline attempt left no window behind it');
    });

    test('a blocked run does not disturb an open window either', () async {
      final h = build(injectIsConnected: false);
      connectivity.connected = true;
      await h.trigger.runNow();
      expect(h.pull.pulls, 1, reason: 'a successful run opened the window');

      connectivity.connected = false;
      h.trigger.onAppStart();
      await pumpEventQueue();
      expect(h.pull.pulls, 1, reason: 'the offline start was skipped');

      await h.trigger.runNow();
      expect(h.pull.pulls, 1,
          reason: 'the original window still holds; the skip changed nothing');
    });

    test('the default gate reads connectivity_plus itself', () async {
      final h = build(injectIsConnected: false);
      connectivity.connected = false;
      h.trigger.onAppStart();
      await pumpEventQueue();
      expect(connectivity.checks, greaterThan(0),
          reason: 'the real source was consulted, not the injected stub');
      expect(h.pull.pulls, 0);

      connectivity.connected = true;
      h.trigger.onAppStart();
      await pumpEventQueue();
      expect(h.pull.pulls, 1, reason: 'same gate, now reporting a network');
    });

    test('reconnect never asks about the connection', () async {
      final h = build(injectIsConnected: false);
      connectivity.connected = true;
      connectivity.emit([ConnectivityResult.wifi]);
      await pumpEventQueue();
      expect(journal.entries, ['drain', 'pull'],
          reason: 'reconnect is unchanged: the network is already back');
      expect(h.pull.pulls, 1);
      expect(connectivity.checks, 0,
          reason: 'so it has no reason to check for one');
    });

    test('connectivity restored pulls for Manager and Staff alike', () async {
      final manager = build(role: 'manager', injectIsConnected: false);
      connectivity.emit([ConnectivityResult.wifi]);
      await pumpEventQueue();
      expect(manager.pull.pulls, 1);
      final managerJournal = List<String>.from(journal.entries);

      journal.clear();
      final staff = build(role: 'staff', injectIsConnected: false);
      connectivity.emit([ConnectivityResult.wifi]);
      await pumpEventQueue();

      expect(journal.entries, managerJournal,
          reason: 'the reconnect trigger has no role logic either');
      expect(staff.pull.pulls, 1);
    });
  });

  group('the window opens only for a successful run', () {
    // Every table the pull tries came back as an error, so
    // errors.length == tablesPulled and nothing landed.
    final allTablesFailed = PullResult(
      perTable: const {},
      errors: const [
        'batches', 'expenses', 'mortality', 'feed',
        'weight', 'vaccination', 'harvest', 'sales',
      ],
    );

    test('a run where every table failed leaves no window', () async {
      final h = build(pullResult: allTablesFailed);
      await h.trigger.runNow();
      await h.trigger.runNow();
      expect(h.pull.pulls, 2,
          reason: 'a total failure must not lock the app out for a minute');
    });

    test('a total failure does not stop a later trigger after 60 s', () async {
      final h = build(pullResult: allTablesFailed);
      await h.trigger.runNow();
      expect(h.pull.pulls, 1);
      clock.advance(const Duration(seconds: 60));
      await h.trigger.runNow();
      expect(h.pull.pulls, 2);
    });

    test('a run where one table failed still counts as a success', () async {
      final h = build(
        pullResult: const PullResult(
          perTable: {'batches': 0},
          errors: ['feed'],
        ),
      );
      await h.trigger.runNow();
      await h.trigger.runNow();
      expect(h.pull.pulls, 1,
          reason: 'a table landed, so the run succeeded and opened the window');
    });

    test('a partially failed run releases the window after 60 s', () async {
      final h = build(
        pullResult: const PullResult(
          perTable: {'batches': 0},
          errors: ['feed'],
        ),
      );
      await h.trigger.runNow();
      clock.advance(const Duration(seconds: 59));
      await h.trigger.runNow();
      expect(h.pull.pulls, 1, reason: 'still inside the window');
      clock.advance(const Duration(seconds: 1));
      await h.trigger.runNow();
      expect(h.pull.pulls, 2, reason: 'the window has now elapsed');
    });

    test('a failed run followed by a success throttles as normal', () async {
      final h = build(pullResult: allTablesFailed);
      await h.trigger.runNow();
      expect(h.pull.pulls, 1);

      // The retry lands this time.
      h.pull.result = const PullResult(perTable: {'batches': 2}, errors: []);
      await h.trigger.runNow();
      expect(h.pull.pulls, 2);

      // And now the window the success opened is respected.
      await h.trigger.runNow();
      expect(h.pull.pulls, 2, reason: 'the successful run opened the window');
    });

    test('no rows is still a success, and still opens the window', () async {
      final h = build(rows: 0);
      await h.trigger.runNow();
      await h.trigger.runNow();
      expect(h.pull.pulls, 1,
          reason: 'nothing new is not the same as nothing arrived');
    });
  });
}
