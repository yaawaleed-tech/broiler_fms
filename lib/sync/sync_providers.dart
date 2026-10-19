import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' show TableUpdateQuery, UpdateKind;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/local/database_provider.dart';
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/data/remote/supabase_provider.dart';
import 'package:broiler_fms/domain/current_account_domain.dart';

import 'pull_service.dart';
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
import 'triggers/auto_pull_trigger.dart';
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

/// How long the automatic pull waits for the account behind a restored
/// session to become readable before giving up on that run.
///
/// Twelve seconds: comfortably longer than reading the local account
/// cache, which is one row already on the device, and short enough that a
/// session that will never resolve does not stall the phone. A run that
/// reaches it is skipped, not failed.
const _accountReadyTimeout = Duration(seconds: 12);

/// Drains and then pulls automatically on app start, on app resume, and
/// when the network comes back — one throttle and one in-flight guard
/// shared by all three, so a phone waking up offline does not fire three
/// passes when it reconnects.
///
/// A periodic pull joins them, so a row somebody else recorded arrives
/// while the app is open rather than on the next cold start.
///
/// Identical for every role: what each account receives is decided by RLS
/// on the pull, and the only condition this trigger applies is that
/// somebody is signed in, read the same way [SessionPollTrigger] reads
/// it — off the Supabase session, which is synchronous and available at the
/// instant a lifecycle event arrives.
///
/// Started from here rather than at import time, like the other two
/// triggers: it exists only while something watches this provider, and
/// the app's root widget watches it for the whole session.
///
/// The provider cannot supply the presentation side of an automatic pull,
/// because invalidating open screens needs types from lib/presentation and
/// lib/sync must not import those. `AutoPullHost` does that half; see
/// lib/presentation/shared/widgets/auto_pull_host.dart.
final autoPullTriggerProvider = Provider<AutoPullTrigger>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final trigger = AutoPullTrigger(
    ref.watch(syncServiceProvider),
    ref.watch(pullServiceProvider),
    hasAccount: () => client.auth.currentUser != null,
    // Read, never watched: watching the account would rebuild this
    // provider — and dispose the live trigger — on every invalidation of
    // it, including the ones sign-out causes. Reading it inside the
    // trigger's own wait keeps the instance alive and still makes the
    // first pull wait for the account to be readable.
    accountReady: () async {
      try {
        final account = await ref
            .read(currentAccountProvider.future)
            .timeout(_accountReadyTimeout);
        return account != null;
      } catch (_) {
        // An error, or an account that never arrives, simply means this
        // run is skipped. The next trigger tries again.
        return false;
      }
    },
  );
  trigger.start();
  ref.onDispose(trigger.dispose);
  return trigger;
});

/// Display-only snapshot of what the sync-status pill needs: whether
/// the device currently has any network, and how many rows are still
/// waiting in the local sync queue. Both sources are local (the OS
/// connectivity API and the Drift queue table) — nothing here talks
/// to the server.
class SyncStatus {
  const SyncStatus({required this.isOnline, required this.pendingCount});

  final bool isOnline;
  final int pendingCount;
}

/// Emits the current pending count and every later change to it, on its
/// own. This is a real Drift watch, not a poll and not a one-shot read:
/// it re-runs on any insert, update, or delete on sync_queue, so a
/// drain emptying the queue, a failed push bumping a row's attempts,
/// and a rejection flagging a row all surface here without the code
/// that did them having to announce anything.
Stream<int> _watchPendingCount(Ref ref) {
  return ref
      .watch(localSyncQueueRepositoryProvider)
      .watchPendingCount()
      // The first count arrives a beat after the stream is subscribed,
      // and while we wait the pill shows a loading placeholder anyway,
      // so no seed value is needed.
      .distinct();
}

/// Emits the current connectivity state and every later change to it.
Stream<bool> _watchIsOnline() async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  yield !initial.contains(ConnectivityResult.none);
  yield* connectivity.onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none));
}

/// The pill's data, combining two independent live sources.
///
/// Both halves are watched for their own sake and merged here, rather
/// than one being read inside the other's loop: that is the whole fix.
/// The old shape re-read the count only when connectivity changed, so
/// a drain that emptied the queue on a stable wifi connection left
/// the pill showing the old number indefinitely — nothing about the
/// queue touched the connectivity stream, so nothing re-read it.
///
/// Now either source moving produces a fresh pair: a reconnect drains
/// the queue, the queue's deletes emit, the pill re-counts. A local
/// write enqueues a row, the insert emits, the count goes up; three
/// seconds later the debounced drain deletes it and the count comes
/// back down. No invalidation call is involved in either, and none has
/// to be remembered at the next trigger site that gets added.
final syncStatusProvider = StreamProvider.autoDispose<SyncStatus>((ref) {
  return _combineLatest(
    _watchIsOnline(),
    _watchPendingCount(ref),
    (isOnline, pendingCount) =>
        SyncStatus(isOnline: isOnline, pendingCount: pendingCount),
  );
});

/// Combines two streams into one that emits whenever either side emits,
/// pairing each new value with the latest value from the other side.
///
/// The small hand-rolled equivalent of rxdart's `combineLatest`, which
/// this project does not depend on. It exists because the pill needs
/// exactly this and nothing more general: hold the most recent value
/// from each stream, and re-emit the pair whenever one of them
/// changes. Kept here rather than pulled in as a dependency for four
/// lines of bookkeeping.
Stream<R> _combineLatest<A, B, R>(
  Stream<A> a,
  Stream<B> b,
  R Function(A, B) combine,
) {
  late final StreamController<R> controller;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;

  // Null until each side has produced its first value: a pair needs
  // both halves, so nothing is emitted before that.
  A? latestA;
  B? latestB;
  var hasA = false;
  var hasB = false;

  void emitIfReady() {
    if (!hasA || !hasB) return;
    controller.add(combine(latestA as A, latestB as B));
  }

  controller = StreamController<R>(
    onListen: () {
      subA = a.listen((value) {
        latestA = value;
        hasA = true;
        emitIfReady();
      });
      subB = b.listen((value) {
        latestB = value;
        hasB = true;
        emitIfReady();
      });
    },
    // Both sides are cancelled together, so neither outlives the
    // provider and a disposed pill stops touching Drift entirely.
    onCancel: () async {
      await subA?.cancel();
      await subB?.cancel();
    },
  );
  return controller.stream;
}

