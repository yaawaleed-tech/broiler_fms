import 'package:broiler_fms/data/local/database.dart' show SyncQueueData;
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/sync/pushers/entity_pusher.dart';
import 'package:broiler_fms/sync/sync_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Drains the sync queue up to Supabase, one pass at a time.
///
/// Every local write that has to reach Supabase leaves a row in the
/// queue. A pass reads them all, orders them so foreign keys are
/// satisfied, pushes each through its [EntityPusher], and then either
/// removes the queue row (the record pushed, or it no longer exists
/// locally) or records the failure against it for a later pass.
class SyncService {
  SyncService({
    required LocalSyncQueueRepository queue,
    required SupabaseClient client,
    required List<EntityPusher> pushers,
  })  : _queue = queue,
        _client = client,
        _pushers = {for (final pusher in pushers) pusher.entityTable: pusher};

  final LocalSyncQueueRepository _queue;
  final SupabaseClient _client;
  final Map<String, EntityPusher> _pushers;

  /// Push order: parents before children, so no record arrives before
  /// the row its foreign key points at.
  static const pushOrder = [
    'batches',
    'expenses',
    'mortality_entries',
    'feed_entries',
    'weight_samples',
    'vaccination_entries',
    'harvest_entries',
    'sales',
  ];

  Future<SyncResult>? _active;

  /// True while a pass is running.
  bool get isDraining => _active != null;

  /// Pushes everything currently queued and reports what that pass did.
  ///
  /// A call made while a pass is already running joins it rather than
  /// starting a second one: two drains at once would push the same rows
  /// twice.
  Future<SyncResult> drain() {
    return _active ??= _drain().whenComplete(() => _active = null);
  }

  Future<SyncResult> _drain() async {
    final rows = await _queue.pendingRows();
    final ordered = [...rows]..sort(_inPushOrder);

    var pushed = 0;
    var dropped = 0;
    var failed = 0;
    var rejected = 0;
    final errors = <String>[];

    for (final row in ordered) {
      final pusher = _pushers[row.entityTable];
      if (pusher == null) {
        // Only a missing registration causes this. Retrying would fail
        // forever, but the row still has to say what went wrong.
        final error = 'no pusher registered for "${row.entityTable}"';
        await _queue.markFailed(row.id, error);
        errors.add('${row.entityTable}/${row.recordId}: $error');
        failed++;
        continue;
      }

      try {
        final result = await pusher.push(row, _client);
        if (result is SyncPushSuccess) {
          await _queue.markSynced(row.id);
          pushed++;
        } else if (result is SyncPushDropped) {
          await _queue.markSynced(row.id);
          dropped++;
        } else if (result is SyncPushFailure) {
          // Stays in the queue with its attempt counted up, ready for
          // the next pass.
          await _queue.markFailed(row.id, result.error);
          errors.add('${row.entityTable}/${row.recordId}: ${result.error}');
          failed++;
        } else if (result is SyncPushRejected) {
          // Refused for good — flag it so this pass (and every later
          // one) never retries it. It stays in the queue so logout
          // still counts it.
          await _queue.markRejected(row.id, result.error);
          errors.add('${row.entityTable}/${row.recordId}: ${result.error}');
          rejected++;
        }
      } catch (error) {
        // A pusher is supposed to report failures, not throw them —
        // but if one ever does, keep the row rather than lose it.
        await _queue.markFailed(row.id, error.toString());
        errors.add('${row.entityTable}/${row.recordId}: $error');
        failed++;
      }
    }

    return SyncResult(
      pushed: pushed,
      dropped: dropped,
      failed: failed,
      rejected: rejected,
      errors: errors,
    );
  }

  int _rank(String entityTable) {
    final index = pushOrder.indexOf(entityTable);
    return index == -1 ? pushOrder.length : index;
  }

  /// Known tables in [pushOrder], unknown ones last (they are a bug,
  /// and a bug should not jump the queue), oldest enqueue first within
  /// a table, then by queue id as the tie-break.
  int _inPushOrder(SyncQueueData a, SyncQueueData b) {
    final byRank = _rank(a.entityTable).compareTo(_rank(b.entityTable));
    if (byRank != 0) return byRank;
    final byTime = a.createdAt.compareTo(b.createdAt);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  }
}
