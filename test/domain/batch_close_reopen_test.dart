import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/data/local/database.dart'
    show
        AccountsCompanion,
        AppDatabase,
        BatchesCompanion,
        BusinessesCompanion;
import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/repository/batch/remote_batch_repository.dart';
import 'package:broiler_fms/repository/expense/local_expense_repository.dart';
import 'package:broiler_fms/repository/feed/local_feed_repository.dart';
import 'package:broiler_fms/repository/harvest/local_harvest_repository.dart';
import 'package:broiler_fms/repository/mortality/local_mortality_repository.dart';
import 'package:broiler_fms/repository/sale/local_sale_repository.dart';
import 'package:broiler_fms/repository/weight/local_weight_repository.dart';

/// A RemoteBatchRepository that never talks to the network. The
/// close/reopen paths under test never read from it.
class _UnusedRemoteBatch extends RemoteBatchRepository {
  _UnusedRemoteBatch(super.client);
}

DynamicLibrary _openSqlite() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } on ArgumentError {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

/// Closing and reopening a batch: a close needs every bird accounted
/// for, a reopen needs the batch actually closed. Proves the exact
/// refusal messages and that createBatch needs a business.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late LocalBatchRepository batchRepo;
  late LocalHarvestRepository harvestRepo;
  late LocalMortalityRepository mortalityRepo;
  late SupabaseClient client;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    batchRepo = LocalBatchRepository(db);
    harvestRepo = LocalHarvestRepository(db);
    mortalityRepo = LocalMortalityRepository(db);
    client = SupabaseClient('https://example.supabase.co', 'anon-key');
    addTearDown(client.dispose);
  });

  tearDown(() => db.close());

  BatchDomain domain({String? businessId = 'biz-1'}) => BatchDomain(
        batchRepo: batchRepo,
        remoteBatchRepo: _UnusedRemoteBatch(client),
        harvestRepo: harvestRepo,
        mortalityRepo: mortalityRepo,
        expenseRepo: LocalExpenseRepository(db),
        saleRepo: LocalSaleRepository(db),
        feedRepo: LocalFeedRepository(db),
        weightRepo: LocalWeightRepository(db),
        currentAccount: Account(
          accountId: 'acc-manager',
          businessId: businessId,
          role: 'manager',
          name: 'Ada',
          email: 'ada@example.com',
          status: 'active',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

  Future<void> seedBatch({
    String id = 'batch-1',
    bool isClosed = false,
    int startingBirdCount = 100,
  }) async {
    await db.into(db.businesses).insert(
          BusinessesCompanion.insert(businessId: 'biz-1', name: 'Sunny Farm'),
        );
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            accountId: 'acc-manager',
            businessId: const Value('biz-1'),
            role: 'manager',
            name: 'Ada',
            email: 'ada@example.com',
          ),
        );
    await db.into(db.batches).insert(
          BatchesCompanion.insert(
            batchId: id,
            businessId: 'biz-1',
            assignedStaffId: const Value(null),
            batchName: 'House 1',
            startingBirdCount: startingBirdCount,
            startDate: DateTime(2026, 1, 1),
            isClosed: Value(isClosed),
            createdAt: Value(DateTime(2026, 1, 1)),
          ),
        );
  }

  test('createBatch refuses when the account has no business', () async {
    // Proves an unlinked account is told to register first, with the
    // exact message. createBatch throws synchronously, before any
    // await, so a plain expect is the correct shape here.
    expect(
      () => domain(businessId: null).createBatch(
        batchName: 'House 1',
        startingBirdCount: 100,
        startDate: DateTime(2026, 1, 1),
      ),
      throwsA(
        isA<DomainException>().having(
          (e) => e.message,
          'message',
          'This account is not linked to a business yet.',
        ),
      ),
    );
  });

  test('createBatch registers a batch for the account business', () async {
    // Proves the happy path writes the batch (use case: Manager
    // registers a new flock).
    final batch = await domain().createBatch(
      batchName: 'House 1',
      startingBirdCount: 100,
      startDate: DateTime(2026, 1, 1),
    );
    expect(batch.businessId, 'biz-1');
    expect(batch.startingBirdCount, 100);
  });

  test('closeBatch refuses while birds are unaccounted for', () async {
    // Proves the close is blocked with the exact "N birds are still
    // unaccounted for" message.
    await seedBatch(startingBirdCount: 100);
    await mortalityRepo.record(
      batchId: 'batch-1',
      recordedBy: 'acc-manager',
      date: DateTime(2026, 1, 2),
      count: 30,
    );
    await harvestRepo.record(
      batchId: 'batch-1',
      recordedBy: 'acc-manager',
      date: DateTime(2026, 1, 2),
      birdCount: 60,
    );
    await expectLater(
      domain().closeBatch('batch-1'),
      throwsA(
        isA<DomainException>().having(
          (e) => e.message,
          'message',
          '10 birds are still unaccounted for, so this batch cannot be '
              'closed yet.',
        ),
      ),
    );
  });

  test('closeBatch closes once every bird is accounted for', () async {
    // Proves the boundary: 40 dead + 60 harvested on 100 closes, and
    // the closed flag is persisted.
    await seedBatch(startingBirdCount: 100);
    await mortalityRepo.record(
      batchId: 'batch-1',
      recordedBy: 'acc-manager',
      date: DateTime(2026, 1, 2),
      count: 40,
    );
    await harvestRepo.record(
      batchId: 'batch-1',
      recordedBy: 'acc-manager',
      date: DateTime(2026, 1, 2),
      birdCount: 60,
    );
    await domain().closeBatch('batch-1');
    final stored = await batchRepo.getById('batch-1');
    expect(stored!.isClosed, isTrue);
  });

  test('reopenBatch refuses an already-open batch', () async {
    // Proves a reopen on a running batch is reported, with the exact
    // message.
    await seedBatch(isClosed: false);
    await expectLater(
      domain().reopenBatch('batch-1'),
      throwsA(
        isA<DomainException>().having(
          (e) => e.message,
          'message',
          'This batch is not closed, so there is nothing to reopen.',
        ),
      ),
    );
  });

  test('reopenBatch clears the closed flag', () async {
    // Proves a closed batch becomes open again (use case: Manager
    // reopens a batch that was closed too early).
    await seedBatch(isClosed: true);
    await domain().reopenBatch('batch-1');
    final stored = await batchRepo.getById('batch-1');
    expect(stored!.isClosed, isFalse);
  });
}
