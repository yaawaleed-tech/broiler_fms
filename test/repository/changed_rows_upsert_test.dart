import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;

import 'package:broiler_fms/data/local/database.dart'
    show AccountsCompanion, AppDatabase, BusinessesCompanion;
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/domain/models/expense.dart';
import 'package:broiler_fms/domain/models/feed.dart';
import 'package:broiler_fms/domain/models/harvest.dart';
import 'package:broiler_fms/domain/models/mortality.dart';
import 'package:broiler_fms/domain/models/sale.dart';
import 'package:broiler_fms/domain/models/vaccination.dart';
import 'package:broiler_fms/domain/models/weight_sample.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/repository/expense/local_expense_repository.dart';
import 'package:broiler_fms/repository/feed/local_feed_repository.dart';
import 'package:broiler_fms/repository/harvest/local_harvest_repository.dart';
import 'package:broiler_fms/repository/mortality/local_mortality_repository.dart';
import 'package:broiler_fms/repository/sale/local_sale_repository.dart';
import 'package:broiler_fms/repository/vaccination/local_vaccination_repository.dart';
import 'package:broiler_fms/repository/weight/local_weight_repository.dart';

/// sqlite3_flutter_libs bundles the library into phone builds only, so
/// desktop tests open the system sqlite3. Top level because drift may open
/// the database from another isolate.
DynamicLibrary _openSqlite() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } on ArgumentError {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

/// Every pulled repository counts only the rows that are new or genuinely
/// different, so an unchanged pull reports nothing.
///
/// Each table gets the same six cases: a new row is written and counted, an
/// identical row is neither rewritten nor counted, a row with one changed
/// field is written and counted, a row still queued for push is skipped,
/// a mixed list counts only the changed ones, and the nullable and
/// numeric/date fields never make an identical row look changed.
///
/// The last group drives all eight tables through one pull and checks that
/// a second pull of the same data counts nothing at all.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late LocalSyncQueueRepository queue;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queue = LocalSyncQueueRepository(db);
  });

  tearDown(() => db.close());

  /// The parent rows every table points at.
  Future<void> seed() async {
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
            role: 'staff',
            name: 'Sam',
            email: 'sam@example.com',
          ),
        );
  }

  group('LocalBatchRepository.upsertAll', () {
    late LocalBatchRepository repo;

    setUp(() {
      repo = LocalBatchRepository(db);
    });

    Batch sample({String id = 'batch-1', String name = 'House 1'}) => Batch(
          batchId: id,
          businessId: 'biz-1',
          batchName: name,
          startingBirdCount: 100,
          startDate: DateTime(2026, 1, 1),
          isClosed: false,
          createdAt: DateTime(2026, 1, 1),
        );

    test('a row not present locally is written and counted', () async {
      await seed();
      expect(await repo.upsertAll([sample()]), 1);
      expect((await repo.getById('batch-1'))!.batchName, 'House 1');
    });

    test('an identical row is not counted', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(await repo.upsertAll([sample()]), 0,
          reason: 'nothing changed, so the second pull reports nothing');
    });

    test('a changed field is counted and applied', () async {
      await seed();
      await repo.upsertAll([sample()]);
      final changed = sample();
      expect(
        await repo.upsertAll([
          Batch(
            batchId: changed.batchId,
            businessId: changed.businessId,
            batchName: 'House 1 renamed',
            startingBirdCount: changed.startingBirdCount,
            startDate: changed.startDate,
            isClosed: changed.isClosed,
            createdAt: changed.createdAt,
          ),
        ]),
        1,
      );
      expect((await repo.getById('batch-1'))!.batchName, 'House 1 renamed');
    });

    test('a queued row is skipped and not counted', () async {
      await seed();
      final created = await repo.create(
        businessId: 'biz-1',
        batchName: 'House 1',
        startingBirdCount: 100,
        startDate: DateTime(2026, 1, 1),
      );
      expect(await queue.pendingCount(), 1);
      final written = await repo.upsertAll([
        Batch(
          batchId: created.batchId,
          businessId: 'biz-1',
          batchName: 'House 1',
          startingBirdCount: 100,
          startDate: created.startDate,
          isClosed: true,
          createdAt: created.createdAt,
        ),
      ]);
      expect(written, 0);
      expect((await repo.getById(created.batchId))!.isClosed, isFalse);
    });

    test('a mixed list counts only the new and the different', () async {
      await seed();
      await repo.upsertAll([sample()]);
      final renamed = sample();
      final written = await repo.upsertAll([
        sample(), // identical -> 0
        Batch(
          batchId: renamed.batchId,
          businessId: 'biz-1',
          batchName: 'Renamed',
          startingBirdCount: 100,
          startDate: renamed.startDate,
          isClosed: false,
          createdAt: renamed.createdAt,
        ), // different -> 1
        sample(id: 'batch-2', name: 'House 2'), // new -> 1
      ]);
      expect(written, 2);
    });

    test('joined name fields are not stored, so they never force a write',
        () async {
      await seed();
      final withNames = Batch(
        batchId: 'batch-1',
        businessId: 'biz-1',
        batchName: 'House 1',
        startingBirdCount: 100,
        startDate: DateTime(2026, 1, 1),
        isClosed: false,
        createdAt: DateTime(2026, 1, 1),
        assignedStaffId: 'acc-1',
        assignedStaffName: 'Sam',
        closedByName: 'Mia',
      );
      expect(await repo.upsertAll([withNames]), 1);
      // Second pull carries the same joined names. They are not local
      // columns, so they must not read as a difference.
      expect(await repo.upsertAll([withNames]), 0);
    });

    test('nullable fields and timestamps round-trip unchanged', () async {
      await seed();
      Batch row() => Batch(
            batchId: 'batch-1',
            businessId: 'biz-1',
            batchName: 'House 1',
            startingBirdCount: 100,
            // Sub-second precision: Drift truncates on write, so a naive
            // == would report a change on every pull.
            startDate: DateTime(2026, 1, 1, 8, 30, 15, 250),
            isClosed: false,
            createdAt: DateTime(2026, 1, 1, 8, 30, 15, 750),
            assignedStaffId: null,
            closedBy: null,
            breed: null,
            description: null,
            closedAt: null,
          );
      await repo.upsertAll([row()]);
      expect(await repo.upsertAll([row()]), 0);
    });
  });

  group('LocalMortalityRepository.upsertAll', () {
    late LocalMortalityRepository repo;
    setUp(() {
      repo = LocalMortalityRepository(db);
    });

    Mortality sample({
      String id = 'mort-1',
      int count = 3,
      String? description = 'heat',
    }) =>
        Mortality(
          mortalityId: id,
          batchId: 'batch-1',
          recordedBy: 'acc-1',
          date: DateTime(2026, 2, 1),
          count: count,
          recordedAt: DateTime(2026, 2, 1, 9, 0, 0, 123),
          description: description,
        );

    test('a row not present locally is written and counted', () async {
      await seed();
      expect(await repo.upsertAll([sample()]), 1);
      expect((await repo.getById('mort-1'))!.count, 3);
    });

    test('an identical row is not counted', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(await repo.upsertAll([sample()]), 0);
    });

    test('a changed field is counted and applied', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(await repo.upsertAll([sample(count: 9)]), 1);
      expect((await repo.getById('mort-1'))!.count, 9);
    });

    test('a nullable field moving off null is counted', () async {
      await seed();
      await repo.upsertAll([sample(description: null)]);
      expect(await repo.upsertAll([sample(description: 'note')]), 1);
      expect((await repo.getById('mort-1'))!.description, 'note');
      // And back again.
      expect(await repo.upsertAll([sample(description: null)]), 1);
    });

    test('a queued row is skipped and not counted', () async {
      await seed();
      final created = await repo.record(
        batchId: 'batch-1',
        recordedBy: 'acc-1',
        date: DateTime(2026, 1, 1),
        count: 4,
      );
      expect(
        await repo.upsertAll([
          Mortality(
            mortalityId: created.mortalityId,
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: DateTime(2026, 5, 1),
            count: 99,
            recordedAt: DateTime(2026, 5, 1),
          ),
        ]),
        0,
      );
      expect((await repo.getById(created.mortalityId))!.count, 4);
    });

    test('a mixed list counts only the new and the different', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(
        await repo.upsertAll([
          sample(),
          sample(count: 7),
          sample(id: 'mort-2', count: 1, description: 'new one'),
        ]),
        2,
      );
    });
  });

  group('LocalFeedRepository.upsertAll', () {
    late LocalFeedRepository repo;
    setUp(() {
      repo = LocalFeedRepository(db);
    });

    Feed sample({String id = 'feed-1', double quantity = 25}) => Feed(
          feedEntryId: id,
          batchId: 'batch-1',
          recordedBy: 'acc-1',
          date: DateTime(2026, 2, 1),
          quantity: quantity,
          recordedAt: DateTime(2026, 2, 1, 7, 15, 0, 999),
        );

    test('a row not present locally is written and counted', () async {
      await seed();
      expect(await repo.upsertAll([sample()]), 1);
      expect((await repo.getById('feed-1'))!.quantity, 25);
    });

    test('an identical row is not counted', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(await repo.upsertAll([sample()]), 0);
    });

    test('a changed field is counted and applied', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(await repo.upsertAll([sample(quantity: 30.5)]), 1);
      expect((await repo.getById('feed-1'))!.quantity, 30.5);
    });

    test('a queued row is skipped and not counted', () async {
      await seed();
      final created = await repo.record(
        batchId: 'batch-1',
        recordedBy: 'acc-1',
        date: DateTime(2026, 1, 1),
        quantity: 10,
      );
      expect(
        await repo.upsertAll([
          Feed(
            feedEntryId: created.feedEntryId,
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: DateTime(2026, 6, 1),
            quantity: 99,
            recordedAt: DateTime(2026, 6, 1),
          ),
        ]),
        0,
      );
      expect((await repo.getById(created.feedEntryId))!.quantity, 10);
    });

    test('a mixed list counts only the new and the different', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(
        await repo.upsertAll([
          sample(),
          sample(quantity: 40),
          sample(id: 'feed-2', quantity: 5),
        ]),
        2,
      );
    });

    test('a double never reads as different from itself', () async {
      await seed();
      for (final q in [42.5, 0.1, 1600.0, 0.30000000000000004]) {
        final row = Feed(
          feedEntryId: 'feed-$q',
          batchId: 'batch-1',
          recordedBy: 'acc-1',
          date: DateTime(2026, 2, 1),
          quantity: q,
          recordedAt: DateTime(2026, 2, 1),
        );
        expect(await repo.upsertAll([row]), 1, reason: 'first write of $q');
        expect(await repo.upsertAll([row]), 0, reason: 'identical $q');
      }
    });
  });

  group('LocalWeightRepository.upsertAll', () {
    late LocalWeightRepository repo;
    setUp(() {
      repo = LocalWeightRepository(db);
    });

    WeightSample sample({
      String id = 'wt-1',
      double weight = 18.4,
      int count = 32,
    }) =>
        WeightSample(
          weightSampleId: id,
          batchId: 'batch-1',
          recordedBy: 'acc-1',
          date: DateTime(2026, 2, 1),
          sampleWeight: weight,
          sampleCount: count,
          recordedAt: DateTime(2026, 2, 1, 6, 0, 0, 500),
        );

    test('a row not present locally is written and counted', () async {
      await seed();
      expect(await repo.upsertAll([sample()]), 1);
      expect((await repo.getById('wt-1'))!.sampleWeight, 18.4);
    });

    test('an identical row is not counted', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(await repo.upsertAll([sample()]), 0);
    });

    test('a changed field is counted and applied', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(await repo.upsertAll([sample(weight: 21.0)]), 1);
      expect((await repo.getById('wt-1'))!.sampleWeight, 21.0);
    });

    test('a queued row is skipped and not counted', () async {
      await seed();
      final created = await repo.record(
        batchId: 'batch-1',
        recordedBy: 'acc-1',
        date: DateTime(2026, 1, 1),
        sampleWeight: 10,
        sampleCount: 50,
      );
      expect(
        await repo.upsertAll([
          WeightSample(
            weightSampleId: created.weightSampleId,
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: DateTime(2026, 7, 1),
            sampleWeight: 99,
            sampleCount: 1,
            recordedAt: DateTime(2026, 7, 1),
          ),
        ]),
        0,
      );
      expect((await repo.getById(created.weightSampleId))!.sampleWeight, 10);
    });

    test('a mixed list counts only the new and the different', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(
        await repo.upsertAll([
          sample(),
          sample(count: 40),
          sample(id: 'wt-2', weight: 1.5),
        ]),
        2,
      );
    });
  });

  group('LocalVaccinationRepository.upsertAll', () {
    late LocalVaccinationRepository repo;
    setUp(() {
      repo = LocalVaccinationRepository(db);
    });

    Vaccination sample({String id = 'vac-1', String name = 'Gumboro'}) =>
        Vaccination(
          vaccinationId: id,
          batchId: 'batch-1',
          recordedBy: 'acc-1',
          date: DateTime(2026, 2, 1),
          vaccineName: name,
          recordedAt: DateTime(2026, 2, 1, 5, 30, 0, 750),
        );

    test('a row not present locally is written and counted', () async {
      await seed();
      expect(await repo.upsertAll([sample()]), 1);
      expect((await repo.getById('vac-1'))!.vaccineName, 'Gumboro');
    });

    test('an identical row is not counted', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(await repo.upsertAll([sample()]), 0);
    });

    test('a changed field is counted and applied', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(await repo.upsertAll([sample(name: 'Newcastle')]), 1);
      expect((await repo.getById('vac-1'))!.vaccineName, 'Newcastle');
    });

    test('a queued row is skipped and not counted', () async {
      await seed();
      final created = await repo.record(
        batchId: 'batch-1',
        recordedBy: 'acc-1',
        date: DateTime(2026, 1, 1),
        vaccineName: 'Old',
      );
      expect(
        await repo.upsertAll([
          Vaccination(
            vaccinationId: created.vaccinationId,
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: DateTime(2026, 8, 1),
            vaccineName: 'New',
            recordedAt: DateTime(2026, 8, 1),
          ),
        ]),
        0,
      );
      expect((await repo.getById(created.vaccinationId))!.vaccineName, 'Old');
    });

    test('a mixed list counts only the new and the different', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(
        await repo.upsertAll([
          sample(),
          sample(name: 'Boosters'),
          sample(id: 'vac-2', name: 'Other'),
        ]),
        2,
      );
    });
  });

  group('LocalHarvestRepository.upsertAll', () {
    late LocalHarvestRepository repo;
    setUp(() {
      repo = LocalHarvestRepository(db);
    });

    Harvest sample({String id = 'har-1', int birds = 30}) => Harvest(
          harvestId: id,
          batchId: 'batch-1',
          recordedBy: 'acc-1',
          date: DateTime(2026, 2, 1),
          birdCount: birds,
          recordedAt: DateTime(2026, 2, 1, 4, 20, 0, 250),
        );

    test('a row not present locally is written and counted', () async {
      await seed();
      expect(await repo.upsertAll([sample()]), 1);
      expect((await repo.getById('har-1'))!.birdCount, 30);
    });

    test('an identical row is not counted', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(await repo.upsertAll([sample()]), 0);
    });

    test('a changed field is counted and applied', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(await repo.upsertAll([sample(birds: 45)]), 1);
      expect((await repo.getById('har-1'))!.birdCount, 45);
    });

    test('a queued row is skipped and not counted', () async {
      await seed();
      final created = await repo.record(
        batchId: 'batch-1',
        recordedBy: 'acc-1',
        date: DateTime(2026, 1, 1),
        birdCount: 10,
      );
      expect(
        await repo.upsertAll([
          Harvest(
            harvestId: created.harvestId,
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: DateTime(2026, 9, 1),
            birdCount: 99,
            recordedAt: DateTime(2026, 9, 1),
          ),
        ]),
        0,
      );
      expect((await repo.getById(created.harvestId))!.birdCount, 10);
    });

    test('a mixed list counts only the new and the different', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(
        await repo.upsertAll([
          sample(),
          sample(birds: 35),
          sample(id: 'har-2', birds: 5),
        ]),
        2,
      );
    });
  });

  group('LocalExpenseRepository.upsertAll', () {
    late LocalExpenseRepository repo;
    setUp(() {
      repo = LocalExpenseRepository(db);
    });

    Expense sample({
      String id = 'exp-1',
      double amount = 42.5,
      double? quantity = 2,
      double? unitPrice = 5,
      String? feedType = 'starter',
      String? medicationName,
      String? description,
    }) =>
        Expense(
          expenseId: id,
          batchId: 'batch-1',
          recordedBy: 'acc-1',
          category: medicationName == null ? 'feed' : 'vet_medication',
          date: DateTime(2026, 2, 1),
          amount: amount,
          recordedAt: DateTime(2026, 2, 1, 3, 10, 0, 125),
          quantity: quantity,
          unitPrice: unitPrice,
          feedType: feedType,
          medicationName: medicationName,
          description: description,
        );

    test('a row not present locally is written and counted', () async {
      await seed();
      expect(await repo.upsertAll([sample()]), 1);
      expect((await repo.getById('exp-1'))!.amount, 42.5);
    });

    test('an identical row is not counted', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(await repo.upsertAll([sample()]), 0);
    });

    test('a changed field is counted and applied', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(await repo.upsertAll([sample(amount: 99.99)]), 1);
      expect((await repo.getById('exp-1'))!.amount, 99.99);
    });

    test('nullable and category-specific fields are all compared', () async {
      await seed();
      await repo.upsertAll([sample()]);
      // feed_type -> null
      expect(await repo.upsertAll([sample(feedType: null)]), 1);
      // unit_price -> null
      expect(await repo.upsertAll([sample(unitPrice: null)]), 1);
      // medication_name appears
      expect(await repo.upsertAll([sample(medicationName: 'Albex')]), 1);
      expect((await repo.getById('exp-1'))!.medicationName, 'Albex');
    });

    test('a queued row is skipped and not counted', () async {
      await seed();
      final created = await repo.record(
        batchId: 'batch-1',
        recordedBy: 'acc-1',
        category: 'feed',
        date: DateTime(2026, 1, 1),
        amount: 10,
      );
      expect(
        await repo.upsertAll([
          Expense(
            expenseId: created.expenseId,
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            category: 'feed',
            date: DateTime(2026, 9, 1),
            amount: 999,
            recordedAt: DateTime(2026, 9, 1),
          ),
        ]),
        0,
      );
      expect((await repo.getById(created.expenseId))!.amount, 10);
    });

    test('a mixed list counts only the new and the different', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(
        await repo.upsertAll([
          sample(),
          sample(amount: 50),
          sample(id: 'exp-2', amount: 5),
        ]),
        2,
      );
    });
  });

  group('LocalSaleRepository.upsertAll', () {
    late LocalSaleRepository repo;
    setUp(() {
      repo = LocalSaleRepository(db);
    });

    Sale sample({String id = 'sale-1', double amount = 250}) => Sale(
          saleId: id,
          harvestId: 'har-1',
          recordedBy: 'acc-1',
          disposition: 'sale',
          amount: amount,
          createdAt: DateTime(2026, 2, 1, 2, 0, 0, 625),
          buyerName: 'Local Buyer',
          pricingMethod: 'per_kg',
          weightSold: 125,
          pricePerUnit: 2,
          paymentStatus: 'paid',
        );

    test('a row not present locally is written and counted', () async {
      await seed();
      expect(await repo.upsertAll([sample()]), 1);
      expect((await repo.getById('sale-1'))!.amount, 250);
    });

    test('an identical row is not counted', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(await repo.upsertAll([sample()]), 0);
    });

    test('a changed field is counted and applied', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(await repo.upsertAll([sample(amount: 500)]), 1);
      expect((await repo.getById('sale-1'))!.amount, 500);
    });

    test('a nullable field moving is counted in both directions', () async {
      await seed();
      final without = Sale(
        saleId: 'sale-2',
        harvestId: 'har-1',
        recordedBy: 'acc-1',
        disposition: 'gift_cull',
        amount: 0,
        createdAt: DateTime(2026, 2, 1),
      );
      await repo.upsertAll([without]);
      expect(await repo.upsertAll([without]), 0);
      final withPayment = Sale(
        saleId: 'sale-2',
        harvestId: 'har-1',
        recordedBy: 'acc-1',
        disposition: 'sale',
        amount: 100,
        createdAt: DateTime(2026, 2, 1),
        pricingMethod: 'flat_total',
        pricePerUnit: 10,
        paymentStatus: 'pending',
      );
      expect(await repo.upsertAll([withPayment]), 1);
    });

    test('a queued row is skipped and not counted', () async {
      await seed();
      final created = await repo.record(
        harvestId: 'har-1',
        recordedBy: 'acc-1',
        disposition: 'sale',
        amount: 100,
        // sale_shape requires a payment status and a positive amount for
        // a real sale, so the fixture has to be a legal row.
        pricingMethod: 'flat_total',
        pricePerUnit: 10,
        paymentStatus: 'paid',
      );
      expect(
        await repo.upsertAll([
          Sale(
            saleId: created.saleId,
            harvestId: 'har-1',
            recordedBy: 'acc-1',
            disposition: 'sale',
            amount: 9999,
            createdAt: DateTime(2026, 9, 1),
          ),
        ]),
        0,
      );
      expect((await repo.getById(created.saleId))!.amount, 100);
    });

    test('a mixed list counts only the new and the different', () async {
      await seed();
      await repo.upsertAll([sample()]);
      expect(
        await repo.upsertAll([
          sample(),
          sample(amount: 750),
          sample(id: 'sale-2', amount: 10),
        ]),
        2,
      );
    });
  });

  group('pulling the same data twice', () {
    test('the second pull counts nothing on any table', () async {
      await seed();
      final batches = LocalBatchRepository(db);
      final mortality = LocalMortalityRepository(db);
      final feed = LocalFeedRepository(db);
      final weight = LocalWeightRepository(db);
      final vaccination = LocalVaccinationRepository(db);
      final harvest = LocalHarvestRepository(db);
      final expense = LocalExpenseRepository(db);
      final sale = LocalSaleRepository(db);

      // First pull: everything is new.
      final firstPass = <int>[
        await batches.upsertAll([
          Batch(
            batchId: 'batch-1',
            businessId: 'biz-1',
            batchName: 'House 1',
            startingBirdCount: 100,
            startDate: _day1,
            isClosed: false,
            createdAt: _day1,
          ),
        ]),
        await mortality.upsertAll([
          Mortality(
            mortalityId: 'mort-1',
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: _day2,
            count: 3,
            recordedAt: _day2,
            description: null,
          ),
        ]),
        await feed.upsertAll([
          Feed(
            feedEntryId: 'feed-1',
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: _day2,
            quantity: 25,
            recordedAt: _day2,
          ),
        ]),
        await weight.upsertAll([
          WeightSample(
            weightSampleId: 'wt-1',
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: _day2,
            sampleWeight: 18.4,
            sampleCount: 32,
            recordedAt: _day2,
          ),
        ]),
        await vaccination.upsertAll([
          Vaccination(
            vaccinationId: 'vac-1',
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: _day2,
            vaccineName: 'Gumboro',
            recordedAt: _day2,
          ),
        ]),
        await harvest.upsertAll([
          Harvest(
            harvestId: 'har-1',
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: _day2,
            birdCount: 30,
            recordedAt: _day2,
          ),
        ]),
        await expense.upsertAll([
          Expense(
            expenseId: 'exp-1',
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            category: 'feed',
            date: _day2,
            amount: 42.5,
            recordedAt: _day2,
          ),
        ]),
        await sale.upsertAll([
          Sale(
            saleId: 'sale-1',
            harvestId: 'har-1',
            recordedBy: 'acc-1',
            disposition: 'sale',
            amount: 250,
            createdAt: _day2,
            pricingMethod: 'per_kg',
            weightSold: 125,
            pricePerUnit: 2,
            paymentStatus: 'paid',
          ),
        ]),
      ];
      expect(firstPass, everyElement(1),
          reason: 'a first pull on an empty cache is all new');

      // Second pull, byte-for-byte the same data.
      final secondPass = <int>[
        await batches.upsertAll([
          Batch(
            batchId: 'batch-1',
            businessId: 'biz-1',
            batchName: 'House 1',
            startingBirdCount: 100,
            startDate: _day1,
            isClosed: false,
            createdAt: _day1,
          ),
        ]),
        await mortality.upsertAll([
          Mortality(
            mortalityId: 'mort-1',
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: _day2,
            count: 3,
            recordedAt: _day2,
            description: null,
          ),
        ]),
        await feed.upsertAll([
          Feed(
            feedEntryId: 'feed-1',
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: _day2,
            quantity: 25,
            recordedAt: _day2,
          ),
        ]),
        await weight.upsertAll([
          WeightSample(
            weightSampleId: 'wt-1',
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: _day2,
            sampleWeight: 18.4,
            sampleCount: 32,
            recordedAt: _day2,
          ),
        ]),
        await vaccination.upsertAll([
          Vaccination(
            vaccinationId: 'vac-1',
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: _day2,
            vaccineName: 'Gumboro',
            recordedAt: _day2,
          ),
        ]),
        await harvest.upsertAll([
          Harvest(
            harvestId: 'har-1',
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: _day2,
            birdCount: 30,
            recordedAt: _day2,
          ),
        ]),
        await expense.upsertAll([
          Expense(
            expenseId: 'exp-1',
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            category: 'feed',
            date: _day2,
            amount: 42.5,
            recordedAt: _day2,
          ),
        ]),
        await sale.upsertAll([
          Sale(
            saleId: 'sale-1',
            harvestId: 'har-1',
            recordedBy: 'acc-1',
            disposition: 'sale',
            amount: 250,
            createdAt: _day2,
            pricingMethod: 'per_kg',
            weightSold: 125,
            pricePerUnit: 2,
            paymentStatus: 'paid',
          ),
        ]),
      ];
      expect(secondPass, everyElement(0),
          reason: 'nothing changed on the server, so nothing is reported');
    });

    test('one real change is reported once and then goes quiet', () async {
      await seed();
      final mortality = LocalMortalityRepository(db);
      Mortality row(int count) => Mortality(
            mortalityId: 'mort-1',
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: _day2,
            count: count,
            recordedAt: _day2,
          );

      expect(await mortality.upsertAll([row(3)]), 1);
      expect(await mortality.upsertAll([row(3)]), 0);

      // The Manager/other device changes one row.
      expect(await mortality.upsertAll([row(5)]), 1);
      expect((await mortality.getById('mort-1'))!.count, 5);

      // And then it is quiet again.
      expect(await mortality.upsertAll([row(5)]), 0);
    });
  });
}

/// Shared timestamps: deliberately built with no sub-second component in one
/// place and with one in another, so both paths are exercised.
final _day1 = DateTime(2026, 1, 1);
final _day2 = DateTime(2026, 2, 1, 10, 30, 0, 640);