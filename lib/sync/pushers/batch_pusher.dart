import 'package:broiler_fms/data/local/database.dart' show SyncQueueData;
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/sync/pushers/entity_pusher.dart';
import 'package:broiler_fms/sync/sync_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pushes queued batches to Supabase's `batch` table.
///
/// Batches sort first in the push order because every other record in
/// the queue points at one.
class BatchPusher extends EntityPusher {
  BatchPusher(this._local);

  final LocalBatchRepository _local;

  @override
  String get entityTable => 'batches';

  @override
  Future<SyncPushResult> push(SyncQueueData row, SupabaseClient client) async {
    final batch = await _local.getById(row.recordId);
    if (batch == null) return const SyncPushDropped();

    try {
      await client.from('batch').upsert(_payload(batch));

      // Batches have no syncedAt column, so the queue row is the only
      // local trace of this push.
      return const SyncPushSuccess();
    } on PostgrestException catch (e) {
      return SyncPushFailure(e.message);
    } catch (e) {
      return SyncPushFailure(e.toString());
    }
  }

  Map<String, dynamic> _payload(Batch b) {
    return {
      'batch_id': b.batchId,
      'business_id': b.businessId,
      'batch_name': b.batchName,
      'starting_bird_count': b.startingBirdCount,
      'start_date': dateOnly(b.startDate),
      'is_closed': b.isClosed,
      'created_at': b.createdAt.toIso8601String(),
      'assigned_staff_id': b.assignedStaffId,
      'closed_by': b.closedBy,
      'breed': b.breed,
      'description': b.description,
      'closed_at': b.closedAt?.toIso8601String(),
    };
  }
}


/// Builds a [BatchPusher] for the sync engine. Mobile only.
final batchPusherProvider = Provider<BatchPusher>(
      (ref) => BatchPusher(ref.watch(localBatchRepositoryProvider)),
);
