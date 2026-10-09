import 'package:broiler_fms/data/local/database.dart' show SyncQueueData;
import 'package:broiler_fms/domain/models/vaccination.dart';
import 'package:broiler_fms/repository/vaccination/local_vaccination_repository.dart';
import 'package:broiler_fms/sync/pushers/entity_pusher.dart';
import 'package:broiler_fms/sync/sync_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pushes queued vaccination entries to Supabase's `vaccination_entry`
/// table.
class VaccinationPusher extends EntityPusher {
  VaccinationPusher(this._local);

  final LocalVaccinationRepository _local;

  @override
  String get entityTable => 'vaccination_entries';

  @override
  Future<SyncPushResult> push(SyncQueueData row, SupabaseClient client) async {
    final vaccination = await _local.getById(row.recordId);
    if (vaccination == null) return const SyncPushDropped();

    try {
      await client.from('vaccination_entry').upsert(_payload(vaccination));
      await _local.markSynced(row.recordId, DateTime.now());
      return const SyncPushSuccess();
    } on PostgrestException catch (e) {
      return SyncPushFailure(e.message);
    } catch (e) {
      return SyncPushFailure(e.toString());
    }
  }

  Map<String, dynamic> _payload(Vaccination v) {
    return {
      'vaccination_id': v.vaccinationId,
      'batch_id': v.batchId,
      'recorded_by': v.recordedBy,
      'date': dateOnly(v.date),
      'vaccine_name': v.vaccineName,
      'recorded_at': v.recordedAt.toIso8601String(),
    };
  }
}


/// Builds a [VaccinationPusher] for the sync engine. Mobile only.
final vaccinationPusherProvider = Provider<VaccinationPusher>(
      (ref) => VaccinationPusher(ref.watch(localVaccinationRepositoryProvider)),
);
