import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/models/expense.dart';
import 'package:broiler_fms/repository/expense/remote_expense_repository.dart';

/// Web-side expense reads, used by Admin. Read-only on purpose, Admin
/// never records an expense, only Manager does, through
/// [ExpenseDomain] on mobile.
class RemoteExpenseDomain {
  RemoteExpenseDomain(this._expenseRepo);

  final RemoteExpenseRepository _expenseRepo;

  /// All expenses for one batch.
  Future<List<Expense>> getByBatch(String batchId) {
    return _expenseRepo.getByBatch(batchId);
  }
}

/// Builds a [RemoteExpenseDomain] wired to the shared Supabase client.
/// Web only, since Admin is the only role that uses this class.
final remoteExpenseDomainProvider = Provider<RemoteExpenseDomain>(
      (ref) => RemoteExpenseDomain(ref.watch(remoteExpenseRepositoryProvider)),
);