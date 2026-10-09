import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
// Prefixed: Supabase's storage_client exports a TableUpdate of its own.
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/data/local/database.dart';
import 'package:broiler_fms/data/local/database_provider.dart';
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/sync/sync_providers.dart';
import 'package:broiler_fms/sync/sync_result.dart';
import 'package:broiler_fms/sync/sync_service.dart';
import 'package:broiler_fms/sync/triggers/connectivity_sync_trigger.dart';
import 'package:broiler_fms/sync/triggers/lifecycle_sync_trigger.dart';

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

/// A sync service that only counts how often it was asked to drain —
/// the triggers under test care about *when* drain runs, not what it
/// pushes.
class _CountingSyncService extends SyncService {
  _CountingSyncService({
    required super.queue,
    required super.client,
    required super.pushers,
  });

  int drains = 0;

  @override
  Future<SyncResult> drain() {
    drains++;
    return super.drain();
  }
}

/// Stands in for the plugin's event stream, which no unit test can
/// reach: the trigger only ever reads `onConnectivityChanged`.
class _FakeConnectivity extends Fake implements Connectivity {
  final _changes = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _changes.stream;

  void emit(List<ConnectivityResult> results) => _changes.add(results);

  Future<void> close() => _changes.close();
}

/// The three automatic triggers: connectivity, the debounced write
/// trigger, and the queue-table listener that feeds it.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late LocalSyncQueueRepository queue;
  late SupabaseClient client;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queue = LocalSyncQueueRepository(db);
    client = SupabaseClient('https://example.supabase.co', 'anon-key');
    addTearDown(client.dispose);
  });

  tearDown(() => db.close());

  _CountingSyncService countingService() =>
      _CountingSyncService(queue: queue, client: client, pushers: const []);

  group('LifecycleSyncTrigger', () {
    test('a burst of writes collapses into a single drain', () async {
      final service = countingService();
      final trigger = LifecycleSyncTrigger(
        service,
        debounce: const Duration(milliseconds: 50),
      );
      addTearDown(trigger.dispose);

      trigger.scheduleDrain();
      trigger.scheduleDrain();
      trigger.scheduleDrain();
      expect(service.drains, 0, reason: 'nothing drains mid-burst');

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(service.drains, 1);
    });

    test('disposing cancels a drain that has not fired yet', () async {
      final service = countingService();
      final trigger = LifecycleSyncTrigger(
        service,
        debounce: const Duration(milliseconds: 50),
      );

      trigger.scheduleDrain();
      trigger.dispose();

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(service.drains, 0);
    });
  });

  group('ConnectivitySyncTrigger', () {
    test('drains on coming online, never on dropping offline', () async {
      final fake = _FakeConnectivity();
      addTearDown(fake.close);
      final service = countingService();
      final trigger = ConnectivitySyncTrigger(service, connectivity: fake);
      addTearDown(trigger.dispose);

      trigger.start();
      fake.emit([ConnectivityResult.wifi]);
      await pumpEventQueue();
      expect(service.drains, 1);

      fake.emit([ConnectivityResult.none]);
      await pumpEventQueue();
      expect(service.drains, 1, reason: 'going offline drains nothing');

      fake.emit([ConnectivityResult.mobile, ConnectivityResult.vpn]);
      await pumpEventQueue();
      expect(service.drains, 2);
    });

    test('stops listening once disposed', () async {
      final fake = _FakeConnectivity();
      addTearDown(fake.close);
      final service = countingService();
      final trigger = ConnectivitySyncTrigger(service, connectivity: fake);

      trigger.start();
      trigger.dispose();

      fake.emit([ConnectivityResult.wifi]);
      await pumpEventQueue();
      expect(service.drains, 0);
    });
  });

  group('queue-table listener', () {
    test('sees the inserts enqueue writes, not the engine’s own edits',
        () async {
      final events = <drift.TableUpdate>[];
      final subscription = db
          .tableUpdates(
            drift.TableUpdateQuery.onTable(
              db.syncQueue,
              limitUpdateKind: drift.UpdateKind.insert,
            ),
          )
          .listen((updates) => events.addAll(updates));
      addTearDown(subscription.cancel);

      await queue.enqueue(
        entityTable: 'batches',
        recordId: 'batch-1',
        operation: 'insert',
      );
      await queue.enqueue(
        entityTable: 'expenses',
        recordId: 'exp-1',
        operation: 'insert',
      );
      final rows = await queue.pendingRows();
      await queue.markSynced(rows[0].id); // delete
      await queue.markFailed(rows[1].id, 'network is down'); // update
      await pumpEventQueue();

      expect(events, hasLength(2),
          reason: 'two enqueues, and neither of the engine’s own '
              'bookkeeping writes should schedule a drain');
      expect(events.map((e) => e.kind).toSet(), {drift.UpdateKind.insert});
    });

    test('an enqueue reaches a debounced drain through its provider',
        () async {
      final service = countingService();
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          syncServiceProvider.overrideWithValue(service),
          syncDrainDebounceProvider
              .overrideWithValue(const Duration(milliseconds: 50)),
        ],
      );
      addTearDown(container.dispose);

      // Reading the provider is what attaches the listener — in the
      // app, the root widget's ref.watch() does it.
      container.read(lifecycleSyncTriggerProvider);

      await queue.enqueue(
        entityTable: 'batches',
        recordId: 'batch-1',
        operation: 'insert',
      );
      await queue.enqueue(
        entityTable: 'batches',
        recordId: 'batch-2',
        operation: 'insert',
      );
      expect(service.drains, 0);

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(service.drains, 1,
          reason: 'both writes should collapse into one drain');

      // That drain fails both rows (no pusher is registered here), and
      // those failure writes must not schedule the next one.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(service.drains, 1);
    });
  });
}
