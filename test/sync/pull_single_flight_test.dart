import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/data/local/database.dart' show AppDatabase;
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

DynamicLibrary _openSqlite() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } on ArgumentError {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

/// Counts every remote fetch, which is one per table per pass, so a test can
/// count real work rather than trust a mock.
class _Counter {
  final List<String> calls = [];
  int get batchCalls => calls.where((c) => c == 'batch').length;
}

class _StubRemoteBatchRepository extends RemoteBatchRepository {
  _StubRemoteBatchRepository(super.client, this._counter);

  final _Counter _counter;

  @override
  Future<List<Batch>> getAll() async {
    _counter.calls.add('batch');
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

/// PullService shares one in-flight run, the same way SyncService.drain
/// does, so two callers arriving together fetch every table once instead of
/// twice.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late SupabaseClient client;
  late _Counter counter;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    client = SupabaseClient('https://example.supabase.co', 'anon-key');
    addTearDown(client.dispose);
    counter = _Counter();
  });

  tearDown(() => db.close());

  final account = Account(
    accountId: 'acc-1',
    role: 'manager',
    name: 'Mia',
    email: 'mia@example.com',
    status: 'active',
    createdAt: DateTime(2026, 1, 1),
    businessId: 'biz-1',
  );

  PullService buildService() => PullService(
        batches: BatchDomain(
          batchRepo: LocalBatchRepository(db),
          remoteBatchRepo: _StubRemoteBatchRepository(client, counter),
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

  test('two concurrent calls share one pass and the same result', () async {
    final service = buildService();

    final first = service.pullAll();
    final second = service.pullAll();

    expect(identical(first, second), isTrue,
        reason: 'the second caller joins the run already in flight');

    final a = await first;
    final b = await second;
    expect(identical(a, b), isTrue, reason: 'one PullResult, shared');
    expect(counter.batchCalls, 1,
        reason: 'the batch table was refreshed once, not twice');
  });

  test('isPulling is true during a run and false once it finishes', () async {
    final service = buildService();
    expect(service.isPulling, isFalse);

    final pending = service.pullAll();
    expect(service.isPulling, isTrue);
    await pending;
    expect(service.isPulling, isFalse);
  });

  test('a later call starts a fresh pass', () async {
    final service = buildService();
    await service.pullAll();
    final second = service.pullAll();
    expect(service.isPulling, isTrue);
    await second;
    expect(service.isPulling, isFalse);
    expect(counter.batchCalls, 2, reason: 'two passes, two refreshes');
  });

  test('pullAll still never throws when every table is empty', () async {
    final service = buildService();
    final result = await service.pullAll();
    expect(result.errors, isEmpty);
    expect(result.updated, 0);
  });
}