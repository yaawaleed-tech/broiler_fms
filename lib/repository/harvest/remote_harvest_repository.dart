import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/domain/models/harvest.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';

/// Harvest entries read straight from Supabase, used by the web app
/// (Admin), and by mobile's HarvestDomain.refreshHarvestEntries() at
/// login. It always returns [Harvest] objects.
///
/// Read-only by design: Admin never records harvests, and there is no
/// local database on the web.
class RemoteHarvestRepository {
  RemoteHarvestRepository(this._client);

  final SupabaseClient _client;

  /// All harvest entries the signed-in account is allowed to see,
  /// oldest first. RLS scopes this to the account's own business (and
  /// to assigned batches for Staff), so no filter is needed by hand.
  Future<List<Harvest>> getAll() async {
    final rows = await _client.from('harvest_entry').select().order('date');
    return rows.map(Harvest.fromJson).toList();
  }

  /// All harvest entries for one batch, oldest first.
  Future<List<Harvest>> getByBatch(String batchId) async {
    final rows = await _client
        .from('harvest_entry')
        .select()
        .eq('batch_id', batchId)
        .order('date');
    return rows.map(Harvest.fromJson).toList();
  }
}


/// Builds a [RemoteHarvestRepository] wired to the shared Supabase
/// client, for web Admin's read-only harvest views and for mobile's
/// login-time cache refresh.
final remoteHarvestRepositoryProvider = Provider<RemoteHarvestRepository>(
      (ref) => RemoteHarvestRepository(ref.watch(supabaseClientProvider)),
);