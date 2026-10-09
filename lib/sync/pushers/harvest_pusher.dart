import 'package:broiler_fms/data/local/database.dart' show SyncQueueData;
import 'package:broiler_fms/domain/models/harvest.dart';
import 'package:broiler_fms/repository/harvest/local_harvest_repository.dart';
import 'package:broiler_fms/sync/pushers/entity_pusher.dart';
import 'package:broiler_fms/sync/sync_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pushes queued harvest entries to Supabase's `harvest_entry` table.
///
/// Harvests sit second to last in the push order because sales hang
/// off them.
class HarvestPusher extends EntityPusher {
  HarvestPusher(this._local);

  final LocalHarvestRepository _local;

  @override
  String get entityTable => 'harvest_entries';

  @override
  Future<SyncPushResult> push(SyncQueueData row, SupabaseClient client) async {
    final harvest = await _local.getById(row.recordId);
    if (harvest == null) return const SyncPushDropped();

    try {
      await client.from('harvest_entry').upsert(_payload(harvest));
      await _local.markSynced(row.recordId, DateTime.now());
      return const SyncPushSuccess();
    } on PostgrestException catch (e) {
      // The check_batch_bird_count() trigger refused this row: mortality +
      // harvested would pass the batch's starting count. Retrying cannot
      // fix that, so the row is marked rejected instead of failed.
      if (e.message.startsWith('mortality plus harvested')) {
        return SyncPushRejected(e.message);
      }
      return SyncPushFailure(e.message);
    } catch (e) {
      return SyncPushFailure(e.toString());
    }
  }

  Map<String, dynamic> _payload(Harvest h) {
    return {
      'harvest_id': h.harvestId,
      'batch_id': h.batchId,
      'recorded_by': h.recordedBy,
      'date': dateOnly(h.date),
      'bird_count': h.birdCount,
      'recorded_at': h.recordedAt.toIso8601String(),
    };
  }
}


/// Builds a [HarvestPusher] for the sync engine. Mobile only.
final harvestPusherProvider = Provider<HarvestPusher>(
      (ref) => HarvestPusher(ref.watch(localHarvestRepositoryProvider)),
);
