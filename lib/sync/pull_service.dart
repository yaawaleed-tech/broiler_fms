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
/// [updated] counts rows that were genuinely new or different — the
/// repositories only write and count a row whose stored values differ from
/// the server's copy, so a pull that changes nothing reports zero rather
/// than re-reporting everything it read. The pull itself is still a
/// full-table fetch with no delta support; this just stops an unchanged
/// row counting as news each time.
///
/// [errors] carries one line per table that could not be pulled at all,
/// formatted `table: error`. A failure in one table never stops the
/// others, the same isolation the login pull has always had.
class PullResult {
  const PullResult({required this.perTable, required this.errors});

  final Map<String, int> perTable;
  final List<String> errors;

  /// Total rows that were new or different, across every table.
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
/// Which rows come back is decided entirely by RLS, per role, so this
/// class has no role logic of its own and every role may pull. A Manager
/// gets every batch, entry, expense and sale for their own business; a
/// Staff account gets only the batches it is assigned to and nothing
/// financial. Row Level Security is what narrows the result.
///
/// Each table is pulled through its Domain class, exactly as the login
/// pull always has, so every path into the cache goes through the same
/// repositories, the same pending-row guard in their upsertAll(), and the
/// same change detection: a row already cached unchanged is neither
/// rewritten nor counted.
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
  }) : this._lazy(
          batches: () => batches,
          expenses: () => expenses,
          mortality: () => mortality,
          feed: () => feed,
          weight: () => weight,
          vaccination: () => vaccination,
          harvest: () => harvest,
          sales: () => sales,
        );

  /// Takes the Domains as thunks rather than values, so the caller can
  /// decide *when* they are built.
  ///
  /// Private because the eight-Domain constructor above is the one every
  /// other caller should use; this exists for [pullServiceProvider],
  /// which must be safe to create before anybody has signed in.
  PullService._lazy({
    required BatchDomain Function() batches,
    required ExpenseDomain Function() expenses,
    required MortalityDomain Function() mortality,
    required FeedDomain Function() feed,
    required WeightDomain Function() weight,
    required VaccinationDomain Function() vaccination,
    required HarvestDomain Function() harvest,
    required SaleDomain Function() sales,
  })  : _batches = batches,
        _expenses = expenses,
        _mortality = mortality,
        _feed = feed,
        _weight = weight,
        _vaccination = vaccination,
        _harvest = harvest,
        _sales = sales;

  /// The run in flight, if any, so callers that arrive together share one
  /// pull instead of each starting their own. Cleared when that run
  /// completes, whether it succeeded or not.
  Future<PullResult>? _active;

  /// True while a pull is running.
  bool get isPulling => _active != null;

  // Resolved per table, immediately before it is used, so building a
  // PullService never needs an account. See [pullServiceProvider].
  final BatchDomain Function() _batches;
  final ExpenseDomain Function() _expenses;
  final MortalityDomain Function() _mortality;
  final FeedDomain Function() _feed;
  final WeightDomain Function() _weight;
  final VaccinationDomain Function() _vaccination;
  final HarvestDomain Function() _harvest;
  final SaleDomain Function() _sales;

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
  ///
  /// Single-flight, the same way [SyncService.drain] is: a call made while
  /// a pull is already running joins that run and receives its result
  /// rather than starting a second one. Two pulls at once would fetch
  /// every table twice and write the same rows twice. Mirrors
  /// `return _active ??= _pullAll().whenComplete(() => _active = null);`
  /// in `sync_service.dart`.
  Future<PullResult> pullAll() {
    return _active ??= _pullAll().whenComplete(() => _active = null);
  }

  Future<PullResult> _pullAll() async {
    final perTable = <String, int>{};
    final errors = <String>[];

    Future<void> pullOne(String table, Future<int> Function() pull) async {
      try {
        perTable[table] = await pull();
      } catch (e) {
        errors.add('$table: $e');
      }
    }

    // Each Domain is resolved inside its own pullOne, so resolving it is
    // covered by the same catch as the fetch. Otherwise a provider that
    // has no account would throw on the spot and break the "never throws"
    // contract above, instead of being reported like any other failure.
    await pullOne('batches', () => _batches().refreshBatches());
    await pullOne('expenses', () => _expenses().refreshExpenses());
    await pullOne(
      'mortality_entries',
      () => _mortality().refreshMortalityEntries(),
    );
    await pullOne('feed_entries', () => _feed().refreshFeedEntries());
    await pullOne('weight_samples', () => _weight().refreshWeightSamples());
    await pullOne(
      'vaccination_entries',
      () => _vaccination().refreshVaccinationEntries(),
    );
    await pullOne('harvest_entries', () => _harvest().refreshHarvestEntries());
    await pullOne('sales', () => _sales().refreshSales());

    return PullResult(perTable: perTable, errors: errors);
  }
}

/// Builds a [PullService] wired to the mobile Domain classes.
///
/// Mobile only, same rule as every local-only provider: it reaches the
/// Drift-backed repositories, so it must never be imported from
/// anything the web build can reach.
///
/// Every Domain it needs is bound to a signed-in account, and this
/// provider is read at app start, before anybody has signed in. So none
/// of them is built here: each is read inside the pull that needs it,
/// which is the first moment an account can be guaranteed. Reading the
/// provider — which the app's root widget does on every cold start,
/// signed in or not — therefore never throws, and the "No account is
/// currently signed in" error stays exactly where it belongs: on the
/// pull that actually needs an account.
final pullServiceProvider = Provider<PullService>((ref) {
  return PullService._lazy(
    batches: () => ref.read(batchDomainProvider),
    expenses: () => ref.read(expenseDomainProvider),
    mortality: () => ref.read(mortalityDomainProvider),
    feed: () => ref.read(feedDomainProvider),
    weight: () => ref.read(weightDomainProvider),
    vaccination: () => ref.read(vaccinationDomainProvider),
    harvest: () => ref.read(harvestDomainProvider),
    sales: () => ref.read(saleDomainProvider),
  );
});