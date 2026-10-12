import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/models/expense.dart';
import 'package:broiler_fms/domain/rules/expense_category_rule.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/repository/expense/local_expense_repository.dart';
import 'package:broiler_fms/repository/expense/remote_expense_repository.dart';

/// Mobile-side expense actions, used by Manager. Unlike the other entry
/// types, Staff never records an expense, financial data is restricted
/// to Manager and above, matching [LocalExpenseRepository]'s own
/// restriction.
///
/// No bird-count rule applies here, an expense does not change how
/// many birds are in a batch.
class ExpenseDomain {
  ExpenseDomain({
    required LocalExpenseRepository expenseRepo,
    required RemoteExpenseRepository remoteExpenseRepo,
    required LocalBatchRepository batchRepo,
    required Account currentAccount,
  })  : _expenseRepo = expenseRepo,
        _remoteExpenseRepo = remoteExpenseRepo,
        _batchRepo = batchRepo,
        _currentAccount = currentAccount;

  final LocalExpenseRepository _expenseRepo;
  final RemoteExpenseRepository _remoteExpenseRepo;
  final LocalBatchRepository _batchRepo;
  final Account _currentAccount;

  /// Records an expense, after checking the batch exists and the
  /// category is one the database allows.
  ///
  /// Works on a closed batch too — see [_checkBatchExists].
  Future<Expense> recordExpense({
    required String batchId,
    required String category,
    required DateTime date,
    required double amount,
    double? quantity,
    double? unitPrice,
    String? feedType,
    String? medicationName,
    String? description,
  }) async {
    await _checkBatchExists(batchId);

    final categoryError = expenseCategoryError(category);
    if (categoryError != null) {
      throw DomainException(categoryError);
    }

    return _expenseRepo.record(
      batchId: batchId,
      recordedBy: _currentAccount.accountId,
      category: category,
      date: date,
      amount: amount,
      quantity: quantity,
      unitPrice: unitPrice,
      feedType: feedType,
      medicationName: medicationName,
      description: description,
    );
  }

  /// All expenses for one batch.
  Future<List<Expense>> getByBatch(String batchId) {
    return _expenseRepo.getByBatch(batchId);
  }

  /// Same as [getByBatch], but emits a new list whenever the data
  /// changes.
  Stream<List<Expense>> watchByBatch(String batchId) {
    return _expenseRepo.watchByBatch(batchId);
  }

  /// Pulls the latest expenses from Supabase and overwrites the local
  /// cache — same contract as BatchDomain.refreshBatches(): needs
  /// connectivity, RLS scopes the rows (Staff gets none back, financial
  /// data is Manager-only by design), and nothing enqueues because this
  /// data already lives on the server.
  ///
  /// Returns how many rows were written into the cache.
  Future<int> refreshExpenses() async {
    final expenses = await _remoteExpenseRepo.getAll();
    return _expenseRepo.upsertAll(expenses);
  }

  /// Throws if the batch is missing.
  ///
  /// Deliberately no closed-batch check: expenses are Manager-only
  /// financial records and stay writable after a batch is closed, since
  /// bills for a finished batch still arrive (and get priced into the
  /// batch's financial summary) after the birds are gone.
  Future<void> _checkBatchExists(String batchId) async {
    final batch = await _batchRepo.getById(batchId);
    if (batch == null) {
      throw const DomainException('This batch could not be found.');
    }
  }
}

/// Builds an [ExpenseDomain] for the currently signed-in account.
/// Throws if nobody is resolved as signed in yet.
final expenseDomainProvider = Provider<ExpenseDomain>((ref) {
  final currentAccount = ref.watch(currentAccountProvider).value;
  if (currentAccount == null) {
    throw const DomainException('No account is currently signed in.');
  }
  return ExpenseDomain(
    expenseRepo: ref.watch(localExpenseRepositoryProvider),
    remoteExpenseRepo: ref.watch(remoteExpenseRepositoryProvider),
    batchRepo: ref.watch(localBatchRepositoryProvider),
    currentAccount: currentAccount,
  );
});