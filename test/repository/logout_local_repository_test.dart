import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/data/local/database.dart';
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/domain/logout_domain.dart';
import 'package:broiler_fms/sync/pushers/entity_pusher.dart';
import 'package:broiler_fms/sync/sync_result.dart';
import 'package:broiler_fms/sync/sync_service.dart';
import 'package:broiler_fms/repository/logout/local_logout_repository.dart';

/// sqlite3_flutter_libs bundles the library into phone builds only,
/// so desktop tests open the system sqlite3. Prefer the normal soname,
/// fall back to the versioned one for machines that have no unversioned
/// development symlink. Top level because drift may open the database
/// from another isolate.
DynamicLibrary _openSqlite() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } on ArgumentError {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

/// Covers the two halves of mobile logout that can be checked without
/// a device: counting what only exists locally, and wiping every
/// table afterwards.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late LocalLogoutRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalLogoutRepository(db);
  });

  tearDown(() => db.close());

  /// One business, one staff account, one batch and one mortality
  /// entry — the shape a phone ends up with after someone logs in and
  /// records something offline.
  Future<void> seed() async {
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
            batchId: 'batch-1',
            businessId: 'biz-1',
            batchName: 'House 1',
            startingBirdCount: 100,
            startDate: DateTime(2026, 1, 1),
          ),
        );
    await db.into(db.mortalityEntries).insert(
          MortalityEntriesCompanion.insert(
            mortalityId: 'mor-1',
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            date: DateTime(2026, 1, 2),
            count: 3,
          ),
        );
  }

  Future<int> rowsIn(String table) async {
    final row = await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle();
    return row.read<int>('n');
  }

  group('LocalLogoutRepository', () {
    test('counts zero unsynced rows on an empty device', () async {
      expect(await repo.countUnsyncedRows(), 0);
    });

    test('counts what is queued, not every local row', () async {
      await seed();
      // Seeding writes straight through Drift, the way a download from
      // Supabase does, so nothing of the batch or the mortality entry
      // is queued yet — and accounts and businesses never queue at all.
      expect(await repo.countUnsyncedRows(), 0);

      final queue = LocalSyncQueueRepository(db);
      await queue.enqueue(
        entityTable: 'batches',
        recordId: 'batch-1',
        operation: 'insert',
      );
      await queue.enqueue(
        entityTable: 'mortality_entries',
        recordId: 'mor-1',
        operation: 'insert',
      );
      expect(await repo.countUnsyncedRows(), 2);

      // The rows themselves are still there; only the queue decides
      // the count.
      expect(await rowsIn('batches'), 1);
      expect(await rowsIn('mortality_entries'), 1);
    });

    test('clearAll empties every table, parents last', () async {
      await seed();
      await repo.clearAll();

      for (final table in [
        ...LocalLogoutRepository.deviceOwnedTables,
        'accounts',
        'businesses',
      ]) {
        expect(await rowsIn(table), 0, reason: '$table should be empty');
      }
      expect(await repo.countUnsyncedRows(), 0);
    });
  });

  group('LocalSyncQueueRepository.blockingCount', () {
    test('counts pending and failed rows but never rejected ones', () async {
      await seed();
      final queue = LocalSyncQueueRepository(db);
      await queue.enqueue(
        entityTable: 'batches',
        recordId: 'batch-1',
        operation: 'insert',
      );
      await queue.enqueue(
        entityTable: 'mortality_entries',
        recordId: 'mor-1',
        operation: 'insert',
      );

      expect(await queue.blockingCount(), 2);
      expect(await queue.pendingCount(), 2);

      // The server refused the mortality row for good (the bird-count
      // trigger): it can never sync, so it stops blocking logout —
      // but stays in the informational total.
      final rows = await db.select(db.syncQueue).get();
      final rejectedRow =
          rows.firstWhere((r) => r.entityTable == 'mortality_entries');
      await queue.markRejected(rejectedRow.id, 'mortality plus harvested');

      expect(await queue.blockingCount(), 1,
          reason: 'a rejected row can never resolve, so it must not block');
      expect(await queue.pendingCount(), 2,
          reason: 'the informational count still warns about it');
    });
  });

  group('LogoutDomain', () {
    test('signs out and wipes the device', () async {
      await seed();
      final client = SupabaseClient('https://example.supabase.co', 'anon-key');
      addTearDown(client.dispose);

      final domain = LogoutDomain(supabase: client, localLogoutRepo: repo);

      // No session on this client, so nothing reaches the network and
      // there is nothing to warn about.
      expect(await domain.logOut(), isNull);
      expect(await repo.countUnsyncedRows(), 0);
      expect(await rowsIn('accounts'), 0);
      expect(await rowsIn('businesses'), 0);
    });

    test('drainAndCountUnsyncedRows drains first, so the dialog gets the true number', () async {
      await seed();
      final queue = LocalSyncQueueRepository(db);
      await queue.enqueue(
        entityTable: 'batches',
        recordId: 'batch-1',
        operation: 'insert',
      );
      await queue.enqueue(
        entityTable: 'mortality_entries',
        recordId: 'mor-1',
        operation: 'insert',
      );
      final client = SupabaseClient('https://example.supabase.co', 'anon-key');
      addTearDown(client.dispose);

      final domain = LogoutDomain(
        supabase: client,
        localLogoutRepo: repo,
        syncService: SyncService(
          queue: queue,
          client: client,
          pushers: [_InstantSuccessPusher('batches'), _InstantSuccessPusher('mortality_entries')],
        ),
      );

      expect(await domain.drainAndCountUnsyncedRows(),
          (total: 0, blocking: 0),
          reason: 'drain cleared the queue, so logout is unblocked and the '
              'confirmation says nothing about lost work');
    });

    test('drainAndCountUnsyncedRows counts whatever the drain could not clear', () async {
      await seed();
      final queue = LocalSyncQueueRepository(db);
      await queue.enqueue(
        entityTable: 'batches',
        recordId: 'batch-1',
        operation: 'insert',
      );
      final client = SupabaseClient('https://example.supabase.co', 'anon-key');
      addTearDown(client.dispose);

      final domain = LogoutDomain(
        supabase: client,
        localLogoutRepo: repo,
        // No pushers registered: every row stays failed, count stays 1.
        syncService: SyncService(queue: queue, client: client, pushers: const []),
      );

      expect(await domain.drainAndCountUnsyncedRows(), (total: 1, blocking: 1),
          reason: 'the row never synced and was not rejected, so it blocks');
    });

    test('drainAndCountUnsyncedRows warns about rejected rows without blocking',
        () async {
      await seed();
      final queue = LocalSyncQueueRepository(db);
      await queue.enqueue(
        entityTable: 'batches',
        recordId: 'batch-1',
        operation: 'insert',
      );
      await queue.enqueue(
        entityTable: 'mortality_entries',
        recordId: 'mor-1',
        operation: 'insert',
      );
      // The bird-count trigger refused the mortality row: it can never
      // succeed, so it must not hard-block logout — only be counted.
      final rows = await db.select(db.syncQueue).get();
      final rejectedRow =
          rows.firstWhere((r) => r.entityTable == 'mortality_entries');
      await queue.markRejected(rejectedRow.id, 'mortality plus harvested');

      final client = SupabaseClient('https://example.supabase.co', 'anon-key');
      addTearDown(client.dispose);

      final domain = LogoutDomain(
        supabase: client,
        localLogoutRepo: repo,
        // No pushers: the pending batch row survives the drain, and
        // the rejected row is never retried in the first place.
        syncService:
            SyncService(queue: queue, client: client, pushers: const []),
      );

      expect(await domain.drainAndCountUnsyncedRows(), (total: 2, blocking: 1),
          reason: 'rejected rows stay in the total but never block; the '
              'still-pending batch row does block');
    });
  });
}

/// Test pusher that succeeds instantly, so the service clears every
/// queue row it is given — simulates a drain with perfect connectivity.
class _InstantSuccessPusher extends EntityPusher {
  _InstantSuccessPusher(this.entityTable);

  @override
  final String entityTable;

  @override
  Future<SyncPushResult> push(SyncQueueData row, SupabaseClient client) async =>
      const SyncPushSuccess();
}
