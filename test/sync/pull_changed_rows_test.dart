import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/data/local/database.dart'
    show AccountsCompanion, AppDatabase, BusinessesCompanion;
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
import 'package:broiler_fms/repository/expense/remote_expense_repository.dart';
import 'package:broiler_fms/repository/expense/local_expense_repository.dart';
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

/// A remote batch read that never touches the network. The test mutates
/// [rows] to stand in for whatever the server currently holds.
class _StubRemoteBatchRepository extends RemoteBatchRepository {
  _StubRemoteBatchRepository(super.client);

  List<Batch> rows = const [];

  @override
  Future<List<Batch>> getAll() async => rows;
}

/// Pulling the same data twice must report nothing the second time.
///
/// This is the level the sync button cares about: it reads
/// `PullResult.updated`, which sums what each repository returned. Proving
/// the repositories count only real changes is not enough on its own — this
/// drives the real `PullService.pullAll()` over real repositories and a real
/// database, so the sum it produces is the number the user sees.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late _StubRemoteBatchRepository remoteBatches;
  late PullService service;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remoteBatches = _StubRemoteBatchRepository(
      SupabaseClient('https://example.supabase.co', 'anon-key'),
    );

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

    final account = Account(
      accountId: 'acc-1',
      businessId: 'biz-1',
      role: 'manager',
      name: 'Mia',
      email: 'mia@example.com',
      status: 'active',
      createdAt: DateTime(2026, 1, 1),
    );

    final client = SupabaseClient('https://example.supabase.co', 'anon-key');
    service = PullService(
      batches: BatchDomain(
        batchRepo: LocalBatchRepository(db),
        remoteBatchRepo: remoteBatches,
        harvestRepo: LocalHarvestRepository(db),
        mortalityRepo: LocalMortalityRepository(db),
        expenseRepo: LocalExpenseRepository(db),
        saleRepo: LocalSaleRepository(db),
        feedRepo: LocalFeedRepository(db),
        weightRepo: LocalWeightRepository(db),
        currentAccount: account,
      ),
      // The other seven tables are stubbed empty, which is also exactly
      // what a Staff session sees for the two financial ones. They still
      // run through the real fan-out and the real counting.
      expenses: ExpenseDomain(
        expenseRepo: LocalExpenseRepository(db),
        remoteExpenseRepo: _EmptyRemoteExpenseRepository(client),
        batchRepo: LocalBatchRepository(db),
        currentAccount: account,
      ),
      mortality: MortalityDomain(
        mortalityRepo: LocalMortalityRepository(db),
        remoteMortalityRepo: _EmptyRemoteMortalityRepository(client),
        batchRepo: LocalBatchRepository(db),
        harvestRepo: LocalHarvestRepository(db),
        currentAccount: account,
      ),
      feed: FeedDomain(
        feedRepo: LocalFeedRepository(db),
        remoteFeedRepo: _EmptyRemoteFeedRepository(client),
        batchRepo: LocalBatchRepository(db),
        currentAccount: account,
      ),
      weight: WeightDomain(
        weightRepo: LocalWeightRepository(db),
        remoteWeightRepo: _EmptyRemoteWeightRepository(client),
        batchRepo: LocalBatchRepository(db),
        currentAccount: account,
      ),
      vaccination: VaccinationDomain(
        vaccinationRepo: LocalVaccinationRepository(db),
        remoteVaccinationRepo: _EmptyRemoteVaccinationRepository(client),
        batchRepo: LocalBatchRepository(db),
        currentAccount: account,
      ),
      harvest: HarvestDomain(
        harvestRepo: LocalHarvestRepository(db),
        remoteHarvestRepo: _EmptyRemoteHarvestRepository(client),
        batchRepo: LocalBatchRepository(db),
        mortalityRepo: LocalMortalityRepository(db),
        currentAccount: account,
      ),
      sales: SaleDomain(
        saleRepo: LocalSaleRepository(db),
        remoteSaleRepo: _EmptyRemoteSaleRepository(client),
        harvestRepo: LocalHarvestRepository(db),
        currentAccount: account,
      ),
    );
  });

  tearDown(() => db.close());

  /// One batch, as the server currently holds it.
  Batch serverBatch({int startingBirds = 100, String name = 'House 1'}) => Batch(
        batchId: 'batch-1',
        businessId: 'biz-1',
        batchName: name,
        startingBirdCount: startingBirds,
        startDate: DateTime(2026, 1, 1),
        isClosed: false,
        createdAt: DateTime(2026, 1, 1),
      );

  test('the first pull reports the new row, the second reports nothing',
      () async {
    remoteBatches.rows = [serverBatch()];

    final first = await service.pullAll();
    expect(first.errors, isEmpty);
    expect(first.perTable['batches'], 1, reason: 'the row is new');

    final second = await service.pullAll();
    expect(second.errors, isEmpty);
    expect(
      second.updated,
      0,
      reason: 'nothing changed on the server, so nothing is reported',
    );
    expect(second.isEmpty, isTrue);
  });

  test('one changed row is reported once, then the pull goes quiet', () async {
    remoteBatches.rows = [serverBatch()];
    await service.pullAll();
    expect((await service.pullAll()).updated, 0);

    // The Manager renames the batch on another device.
    remoteBatches.rows = [serverBatch(name: 'House 1 renamed')];
    final changed = await service.pullAll();
    expect(changed.updated, 1, reason: 'exactly one row genuinely differs');
    expect(changed.perTable['batches'], 1);

    expect((await service.pullAll()).updated, 0);
  });

  test('a first login on an empty database writes everything', () async {
    remoteBatches.rows = [
      serverBatch(),
      Batch(
        batchId: 'batch-2',
        businessId: 'biz-1',
        batchName: 'House 2',
        startingBirdCount: 200,
        startDate: DateTime(2026, 2, 1),
        isClosed: false,
        createdAt: DateTime(2026, 2, 1),
      ),
    ];

    final result = await service.pullAll();
    expect(result.perTable['batches'], 2);
    expect(result.updated, 2);

    final rows = await db.select(db.batches).get();
    expect(rows.map((r) => r.batchName), containsAll(['House 1', 'House 2']));
  });
}

/// Remote repositories that hold nothing, so the seven non-batch tables
/// contribute zero rows without any network call.

class _EmptyRemoteExpenseRepository extends RemoteExpenseRepository {
  _EmptyRemoteExpenseRepository(super.client);
  @override
  Future<List<Expense>> getAll() async => const [];
}

class _EmptyRemoteMortalityRepository extends RemoteMortalityRepository {
  _EmptyRemoteMortalityRepository(super.client);
  @override
  Future<List<Mortality>> getAll() async => const [];
}

class _EmptyRemoteFeedRepository extends RemoteFeedRepository {
  _EmptyRemoteFeedRepository(super.client);
  @override
  Future<List<Feed>> getAll() async => const [];
}

class _EmptyRemoteWeightRepository extends RemoteWeightRepository {
  _EmptyRemoteWeightRepository(super.client);
  @override
  Future<List<WeightSample>> getAll() async => const [];
}

class _EmptyRemoteVaccinationRepository extends RemoteVaccinationRepository {
  _EmptyRemoteVaccinationRepository(super.client);
  @override
  Future<List<Vaccination>> getAll() async => const [];
}

class _EmptyRemoteHarvestRepository extends RemoteHarvestRepository {
  _EmptyRemoteHarvestRepository(super.client);
  @override
  Future<List<Harvest>> getAll() async => const [];
}

class _EmptyRemoteSaleRepository extends RemoteSaleRepository {
  _EmptyRemoteSaleRepository(super.client);
  @override
  Future<List<Sale>> getAll() async => const [];
}
