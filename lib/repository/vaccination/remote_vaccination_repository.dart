import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/domain/models/vaccination.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broiler_fms/data/remote/supabase_provider.dart';

/// Vaccination entries read straight from Supabase, used by the web
/// app (Admin), and by mobile's
/// VaccinationDomain.refreshVaccinationEntries() at login. It always
/// returns [Vaccination] objects.
///
/// Read-only by design: Admin never records a vaccination entry, and
/// there is no local database on the web.
class RemoteVaccinationRepository {
  RemoteVaccinationRepository(this._client);

  final SupabaseClient _client;

  /// All vaccination entries the signed-in account is allowed to see,
  /// oldest first. RLS scopes this to the account's own business (and
  /// to assigned batches for Staff), so no filter is needed by hand.
  Future<List<Vaccination>> getAll() async {
    final rows =
        await _client.from('vaccination_entry').select().order('date');
    return rows.map(Vaccination.fromJson).toList();
  }

  /// All vaccination entries for one batch.
  Future<List<Vaccination>> getByBatch(String batchId) async {
    final rows = await _client
        .from('vaccination_entry')
        .select()
        .eq('batch_id', batchId)
        .order('date');
    return rows.map(Vaccination.fromJson).toList();
  }
}


/// Builds a [RemoteVaccinationRepository] wired to the shared Supabase
/// client, for web Admin's read-only vaccination views and for
/// mobile's login-time cache refresh.
final remoteVaccinationRepositoryProvider =
Provider<RemoteVaccinationRepository>(
      (ref) => RemoteVaccinationRepository(ref.watch(supabaseClientProvider)),
);
