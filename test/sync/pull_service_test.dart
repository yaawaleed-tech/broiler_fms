import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/expense/expense_domain.dart';
import 'package:broiler_fms/domain/feed/feed_domain.dart';
import 'package:broiler_fms/domain/harvest/harvest_domain.dart';
import 'package:broiler_fms/domain/mortality/mortality_domain.dart';
import 'package:broiler_fms/domain/sale/sale_domain.dart';
import 'package:broiler_fms/domain/vaccination/vaccination_domain.dart';
import 'package:broiler_fms/domain/weight/weight_domain.dart';
import 'package:broiler_fms/sync/pull_service.dart';

/// A Domain stand-in that answers only its own refresh call, with
/// whatever rows or failure the test gave it. Everything else is left to
/// noSuchMethod, since PullService never touches anything but the eight
/// refresh methods.
class _FakeBatchDomain implements BatchDomain {
  _FakeBatchDomain(this.rows, {this.error});
  final int rows;
  final Object? error;

  @override
  Future<int> refreshBatches() async {
    if (error != null) throw error!;
    return rows;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeExpenseDomain implements ExpenseDomain {
  _FakeExpenseDomain(this.rows, {this.error});
  final int rows;
  final Object? error;

  @override
  Future<int> refreshExpenses() async {
    if (error != null) throw error!;
    return rows;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMortalityDomain implements MortalityDomain {
  _FakeMortalityDomain(this.rows, {this.error});
  final int rows;
  final Object? error;

  @override
  Future<int> refreshMortalityEntries() async {
    if (error != null) throw error!;
    return rows;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFeedDomain implements FeedDomain {
  _FakeFeedDomain(this.rows, {this.error});
  final int rows;
  final Object? error;

  @override
  Future<int> refreshFeedEntries() async {
    if (error != null) throw error!;
    return rows;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWeightDomain implements WeightDomain {
  _FakeWeightDomain(this.rows, {this.error});
  final int rows;
  final Object? error;

  @override
  Future<int> refreshWeightSamples() async {
    if (error != null) throw error!;
    return rows;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeVaccinationDomain implements VaccinationDomain {
  _FakeVaccinationDomain(this.rows, {this.error});
  final int rows;
  final Object? error;

  @override
  Future<int> refreshVaccinationEntries() async {
    if (error != null) throw error!;
    return rows;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHarvestDomain implements HarvestDomain {
  _FakeHarvestDomain(this.rows, {this.error});
  final int rows;
  final Object? error;

  @override
  Future<int> refreshHarvestEntries() async {
    if (error != null) throw error!;
    return rows;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSaleDomain implements SaleDomain {
  _FakeSaleDomain(this.rows, {this.error});
  final int rows;
  final Object? error;

  @override
  Future<int> refreshSales() async {
    if (error != null) throw error!;
    return rows;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  PullService serviceWith({
    int batches = 0,
    int expenses = 0,
    int mortality = 0,
    int feed = 0,
    int weight = 0,
    int vaccination = 0,
    int harvest = 0,
    int sales = 0,
    Object? failingTableError,
    String? failingTable,
  }) {
    Object? errFor(String table) =>
        failingTable == table ? failingTableError ?? 'boom' : null;

    return PullService(
      batches: _FakeBatchDomain(batches, error: errFor('batches')),
      expenses: _FakeExpenseDomain(expenses, error: errFor('expenses')),
      mortality: _FakeMortalityDomain(mortality,
          error: errFor('mortality_entries')),
      feed: _FakeFeedDomain(feed, error: errFor('feed_entries')),
      weight: _FakeWeightDomain(weight, error: errFor('weight_samples')),
      vaccination: _FakeVaccinationDomain(vaccination,
          error: errFor('vaccination_entries')),
      harvest: _FakeHarvestDomain(harvest, error: errFor('harvest_entries')),
      sales: _FakeSaleDomain(sales, error: errFor('sales')),
    );
  }

  group('PullService.pullAll', () {
    test('pulls every table and totals the rows written', () async {
      final result = await serviceWith(
        batches: 4,
        expenses: 2,
        mortality: 7,
        feed: 3,
        weight: 1,
        vaccination: 5,
        harvest: 2,
        sales: 6,
      ).pullAll();

      expect(result.updated, 30);
      expect(result.errors, isEmpty);
      expect(result.perTable, {
        'batches': 4,
        'expenses': 2,
        'mortality_entries': 7,
        'feed_entries': 3,
        'weight_samples': 1,
        'vaccination_entries': 5,
        'harvest_entries': 2,
        'sales': 6,
      });
      expect(result.isEmpty, isFalse);
    });

    test('one failing table does not stop the others, and never throws',
        () async {
      final result = await serviceWith(
        failingTable: 'mortality_entries',
        failingTableError: 'no network',
        batches: 3,
        sales: 4,
      ).pullAll();

      expect(result.errors, hasLength(1));
      expect(result.errors.single, contains('mortality_entries'));
      expect(result.errors.single, contains('no network'));
      expect(
        result.perTable.containsKey('mortality_entries'),
        isFalse,
        reason: 'a table that failed contributes no count',
      );
      expect(result.updated, 7, reason: 'the other tables still landed');
    });

    test('every table failing is reported, not thrown', () async {
      final result = await serviceWith(failingTable: 'batches').pullAll();

      // Only batches is wired to fail here, so exactly one error.
      expect(result.errors, hasLength(1));
      expect(result.updated, 0);
      expect(result.isEmpty, isFalse,
          reason: 'errors mean not-empty even when no rows landed');
    });

    test('an empty pull is empty', () async {
      final result = await serviceWith().pullAll();

      expect(result.updated, 0);
      expect(result.errors, isEmpty);
      expect(result.isEmpty, isTrue);
    });

    test('tablesPulled counts both the tables that landed and those that did not',
        () async {
      final result = await serviceWith(failingTable: 'mortality_entries').pullAll();

      expect(result.tablesPulled, 8, reason: 'every table was attempted');
      expect(result.perTable, hasLength(7));
      expect(result.errors, hasLength(1));
      expect(
        result.errors.length < result.tablesPulled,
        isTrue,
        reason: 'a partial failure must not read as a total one',
      );
    });
  });
}