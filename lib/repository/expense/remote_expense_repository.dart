import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/domain/models/expense.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broiler_fms/data/remote/supabase_provider.dart';

/// Expenses read straight from Supabase, used by the web app (Admin),
/// and by mobile's ExpenseDomain.refreshExpenses() at login. It always
/// returns [Expense] objects.
///
/// Read-only by design: Admin never records an expense, and there is no
/// local database on the web.
class RemoteExpenseRepository {
  RemoteExpenseRepository(this._client);

  final SupabaseClient _client;

  /// All expenses the signed-in account is allowed to see, oldest
  /// first. RLS scopes this — a Staff session gets zero rows back,
  /// financial data is Manager-only by design.
  Future<List<Expense>> getAll() async {
    final rows = await _client.from('expense').select().order('date');
    return rows.map(Expense.fromJson).toList();
  }

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
/// client, for web Admin's read-only expense views and for mobile's
/// login-time cache refresh.
final remoteExpenseRepositoryProvider = Provider<RemoteExpenseRepository>(
      (ref) => RemoteExpenseRepository(ref.watch(supabaseClientProvider)),
);
