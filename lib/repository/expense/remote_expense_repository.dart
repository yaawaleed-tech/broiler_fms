import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/domain/models/expense.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broiler_fms/data/remote/supabase_provider.dart';

/// Expenses read straight from Supabase, used by the web app (Admin).
/// It always returns [Expense] objects.
///
/// Read-only by design: Admin never records an expense, and there is no
/// local database on the web.
class RemoteExpenseRepository {
  RemoteExpenseRepository(this._client);

  final SupabaseClient _client;

  /// All expenses for one batch.
  Future<List<Expense>> getByBatch(String batchId) async {
    final rows = await _client
        .from('expense')
        .select()
        .eq('batch_id', batchId)
        .order('date');
    return rows.map(Expense.fromJson).toList();
  }
}


/// Builds a [RemoteExpenseRepository] wired to the shared Supabase
/// client. Web only, used by Admin's read-only expense views.
final remoteExpenseRepositoryProvider = Provider<RemoteExpenseRepository>(
      (ref) => RemoteExpenseRepository(ref.watch(supabaseClientProvider)),
);
