import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/data/local/database.dart' show AppDatabase;
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/sale/sale_domain.dart';
import 'package:broiler_fms/repository/harvest/local_harvest_repository.dart';
import 'package:broiler_fms/repository/sale/local_sale_repository.dart';
import 'package:broiler_fms/repository/sale/remote_sale_repository.dart';

/// A RemoteSaleRepository that never talks to the network. The sale
/// write path under test never reads from it.
class _UnusedRemoteSale extends RemoteSaleRepository {
  _UnusedRemoteSale(super.client);
}

DynamicLibrary _openSqlite() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } on ArgumentError {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

/// Pricing a harvest, which a Manager does once. Proves each guard and
/// its exact message: the harvest must exist, must not already be
/// priced, and must match the sale_shape rule.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late LocalSaleRepository saleRepo;
  late LocalHarvestRepository harvestRepo;
  late SupabaseClient client;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    saleRepo = LocalSaleRepository(db);
    harvestRepo = LocalHarvestRepository(db);
    client = SupabaseClient('https://example.supabase.co', 'anon-key');
    addTearDown(client.dispose);
  });

  tearDown(() => db.close());

  SaleDomain domain() => SaleDomain(
        saleRepo: saleRepo,
        remoteSaleRepo: _UnusedRemoteSale(client),
        harvestRepo: harvestRepo,
        currentAccount: Account(
          accountId: 'acc-manager',
          businessId: 'biz-1',
          role: 'manager',
          name: 'Ada',
          email: 'ada@example.com',
          status: 'active',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

  test('prices a harvest and returns the sale', () async {
    // Proves the happy path writes a flat-total sale (use case:
    // Manager records what a harvest earned).
    final harvest = await harvestRepo.record(
      batchId: 'batch-1',
      recordedBy: 'acc-1',
      date: DateTime(2026, 1, 2),
      birdCount: 20,
    );
    final sale = await domain().recordSale(
      harvestId: harvest.harvestId,
      disposition: 'sale',
      amount: 32000,
      pricingMethod: 'flat_total',
      paymentStatus: 'paid',
    );
    expect(sale.amount, 32000);
    expect(await saleRepo.getByHarvest(harvest.harvestId), hasLength(1));
  });

  test('refuses a harvest that does not exist', () async {
    // Proves an unknown harvest is reported rather than written.
    await expectLater(
      domain().recordSale(
        harvestId: 'missing',
        disposition: 'sale',
        amount: 32000,
        pricingMethod: 'flat_total',
        paymentStatus: 'paid',
      ),
      throwsA(
        isA<DomainException>().having(
          (e) => e.message,
          'message',
          'This harvest could not be found.',
        ),
      ),
    );
  });

  test('refuses a harvest that already has a sale', () async {
    // Proves a harvest is priced exactly once, with the exact message.
    final harvest = await harvestRepo.record(
      batchId: 'batch-1',
      recordedBy: 'acc-1',
      date: DateTime(2026, 1, 2),
      birdCount: 20,
    );
    await domain().recordSale(
      harvestId: harvest.harvestId,
      disposition: 'sale',
      amount: 32000,
      pricingMethod: 'flat_total',
      paymentStatus: 'paid',
    );
    await expectLater(
      domain().recordSale(
        harvestId: harvest.harvestId,
        disposition: 'sale',
        amount: 32000,
        pricingMethod: 'flat_total',
        paymentStatus: 'paid',
      ),
      throwsA(
        isA<DomainException>().having(
          (e) => e.message,
          'message',
          'This harvest has already been priced.',
        ),
      ),
    );
  });

  test('refuses a sale shape the rule rejects', () async {
    // Proves the shape error from saleShapeError is surfaced verbatim.
    final harvest = await harvestRepo.record(
      batchId: 'batch-1',
      recordedBy: 'acc-1',
      date: DateTime(2026, 1, 2),
      birdCount: 20,
    );
    await expectLater(
      domain().recordSale(
        harvestId: harvest.harvestId,
        disposition: 'sale',
        amount: 32000,
        pricingMethod: 'flat_total',
        // paymentStatus missing on purpose.
      ),
      throwsA(
        isA<DomainException>().having(
          (e) => e.message,
          'message',
          'Choose whether the sale is paid or pending.',
        ),
      ),
    );
  });

  test('refuses a per_kg amount that does not match weight times price',
      () async {
    // Proves the amount must equal weight * price within one naira,
    // with the exact message.
    final harvest = await harvestRepo.record(
      batchId: 'batch-1',
      recordedBy: 'acc-1',
      date: DateTime(2026, 1, 2),
      birdCount: 20,
    );
    await expectLater(
      domain().recordSale(
        harvestId: harvest.harvestId,
        disposition: 'sale',
        amount: 9999,
        pricingMethod: 'per_kg',
        weightSold: 50,
        pricePerUnit: 100,
        paymentStatus: 'paid',
      ),
      throwsA(
        isA<DomainException>().having(
          (e) => e.message,
          'message',
          'The amount does not match the weight and price entered.',
        ),
      ),
    );
  });

  test('prices a gift_cull at zero with no other fields', () async {
    // Proves a giveaway is written as a priced harvest (use case:
    // Manager records birds given away or culled).
    final harvest = await harvestRepo.record(
      batchId: 'batch-1',
      recordedBy: 'acc-1',
      date: DateTime(2026, 1, 2),
      birdCount: 20,
    );
    final sale = await domain().recordSale(
      harvestId: harvest.harvestId,
      disposition: 'gift_cull',
      amount: 0,
    );
    expect(sale.amount, 0);
    expect(sale.disposition, 'gift_cull');
  });
}
