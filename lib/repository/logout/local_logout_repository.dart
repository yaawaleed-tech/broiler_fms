import 'package:broiler_fms/data/local/database.dart' as local;
import 'package:broiler_fms/data/local/database_provider.dart';
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Everything this device stores locally, counted or wiped in one go,
/// used only by the mobile logout flow.
///
/// The eight tables in [deviceOwnedTables] are written by the phone
/// itself. The two cache tables (accounts, businesses) are copies of
/// server data and are wiped too, so the next person to sign in on this
/// phone cannot read the previous person's business or staff list.
class LocalLogoutRepository {
  LocalLogoutRepository(this._db);

  final local.AppDatabase _db;
  late final LocalSyncQueueRepository _syncQueueRepo =
      LocalSyncQueueRepository(_db);

  /// Tables whose rows are created on this device. Deliberately does
  /// not include `accounts` or `businesses`, those are downloads.
  static const deviceOwnedTables = [
    'batches',
    'expenses',
    'mortality_entries',
    'feed_entries',
    'weight_samples',
    'vaccination_entries',
    'harvest_entries',
    'sales',
  ];

  /// How many rows on this device are still waiting to reach Supabase.
  ///
  /// One number rather than a per-table breakdown: the confirmation
  /// dialog only needs to say how much would be lost. Read from the
  /// sync queue, so a row that has already been pushed does not count
  /// twice — and rows the server sent us never count at all.
  Future<int> countUnsyncedRows() => _syncQueueRepo.pendingCount();

  /// How many of those rows are still blocking logout: pending or
  /// failed, with rejected rows excluded. Rejected rows can never
  /// sync on their own, so they only ever warn — they never block.
  Future<int> countBlockingUnsyncedRows() => _syncQueueRepo.blockingCount();

  /// Deletes every row from every table, in one transaction.
  ///
  /// Children go first so the deletes stay inside the foreign keys:
  /// sales -> harvest entries -> the other entries -> batches ->
  /// accounts -> businesses.
  Future<void> clearAll() {
    return _db.transaction(() async {
      await _db.delete(_db.sales).go();
      await _db.delete(_db.harvestEntries).go();
      await _db.delete(_db.mortalityEntries).go();
      await _db.delete(_db.feedEntries).go();
      await _db.delete(_db.weightSamples).go();
      await _db.delete(_db.vaccinationEntries).go();
      await _db.delete(_db.expenses).go();
      await _db.delete(_db.batches).go();
      await _db.delete(_db.accounts).go();
      await _db.delete(_db.businesses).go();
    });
  }
}



/// Builds a [LocalLogoutRepository] wired to the shared Drift
/// database. Mobile only, never imported from anything the web build
/// can reach, same rule as [appDatabaseProvider] itself.
final localLogoutRepositoryProvider = Provider<LocalLogoutRepository>(
      (ref) => LocalLogoutRepository(ref.watch(appDatabaseProvider)),
);
