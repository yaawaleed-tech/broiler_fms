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
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/harvest/harvest_domain.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/repository/harvest/local_harvest_repository.dart';
import 'package:broiler_fms/repository/harvest/remote_harvest_repository.dart';
import 'package:broiler_fms/repository/mortality/local_mortality_repository.dart';

/// A RemoteHarvestRepository that never talks to the network. The
/// harvest write path under test never reads from it.
class _UnusedRemoteHarvest extends RemoteHarvestRepository {
  _UnusedRemoteHarvest(super.client);
}

DynamicLibrary _openSqlite() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } on ArgumentError {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

/// The Domain-layer guards on recording a harvest: the batch must be
/// open, assigned to the caller (or unassigned for a Manager), and the
/// bird count must still fit. Proves the exact messages Staff sees.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late LocalHarvestRepository harvestRepo;
  late LocalMortalityRepository mortalityRepo;
  late LocalBatchRepository batchRepo;
  late SupabaseClient client;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    harvestRepo = LocalHarvestRepository(db);
    mortalityRepo = LocalMortalityRepository(db);
    batchRepo = LocalBatchRepository(db);
    client = SupabaseClient('https://example.supabase.co', 'anon-key');
    addTearDown(client.dispose);
  });

  tearDown(() => db.close());

  Account account({String role = 'staff'}) => Account(
        accountId: 'acc-1',
        businessId: 'biz-1',
        role: role,
        name: 'Sam',
        email: 'sam@example.com',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
      );

  HarvestDomain domain({String role = 'staff'}) => HarvestDomain(
        harvestRepo: harvestRepo,
        remoteHarvestRepo: _UnusedRemoteHarvest(client),
        batchRepo: batchRepo,
        mortalityRepo: mortalityRepo,
        currentAccount: account(role: role),
      );

  Future<void> seedBatch({
    String id = 'batch-1',
    String? assignedStaffId = 'acc-1',
    bool isClosed = false,
    int startingBirdCount = 100,
  }) async {
    await db.into(db.businesses).insert(
          BusinessesCompanion.insert(businessId: 'biz-1', name: 'Sunny Farm'),
        );
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            accountId: 'acc-1',
            businessId: const Value('biz-1'),
            role: 'staff',
            name: 'Sam',
            email: 'sam@example.com',
          ),
        );
    await db.into(db.batches).insert(
          BatchesCompanion.insert(
            batchId: id,
            businessId: 'biz-1',
            assignedStaffId: Value(assignedStaffId),
            batchName: 'House 1',
            startingBirdCount: startingBirdCount,
            startDate: DateTime(2026, 1, 1),
            isClosed: Value(isClosed),
            createdAt: Value(DateTime(2026, 1, 1)),
          ),
        );
  }

  test('records a harvest when the batch is open and assigned to the Staff',
      () async {
    // Proves the happy path writes and returns a harvest (use case:
    // Staff records birds leaving the batch).
    await seedBatch();
    final harvest = await domain().recordHarvest(
      batchId: 'batch-1',
      date: DateTime(2026, 1, 2),
      birdCount: 20,
    );
    expect(harvest.birdCount, 20);
    expect(await harvestRepo.getByBatch('batch-1'), hasLength(1));
  });

  test('refuses when the batch could not be found', () async {
    // Proves a missing batch is reported rather than written.
    await seedBatch();
    await expectLater(
      domain().recordHarvest(
        batchId: 'missing',
        date: DateTime(2026, 1, 2),
        birdCount: 20,
      ),
      throwsA(
        isA<DomainException>().having(
          (e) => e.message,
          'message',
          'This batch could not be found.',
        ),
      ),
    );
  });

  test('refuses when the batch is closed', () async {
    // Proves a closed batch accepts no more harvests, with the exact
    // message.
    await seedBatch(isClosed: true);
    await expectLater(
      domain().recordHarvest(
        batchId: 'batch-1',
        date: DateTime(2026, 1, 2),
        birdCount: 20,
      ),
      throwsA(
        isA<DomainException>().having(
          (e) => e.message,
          'message',
          'This batch is closed, so no more harvests can be recorded.',
        ),
      ),
    );
  });

  test('refuses a Manager recording on a Staff-assigned batch', () async {
    // Proves two people never write the same batch's data, with the
    // exact message.
    await seedBatch(assignedStaffId: 'acc-1');
    await expectLater(
      domain(role: 'manager').recordHarvest(
        batchId: 'batch-1',
        date: DateTime(2026, 1, 2),
        birdCount: 20,
      ),
      throwsA(
        isA<DomainException>().having(
          (e) => e.message,
          'message',
          'This batch is assigned to a staff member. Only they can record '
              'entries.',
        ),
      ),
    );
  });

  test('refuses a harvest that would exceed the starting count', () async {
    // Proves the bird-count rule is applied before the write, with the
    // exact "Only N birds remain" message.
    await seedBatch(startingBirdCount: 100);
    await mortalityRepo.record(
      batchId: 'batch-1',
      recordedBy: 'acc-1',
      date: DateTime(2026, 1, 2),
      count: 90,
    );
    await expectLater(
      domain().recordHarvest(
        batchId: 'batch-1',
        date: DateTime(2026, 1, 3),
        birdCount: 11,
      ),
      throwsA(
        isA<DomainException>().having(
          (e) => e.message,
          'message',
          'Only 10 birds remain in this batch.',
        ),
      ),
    );
  });

  test('allows a harvest that lands exactly on the starting count', () async {
    // Proves the boundary is inclusive: 90 mortality + 10 harvest fits.
    await seedBatch(startingBirdCount: 100);
    await mortalityRepo.record(
      batchId: 'batch-1',
      recordedBy: 'acc-1',
      date: DateTime(2026, 1, 2),
      count: 90,
    );
    final harvest = await domain().recordHarvest(
      batchId: 'batch-1',
      date: DateTime(2026, 1, 3),
      birdCount: 10,
    );
    expect(harvest.birdCount, 10);
  });

  test('an unassigned batch stays recordable by the Manager', () async {
    // Proves the normal state between creating and assigning accepts a
    // Manager's harvest.
    await seedBatch(assignedStaffId: null);
    final harvest = await domain(role: 'manager').recordHarvest(
      batchId: 'batch-1',
      date: DateTime(2026, 1, 2),
      birdCount: 20,
    );
    expect(harvest.birdCount, 20);
  });
}
