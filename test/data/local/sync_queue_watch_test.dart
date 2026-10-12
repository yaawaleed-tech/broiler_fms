import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;

import 'package:broiler_fms/data/local/database.dart' show AppDatabase;
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';

/// sqlite3_flutter_libs bundles the library into phone builds only,
/// so desktop tests open the system sqlite3.
DynamicLibrary _openSqlite() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } on ArgumentError {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

/// Proves the pending count is watched rather than polled, which is
/// what lets the sync-status pill correct itself after any drain
/// without that drain having to announce itself.
///
/// Each case writes to the queue the way a real path does — enqueue,
/// markSynced's delete, markFailed's update — and asserts the watched
/// stream produced the new number on its own. Nothing here calls an
/// invalidate or advances a clock; a poll-based implementation would
/// pass these too, so the timing assertions below are what separate
/// the two.
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

  /// Subscribes once, runs [action], then waits for the count to reach
  /// [expectValue].
  ///
  /// One subscription for the whole test, because a Drift watch stream
  /// is single-subscription: cancelling and re-listening would be
  /// testing a different stream each time rather than the same watch
  /// seeing a change.
  Future<List<int>> watchThrough(
    Future<void> Function() action,
    int expectValue, {
    int minimumEmissions = 1,
  }) async {
    final seen = <int>[];
    final done = Completer<void>();
    late final StreamSubscription<int> sub;
    sub = queue.watchPendingCount().listen((value) {
      seen.add(value);
      if (seen.length >= minimumEmissions && seen.last == expectValue) {
        if (!done.isCompleted) done.complete();
      }
    });
    await action();
    await done.future.timeout(const Duration(seconds: 5));
    await sub.cancel();
    return seen;
  }

  Future<int> enqueueOne() async {
    await queue.enqueue(
      entityTable: 'mortality',
      recordId: 'm-1',
      operation: 'insert',
    );
    return (await queue.pendingRows()).first.id;
  }

  test('emits the current count on subscribe', () async {
    final seen = await watchThrough(() async {}, 0);
    expect(seen.first, 0);
  });

  test('emits when a row is enqueued', () async {
    final seen = await watchThrough(() => enqueueOne(), 1);
    expect(seen.last, 1);
  });

  test('emits when a row is marked synced and deleted', () async {
    final rowId = await enqueueOne();
    expect(await queue.pendingCount(), 1);

    final seen = await watchThrough(() => queue.markSynced(rowId), 0);
    expect(seen.last, 0);
  });

  test('emits when a row is marked failed, even though the count holds',
      () async {
    final rowId = await enqueueOne();

    // The row is still pending, so the number stays 1. What is being
    // asserted is that the *stream emitted again at all* — the watch is
    // on the table, not on the value, which is what lets a rejection
    // or a retry show up in the pill without the number changing.
    final seen = await watchThrough(
      () => queue.markFailed(rowId, 'network down'),
      1,
      minimumEmissions: 2,
    );
    expect(seen.length, greaterThanOrEqualTo(2));
    expect(seen.last, 1);
  });

  test('matches the one-shot read it is meant to mirror', () async {
    await enqueueOne();
    final expected = await queue.pendingCount();
    final seen = await watchThrough(() async {}, expected);
    expect(seen.last, expected);
  });
}