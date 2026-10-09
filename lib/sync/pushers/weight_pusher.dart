import 'package:broiler_fms/data/local/database.dart' show SyncQueueData;
import 'package:broiler_fms/domain/models/weight_sample.dart';
import 'package:broiler_fms/repository/weight/local_weight_repository.dart';
import 'package:broiler_fms/sync/pushers/entity_pusher.dart';
import 'package:broiler_fms/sync/sync_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pushes queued weight samples to Supabase's `weight_sample` table.
class WeightPusher extends EntityPusher {
  WeightPusher(this._local);

  final LocalWeightRepository _local;

  @override
  String get entityTable => 'weight_samples';

  @override
  Future<SyncPushResult> push(SyncQueueData row, SupabaseClient client) async {
    final sample = await _local.getById(row.recordId);
    if (sample == null) return const SyncPushDropped();

    try {
      await client.from('weight_sample').upsert(_payload(sample));
      await _local.markSynced(row.recordId, DateTime.now());
      return const SyncPushSuccess();
    } on PostgrestException catch (e) {
      return SyncPushFailure(e.message);
    } catch (e) {
      return SyncPushFailure(e.toString());
    }
  }

  Map<String, dynamic> _payload(WeightSample w) {
    return {
      'weight_sample_id': w.weightSampleId,
      'batch_id': w.batchId,
      'recorded_by': w.recordedBy,
      'date': dateOnly(w.date),
      'sample_weight': w.sampleWeight,
      'sample_count': w.sampleCount,
      'recorded_at': w.recordedAt.toIso8601String(),
    };
  }
}


/// Builds a [WeightPusher] for the sync engine. Mobile only.
final weightPusherProvider = Provider<WeightPusher>(
      (ref) => WeightPusher(ref.watch(localWeightRepositoryProvider)),
);
