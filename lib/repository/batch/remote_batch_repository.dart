import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/domain/models/batch.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';

/// Batches read straight from Supabase. Used by the web app (Admin),
/// and by mobile's BatchDomain.refreshBatches() at login. It always
/// returns [Batch] objects.
///
/// Read-only by design: Admin never creates, assigns, or closes batches,
/// and there is no local database on the web. RLS already limits the
/// rows returned to what the signed-in account is allowed to see, for
/// every role, so no business or role filter is needed here.
///
/// batch has two foreign keys to account (assigned_staff_id and
/// closed_by), so both embeds must be disambiguated with a `!column`
/// hint, and both are aliased so the scalar ids from `*` stay intact.
class RemoteBatchRepository {
  RemoteBatchRepository(this._client);

  final SupabaseClient _client;

  static const _withNames =
      '*, assigned_staff:account!assigned_staff_id(name), '
      'closed_by_account:account!closed_by(name)';

  /// All batches the signed-in account is allowed to see, most
  /// recently started first.
  Future<List<Batch>> getAll() async {
    final rows = await _client
        .from('batch')
        .select(_withNames)
        .order('start_date', ascending: false);
    return rows.map(Batch.fromJson).toList();
  }

  /// One batch by id, resolved with its assigned-staff and closed-by
  /// names, or null if it isn't visible to this account.
  Future<Batch?> getById(String batchId) async {
    final row = await _client
        .from('batch')
        .select(_withNames)
        .eq('batch_id', batchId)
        .maybeSingle();
    return row == null ? null : Batch.fromJson(row);
  }

  /// Map of staff account id to list of assigned batch names.
  Future<Map<String, List<String>>> getAssignedBatchesMap() async {
    final rows = await _client
        .from('batch')
        .select('batch_name, assigned_staff_id')
        .not('assigned_staff_id', 'is', null);
    final map = <String, List<String>>{};
    for (final row in rows) {
      final staffId = row['assigned_staff_id'] as String?;
      final batchName = row['batch_name'] as String?;
      if (staffId != null && batchName != null) {
        map.putIfAbsent(staffId, () => []).add(batchName);
      }
    }
    return map;
  }
}


/// Builds a [RemoteBatchRepository] wired to the shared Supabase
/// client, for web Admin's read-only batch views and for mobile's
/// login-time cache refresh.
final remoteBatchRepositoryProvider = Provider<RemoteBatchRepository>(
      (ref) => RemoteBatchRepository(ref.watch(supabaseClientProvider)),
);