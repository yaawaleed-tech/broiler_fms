import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/domain/models/batch.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';

/// Batches read straight from Supabase, used by the web app (Admin).
/// It always returns [Batch] objects.
///
/// Read-only by design: Admin never creates, assigns, or closes batches,
/// and there is no local database on the web. RLS already limits the
/// rows returned to Admin's own business, so no business_id filter is
/// needed here.
class RemoteBatchRepository {
  RemoteBatchRepository(this._client);

  final SupabaseClient _client;

  /// All batches in Admin's business, most recently started first.
  Future<List<Batch>> getAll() async {
    final rows =
    await _client.from('batch').select().order('start_date', ascending: false);
    return rows.map(Batch.fromJson).toList();
  }
}


/// Builds a [RemoteBatchRepository] wired to the shared Supabase
/// client. Web only, used by Admin's read-only batch views.
final remoteBatchRepositoryProvider = Provider<RemoteBatchRepository>(
      (ref) => RemoteBatchRepository(ref.watch(supabaseClientProvider)),
);