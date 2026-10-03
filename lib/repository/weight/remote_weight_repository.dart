import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/domain/models/weight_sample.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broiler_fms/data/remote/supabase_provider.dart';

/// Weight samples read straight from Supabase, used by the web app
/// (Admin). It always returns [WeightSample] objects.
///
/// Read-only by design: Admin never records a weight sample, and there
/// is no local database on the web.
class RemoteWeightRepository {
  RemoteWeightRepository(this._client);

  final SupabaseClient _client;

  /// All weight samples for one batch.
  Future<List<WeightSample>> getByBatch(String batchId) async {
    final rows = await _client
        .from('weight_sample')
        .select()
        .eq('batch_id', batchId)
        .order('date');
    return rows.map(WeightSample.fromJson).toList();
  }
}


/// Builds a [RemoteWeightRepository] wired to the shared Supabase
/// client. Web only, used by Admin's read-only weight views.
final remoteWeightRepositoryProvider = Provider<RemoteWeightRepository>(
      (ref) => RemoteWeightRepository(ref.watch(supabaseClientProvider)),
);