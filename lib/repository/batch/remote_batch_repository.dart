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
class RemoteBatchRepository {
  RemoteBatchRepository(this._client);

  final SupabaseClient _client;

  /// All batches the signed-in account is allowed to see, most
  /// recently started first.
  Future<List<Batch>> getAll() async {
    final rows =
    await _client.from('batch').select().order('start_date', ascending: false);
    return rows.map(Batch.fromJson).toList();
  }
}


/// Builds a [RemoteBatchRepository] wired to the shared Supabase
/// client, for web Admin's read-only batch views and for mobile's
/// login-time cache refresh.
final remoteBatchRepositoryProvider = Provider<RemoteBatchRepository>(
      (ref) => RemoteBatchRepository(ref.watch(supabaseClientProvider)),
);