import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:broiler_fms/presentation/mobile/batch/batch_detail_screen.dart';
import 'package:broiler_fms/presentation/mobile/financial/financial_summary_screen.dart';
import 'package:broiler_fms/presentation/shared/widgets/auto_pull_host.dart';
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
import 'package:broiler_fms/sync/sync_providers.dart';
import 'package:broiler_fms/sync/sync_service.dart';
import 'package:broiler_fms/sync/triggers/auto_pull_trigger.dart';

DynamicLibrary _openSqlite() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } on ArgumentError {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

class _StubRemoteBatchRepository extends RemoteBatchRepository {
  _StubRemoteBatchRepository(super.client);
  @override
  Future<List<Batch>> getAll() async => const [];
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

/// The presentation half of an automatic pull.
///
/// `AutoPullTrigger` reports how many rows arrived; `AutoPullHost` is what
/// turns that into invalidations. What matters here is the condition: an
/// open screen is refreshed when rows genuinely arrived, and left alone
/// when nothing changed.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late SupabaseClient client;
  late LocalSyncQueueRepository queue;
  late AutoPullTrigger trigger;

  final account = Account(
    accountId: 'acc-1',
    businessId: 'biz-1',
    role: 'staff',
    name: 'Sam',
    email: 'sam@example.com',
    status: 'active',
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    client = SupabaseClient('https://example.supabase.co', 'anon-key');
    addTearDown(client.dispose);
    queue = LocalSyncQueueRepository(db);

    final sync = SyncService(queue: queue, client: client, pushers: const []);
    final pull = PullService(
      batches: BatchDomain(
        batchRepo: LocalBatchRepository(db),
        remoteBatchRepo: _StubRemoteBatchRepository(client),
        harvestRepo: LocalHarvestRepository(db),
        mortalityRepo: LocalMortalityRepository(db),
        expenseRepo: LocalExpenseRepository(db),
        saleRepo: LocalSaleRepository(db),
        feedRepo: LocalFeedRepository(db),
        weightRepo: LocalWeightRepository(db),
        currentAccount: account,
      ),
      expenses: ExpenseDomain(
        expenseRepo: LocalExpenseRepository(db),
        remoteExpenseRepo: _EmptyExpenseRepo(client),
        batchRepo: LocalBatchRepository(db),
        currentAccount: account,
      ),
      mortality: MortalityDomain(
        mortalityRepo: LocalMortalityRepository(db),
        remoteMortalityRepo: _EmptyMortalityRepo(client),
        batchRepo: LocalBatchRepository(db),
        harvestRepo: LocalHarvestRepository(db),
        currentAccount: account,
      ),
      feed: FeedDomain(
        feedRepo: LocalFeedRepository(db),
        remoteFeedRepo: _EmptyFeedRepo(client),
        batchRepo: LocalBatchRepository(db),
        currentAccount: account,
      ),
      weight: WeightDomain(
        weightRepo: LocalWeightRepository(db),
        remoteWeightRepo: _EmptyWeightRepo(client),
        batchRepo: LocalBatchRepository(db),
        currentAccount: account,
      ),
      vaccination: VaccinationDomain(
        vaccinationRepo: LocalVaccinationRepository(db),
        remoteVaccinationRepo: _EmptyVaccinationRepo(client),
        batchRepo: LocalBatchRepository(db),
        currentAccount: account,
      ),
      harvest: HarvestDomain(
        harvestRepo: LocalHarvestRepository(db),
        remoteHarvestRepo: _EmptyHarvestRepo(client),
        batchRepo: LocalBatchRepository(db),
        mortalityRepo: LocalMortalityRepository(db),
        currentAccount: account,
      ),
      sales: SaleDomain(
        saleRepo: LocalSaleRepository(db),
        remoteSaleRepo: _EmptySaleRepo(client),
        harvestRepo: LocalHarvestRepository(db),
        currentAccount: account,
      ),
    );

    trigger = AutoPullTrigger(sync, pull, hasAccount: () => true);
  });

  tearDown(() => db.close());

  /// Mounts the host and hands back the container Riverpod created for it.
  ///
  /// `syncStatusProvider` is overridden with a trivial one: the real one
  /// watches the Drift queue, which in a test would reach for the on-disk
  /// database through path_provider and hang. The point here is only
  /// whether the host invalidates it, which an override models exactly.
  Future<ProviderContainer> mountHost(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          autoPullTriggerProvider.overrideWithValue(trigger),
          syncStatusProvider.overrideWith(
            (ref) => Stream<SyncStatus>.value(
              const SyncStatus(isOnline: true, pendingCount: 0),
            ),
          ),
        ],
        child: MaterialApp(
          home: AutoPullHost(child: const Text('content')),
        ),
      ),
    );
    await tester.pump();
    return ProviderScope.containerOf(
      tester.element(find.byType(AutoPullHost)),
      listen: false,
    );
  }

  testWidgets('refreshes open screens when rows actually arrived',
      (tester) async {
    final container = await mountHost(tester);

    var statusRebuilds = 0;
    final sub = container.listen(syncStatusProvider, (_, _) => statusRebuilds++);
    addTearDown(sub.close);
    await tester.pump();
    final before = statusRebuilds;

    // Nothing changed: no invalidation should happen.
    trigger.onChangesArrived?.call(0);
    await tester.pump();
    expect(statusRebuilds, before,
        reason: 'a pull that brought nothing must not rebuild anything');

    // Something changed: the open providers are invalidated.
    trigger.onChangesArrived?.call(3);
    await tester.pump();
    expect(statusRebuilds, greaterThan(before),
        reason: 'rows arrived, so the open providers are invalidated');
  });

  testWidgets('a count of zero invalidates nothing', (tester) async {
    final container = await mountHost(tester);

    var rebuilds = 0;
    final sub = container.listen(syncStatusProvider, (_, _) => rebuilds++);
    addTearDown(sub.close);
    await tester.pump();
    final before = rebuilds;

    trigger.onChangesArrived?.call(0);
    await tester.pump();

    expect(rebuilds, before);
  });

  testWidgets('a negative count invalidates nothing', (tester) async {
    final container = await mountHost(tester);

    var rebuilds = 0;
    final sub = container.listen(syncStatusProvider, (_, _) => rebuilds++);
    addTearDown(sub.close);
    await tester.pump();
    final before = rebuilds;

    trigger.onChangesArrived?.call(-1);
    await tester.pump();

    expect(rebuilds, before);
  });

  testWidgets('renders its child untouched', (tester) async {
    await mountHost(tester);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('unmounting clears the callback so a late run cannot reach it',
      (tester) async {
    await mountHost(tester);
    expect(trigger.onChangesArrived, isNotNull,
        reason: 'attached while mounted');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(trigger.onChangesArrived, isNull,
        reason: 'detached on unmount, so a late pull cannot call a dead State');
  });

  testWidgets('invalidating the whole families is safe with no ids',
      (tester) async {
    final container = await mountHost(tester);

    // The host invalidates the families themselves, which is what makes
    // every open batch recompute. Calling them with no id must be safe.
    container.invalidate(batchDetailProvider);
    container.invalidate(financialSummaryProvider);
    await tester.pump();

    expect(find.text('content'), findsOneWidget);
  });
}
