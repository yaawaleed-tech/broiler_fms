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
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/mortality/mortality_domain.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/repository/harvest/local_harvest_repository.dart';
import 'package:broiler_fms/repository/mortality/local_mortality_repository.dart';
import 'package:broiler_fms/repository/mortality/remote_mortality_repository.dart';

/// A RemoteMortalityRepository that never talks to the network. The
/// mortality write path under test never reads from it.
class _UnusedRemoteMortality extends RemoteMortalityRepository {
  _UnusedRemoteMortality(super.client);
}

DynamicLibrary _openSqlite() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } on ArgumentError {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

/// The Domain-layer guards on recording mortality, the mirror of
/// harvest: the batch must be open, owned by the caller, and the count
/// must still fit. Proves the exact messages Staff sees.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late LocalMortalityRepository mortalityRepo;
  late LocalHarvestRepository harvestRepo;
  late LocalBatchRepository batchRepo;
  late SupabaseClient client;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mortalityRepo = LocalMortalityRepository(db);
    harvestRepo = LocalHarvestRepository(db);
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

  MortalityDomain domain({String role = 'staff'}) => MortalityDomain(
        mortalityRepo: mortalityRepo,
        remoteMortalityRepo: _UnusedRemoteMortality(client),
        batchRepo: batchRepo,
        harvestRepo: harvestRepo,
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

  test('records mortality when the batch is open and assigned', () async {
    // Proves the happy path writes and carries the description (use
    // case: Staff records 5 deaths with a note).
    await seedBatch();
    final mortality = await domain().recordMortality(
      batchId: 'batch-1',
      date: DateTime(2026, 1, 2),
      count: 5,
      description: 'Heat',
    );
    expect(mortality.count, 5);
    expect(mortality.description, 'Heat');
    expect(await mortalityRepo.getByBatch('batch-1'), hasLength(1));
  });

  test('refuses when the batch could not be found', () async {
    // Proves a missing batch is reported rather than written.
    await seedBatch();
    await expectLater(
      domain().recordMortality(
        batchId: 'missing',
        date: DateTime(2026, 1, 2),
        count: 5,
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
    // Proves a closed batch accepts no more mortality, with the exact
    // message.
    await seedBatch(isClosed: true);
    await expectLater(
      domain().recordMortality(
        batchId: 'batch-1',
        date: DateTime(2026, 1, 2),
        count: 5,
      ),
      throwsA(
        isA<DomainException>().having(
          (e) => e.message,
          'message',
          'This batch is closed, so no more mortality can be recorded.',
        ),
      ),
    );
  });

  test('refuses a Manager recording on a Staff-assigned batch', () async {
    // Proves two people never write the same batch's data, with the
    // exact message.
    await seedBatch(assignedStaffId: 'acc-1');
    await expectLater(
      domain(role: 'manager').recordMortality(
        batchId: 'batch-1',
        date: DateTime(2026, 1, 2),
        count: 5,
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

  test('refuses a count that would exceed the starting count', () async {
    // Proves the bird-count rule is applied before the write, with the
    // exact "Only N birds remain" message.
    await seedBatch(startingBirdCount: 100);
    await harvestRepo.record(
      batchId: 'batch-1',
      recordedBy: 'acc-1',
      date: DateTime(2026, 1, 2),
      birdCount: 95,
    );
    await expectLater(
      domain().recordMortality(
        batchId: 'batch-1',
        date: DateTime(2026, 1, 3),
        count: 6,
      ),
      throwsA(
        isA<DomainException>().having(
          (e) => e.message,
          'message',
          'Only 5 birds remain in this batch.',
        ),
      ),
    );
  });

  test('allows a count that lands exactly on the starting count', () async {
    // Proves the boundary is inclusive: 95 harvested + 5 deaths fits.
    await seedBatch(startingBirdCount: 100);
    await harvestRepo.record(
      batchId: 'batch-1',
      recordedBy: 'acc-1',
      date: DateTime(2026, 1, 2),
      birdCount: 95,
    );
    final mortality = await domain().recordMortality(
      batchId: 'batch-1',
      date: DateTime(2026, 1, 3),
      count: 5,
    );
    expect(mortality.count, 5);
  });

  test('an unassigned batch stays recordable by the Manager', () async {
    // Proves the normal state between creating and assigning accepts a
    // Manager's mortality.
    await seedBatch(assignedStaffId: null);
    final mortality = await domain(role: 'manager').recordMortality(
      batchId: 'batch-1',
      date: DateTime(2026, 1, 2),
      count: 5,
    );
    expect(mortality.count, 5);
  });
}
