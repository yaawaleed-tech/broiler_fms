import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/expense/expense_domain.dart';
import 'package:broiler_fms/domain/feed/feed_domain.dart';
import 'package:broiler_fms/domain/harvest/harvest_domain.dart';
import 'package:broiler_fms/domain/mortality/mortality_domain.dart';
import 'package:broiler_fms/domain/sale/sale_domain.dart';
import 'package:broiler_fms/domain/vaccination/vaccination_domain.dart';
import 'package:broiler_fms/domain/weight/weight_domain.dart';

/// What one pull brought down, so the caller can report something the
/// person who tapped Sync can actually act on.
///
/// [updated] counts rows written into the local cache, not rows whose
/// values differed. The pull is a full-table fetch with no delta
/// support, so a row the server sends back identical to what is already
/// cached still counts here. It answers "how much data did I just take
/// from the server", not "how much changed".
///
/// [errors] carries one line per table that could not be pulled at all,
/// formatted `table: error`. A failure in one table never stops the
/// others, the same isolation the login pull has always had.
class PullResult {
  const PullResult({required this.perTable, required this.errors});

  final Map<String, int> perTable;
  final List<String> errors;

  /// Total rows written across every table.
  int get updated => perTable.values.fold(0, (sum, n) => sum + n);

  /// Every table this pull tried, whether it landed or failed. Lets the
  /// caller tell "nothing came back at all" apart from "one table was
  /// unreachable" without hard-coding how many tables there are.
  int get tablesPulled => perTable.length + errors.length;

  /// Nothing at all came down, and nothing failed either.
  bool get isEmpty => updated == 0 && errors.isEmpty;

  @override
  String toString() => 'PullResult(perTable: $perTable, errors: $errors)';
}

/// Pulls the latest data down from Supabase into the local Drift
/// cache, across every table this device caches.
///
/// This is the pull half of syncing, extracted out of the login callback
/// that used to inline it so that more than one caller can reach it: the
/// login path still runs it, and the mobile "Sync now" button runs it
/// on demand for Manager.
///
/// Which rows come back is decided entirely by RLS, per role. A Manager
/// gets every batch, entry, expense and sale for their own business,
/// which is what makes the pull worth having for them; a Staff account
/// gets only the batches it is assigned to, and nothing financial, so
/// the button deliberately does not offer Staff a pull at all.
///
/// Each table is pulled through its Domain class, exactly as the login
/// pull always has, so every path into the cache goes through the same
/// repositories and the same pending-row guard in their upsertAll().
class PullService {
  PullService({
    required BatchDomain batches,
    required ExpenseDomain expenses,
    required MortalityDomain mortality,
    required FeedDomain feed,
    required WeightDomain weight,
    required VaccinationDomain vaccination,
    required HarvestDomain harvest,
    required SaleDomain sales,
  })  : _batches = batches,
        _expenses = expenses,
        _mortality = mortality,
        _feed = feed,
        _weight = weight,
        _vaccination = vaccination,
        _harvest = harvest,
        _sales = sales;

  final BatchDomain _batches;
  final ExpenseDomain _expenses;
  final MortalityDomain _mortality;
  final FeedDomain _feed;
  final WeightDomain _weight;
  final VaccinationDomain _vaccination;
  final HarvestDomain _harvest;
  final SaleDomain _sales;

  /// Pulls every cached table, one after another.
  ///
  /// Never throws: a table that fails records its error and the pull
  /// carries on, so one unreachable table cannot cost the other seven.
  /// Awaited sequentially rather than concurrently so the counts come
  /// back in a stable order and one connection's worth of load is all
  /// that is ever in flight at a time.
  ///
  /// Does not push anything. Pair it with a drain when the caller
  /// wants both directions, and drain first: a pull must never land on
  /// a row a push is still trying to send.
  Future<PullResult> pullAll() async {
    final perTable = <String, int>{};
    final errors = <String>[];

    Future<void> pullOne(String table, Future<int> Function() pull) async {
      try {
        perTable[table] = await pull();
      } catch (e) {
        errors.add('$table: $e');
      }
    }

    await pullOne('batches', _batches.refreshBatches);
    await pullOne('expenses', _expenses.refreshExpenses);
    await pullOne('mortality_entries', _mortality.refreshMortalityEntries);
    await pullOne('feed_entries', _feed.refreshFeedEntries);
    await pullOne('weight_samples', _weight.refreshWeightSamples);
    await pullOne('vaccination_entries', _vaccination.refreshVaccinationEntries);
    await pullOne('harvest_entries', _harvest.refreshHarvestEntries);
    await pullOne('sales', _sales.refreshSales);

    return PullResult(perTable: perTable, errors: errors);
  }
}

/// Builds a [PullService] wired to the mobile Domain classes.
///
/// Mobile only, same rule as every local-only provider: it reaches the
/// Drift-backed repositories, so it must never be imported from
/// anything the web build can reach.
final pullServiceProvider = Provider<PullService>((ref) {
  return PullService(
    batches: ref.watch(batchDomainProvider),
    expenses: ref.watch(expenseDomainProvider),
    mortality: ref.watch(mortalityDomainProvider),
    feed: ref.watch(feedDomainProvider),
    weight: ref.watch(weightDomainProvider),
    vaccination: ref.watch(vaccinationDomainProvider),
    harvest: ref.watch(harvestDomainProvider),
    sales: ref.watch(saleDomainProvider),
  );
});