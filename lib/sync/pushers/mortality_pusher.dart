import 'package:broiler_fms/data/local/database.dart' show SyncQueueData;
import 'package:broiler_fms/domain/models/mortality.dart';
import 'package:broiler_fms/repository/mortality/local_mortality_repository.dart';
import 'package:broiler_fms/sync/pushers/entity_pusher.dart';
import 'package:broiler_fms/sync/sync_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pushes queued mortality entries to Supabase's `mortality_entry` table.
class MortalityPusher extends EntityPusher {
  MortalityPusher(this._local);

  final LocalMortalityRepository _local;

  @override
  String get entityTable => 'mortality_entries';

  @override
  Future<SyncPushResult> push(SyncQueueData row, SupabaseClient client) async {
    final mortality = await _local.getById(row.recordId);
    if (mortality == null) return const SyncPushDropped();

    try {
      await client.from('mortality_entry').upsert(_payload(mortality));
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

  Map<String, dynamic> _payload(Mortality m) {
    return {
      'mortality_id': m.mortalityId,
      'batch_id': m.batchId,
      'recorded_by': m.recordedBy,
      'date': dateOnly(m.date),
      'count': m.count,
      'recorded_at': m.recordedAt.toIso8601String(),
      'description': m.description,
    };
  }
}


/// Builds a [MortalityPusher] for the sync engine. Mobile only.
final mortalityPusherProvider = Provider<MortalityPusher>(
      (ref) => MortalityPusher(ref.watch(localMortalityRepositoryProvider)),
);
