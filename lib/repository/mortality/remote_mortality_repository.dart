import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/domain/models/mortality.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';

/// Mortality entries read straight from Supabase, used by the web app
/// (Admin). It always returns [Mortality] objects.
///
/// Read-only by design: Admin never records a mortality entry, and there
/// is no local database on the web.
class RemoteMortalityRepository {
  RemoteMortalityRepository(this._client);

  final SupabaseClient _client;

  /// All mortality entries for one batch.
  Future<List<Mortality>> getByBatch(String batchId) async {
    final rows = await _client
        .from('mortality_entry')
        .select()
        .eq('batch_id', batchId)
        .order('date');
    return rows.map(Mortality.fromJson).toList();
  }
}


/// Builds a [RemoteMortalityRepository] wired to the shared Supabase
/// client. Web only, used by Admin's read-only mortality views.
final remoteMortalityRepositoryProvider =
Provider<RemoteMortalityRepository>(
      (ref) => RemoteMortalityRepository(ref.watch(supabaseClientProvider)),
);