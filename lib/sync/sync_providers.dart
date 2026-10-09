import 'package:drift/drift.dart' show TableUpdateQuery, UpdateKind;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/local/database_provider.dart';
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/data/remote/supabase_provider.dart';

import 'pushers/batch_pusher.dart';
import 'pushers/entity_pusher.dart';
import 'pushers/expense_pusher.dart';
import 'pushers/feed_pusher.dart';
import 'pushers/harvest_pusher.dart';
import 'pushers/mortality_pusher.dart';
import 'pushers/sale_pusher.dart';
import 'pushers/vaccination_pusher.dart';
import 'pushers/weight_pusher.dart';
import 'sync_service.dart';
import 'triggers/connectivity_sync_trigger.dart';
import 'triggers/lifecycle_sync_trigger.dart';

/// Every pusher the engine knows about — one per syncable table,
/// listed in [SyncService.pushOrder].
final entityPushersProvider = Provider<List<EntityPusher>>((ref) => [
      ref.watch(batchPusherProvider),
      ref.watch(expensePusherProvider),
      ref.watch(mortalityPusherProvider),
      ref.watch(feedPusherProvider),
      ref.watch(weightPusherProvider),
      ref.watch(vaccinationPusherProvider),
      ref.watch(harvestPusherProvider),
      ref.watch(salePusherProvider),
    ]);

/// The one sync engine for this device: the queue it drains, the
/// Supabase client it drains to, and the pushers that do the work.
///
/// Mobile only, same rule as every other local-only provider, never
/// imported from anything the web build can reach.
final syncServiceProvider = Provider<SyncService>(
      (ref) => SyncService(
        queue: ref.watch(localSyncQueueRepositoryProvider),
        client: ref.watch(supabaseClientProvider),
        pushers: ref.watch(entityPushersProvider),
      ),
);

/// How long local writes are allowed to batch up before one drain runs.
///
/// Three seconds: long enough that someone logging a run of entries
/// collapses them into a single pass, short enough that the queue looks
/// current. A provider rather than a hard-coded default so tests can
/// shorten it instead of waiting out the full window.
final syncDrainDebounceProvider =
    Provider<Duration>((ref) => const Duration(seconds: 3));

/// Debounced drain after every local write.
///
/// Every write that needs syncing already ends in an insert on the
/// sync queue — that insert is the choke point all eight repositories
/// share — so this listens to that one table rather than teaching each
/// repository to ask for a drain itself.
///
/// Inserts only, deliberately: the rows the engine writes while
/// draining (deleted on success, updated on failure) must not schedule
/// the next drain, or a failed pass would set off its own retry loop
/// with nothing to back it off.
final lifecycleSyncTriggerProvider = Provider<LifecycleSyncTrigger>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final trigger = LifecycleSyncTrigger(
    ref.watch(syncServiceProvider),
    debounce: ref.watch(syncDrainDebounceProvider),
  );
  final subscription = database
      .tableUpdates(
        TableUpdateQuery.onTable(
          database.syncQueue,
          limitUpdateKind: UpdateKind.insert,
        ),
      )
      .listen((_) => trigger.scheduleDrain());
  ref.onDispose(() async {
    await subscription.cancel();
    trigger.dispose();
  });
  return trigger;
});

/// Drains whenever the device comes back online, and only then.
///
/// Started from here rather than at import time: the trigger only
/// exists while something watches this provider, and the app's root
/// widget watches it for the whole session. (Android reports the
/// current network as soon as we listen, so a freshly opened app also
/// gets a first chance to drain whatever the last session left.)
final connectivitySyncTriggerProvider =
    Provider<ConnectivitySyncTrigger>((ref) {
  final trigger = ConnectivitySyncTrigger(ref.watch(syncServiceProvider));
  trigger.start();
  ref.onDispose(trigger.dispose);
  return trigger;
});
