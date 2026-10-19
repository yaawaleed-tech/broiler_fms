import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:broiler_fms/data/local/database.dart' as local;
import 'package:broiler_fms/domain/models/expense.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:broiler_fms/data/local/database_provider.dart';
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/repository/shared/changed_rows.dart';

/// Expenses stored on the device, used by the mobile app (Manager only,
/// unlike the other entry types). It talks only to Drift and always
/// returns [Expense] objects.
///
/// Staff never sees this repository at all, by design, financial data is
/// restricted to Manager and above.
class LocalExpenseRepository {
  LocalExpenseRepository(this._db);

  final local.AppDatabase _db;
  static const _uuid = Uuid();
  late final LocalSyncQueueRepository _syncQueueRepo =
      LocalSyncQueueRepository(_db);

  /// Overwrites the cache with expenses just pulled from Supabase,
  /// mirroring LocalBatchRepository.upsertAll.
  ///
  /// Deliberately never touches the sync queue: the enqueue() call
  /// lives inside the local-origin write below (record), which has to
  /// travel up. This is the opposite direction — data that is already
  /// on the server — and queuing it would loop pointless pushes.
  ///
  /// Any expense whose id is still queued is skipped entirely, so a
  /// local record the server has not accepted yet is never replaced by
  /// the server's older copy of the same row. Returns how many rows were
  /// genuinely new or different, so an unchanged pull reports nothing.
  Future<int> upsertAll(List<Expense> expenses) async {
    final pending =
        await _syncQueueRepo.pendingRecordIds(entityTable: 'expenses');
    final safe =
        expenses.where((item) => !pending.contains(item.expenseId)).toList();
    if (safe.isEmpty) return 0;
    final stored = await (_db.select(_db.expenses)
          ..where((e) => e.expenseId.isIn(safe.map((e) => e.expenseId))))
        .get();
    final existingById = {for (final row in stored) row.expenseId: _fromRow(row)};
    final changed = changedRows(
      safe,
      existingById,
      (e) => e.expenseId,
      _differs,
    );
    if (changed.isEmpty) return 0;
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.expenses,
        changed.map(_toCompanion).toList(),
      );
    });
    return changed.length;
  }

  /// True when [incoming] differs from what is already stored. Covers
  /// every column this table persists.
  bool _differs(Expense incoming, Expense stored) {
    return incoming.batchId != stored.batchId ||
        incoming.recordedBy != stored.recordedBy ||
        incoming.category != stored.category ||
        !sameStoredInstant(incoming.date, stored.date) ||
        incoming.amount != stored.amount ||
        incoming.quantity != stored.quantity ||
        incoming.unitPrice != stored.unitPrice ||
        incoming.feedType != stored.feedType ||
        incoming.medicationName != stored.medicationName ||
        incoming.description != stored.description ||
        !sameStoredInstant(incoming.recordedAt, stored.recordedAt);
  }

  /// Saves a new expense on the device and returns it.
  /// The id is created here so the expense works fully offline.
  Future<Expense> record({
    required String batchId,
    required String recordedBy,
    required String category,
    required DateTime date,
    required double amount,
    double? quantity,
    double? unitPrice,
    String? feedType,
    String? medicationName,
    String? description,
  }) async {
    final expense = Expense(
      expenseId: _uuid.v4(),
      batchId: batchId,
      recordedBy: recordedBy,
      category: category,
      date: date,
      amount: amount,
      recordedAt: DateTime.now(),
      quantity: quantity,
      unitPrice: unitPrice,
      feedType: feedType,
      medicationName: medicationName,
      description: description,
    );
    await _db.into(_db.expenses).insert(_toCompanion(expense));
    await _syncQueueRepo.enqueue(
      entityTable: 'expenses',
      recordId: expense.expenseId,
      operation: 'insert',
    );
    return expense;
  }

  /// All expenses for one batch.
  Future<List<Expense>> getByBatch(String batchId) async {
    final query = _db.select(_db.expenses)
      ..where((e) => e.batchId.equals(batchId));
    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  /// Same as [getByBatch], but emits a new list whenever the data changes.
  Stream<List<Expense>> watchByBatch(String batchId) {
    final query = _db.select(_db.expenses)
      ..where((e) => e.batchId.equals(batchId));
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// One expense by id, or null if it isn't in local storage.
  Future<Expense?> getById(String expenseId) async {
    final query = _db.select(_db.expenses)
      ..where((e) => e.expenseId.equals(expenseId));
    final row = await query.getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Stamps [syncedAt] once the expense has reached Supabase.
  Future<void> markSynced(String expenseId, DateTime at) {
    final query = _db.update(_db.expenses)
      ..where((e) => e.expenseId.equals(expenseId));
    return query.write(local.ExpensesCompanion(syncedAt: Value(at)));
  }

  /// Drift row to the standard [Expense]. Lives here, not in the model,
  /// because the model must not import Drift.
  Expense _fromRow(local.Expense row) {
    return Expense(
      expenseId: row.expenseId,
      batchId: row.batchId,
      recordedBy: row.recordedBy,
      category: row.category,
      date: row.date,
      amount: row.amount,
      recordedAt: row.recordedAt,
      quantity: row.quantity,
      unitPrice: row.unitPrice,
      feedType: row.feedType,
      medicationName: row.medicationName,
      description: row.description,
    );
  }

  /// Standard [Expense] to the values Drift needs for an insert.
  local.ExpensesCompanion _toCompanion(Expense e) {
    return local.ExpensesCompanion(
      expenseId: Value(e.expenseId),
      batchId: Value(e.batchId),
      recordedBy: Value(e.recordedBy),
      category: Value(e.category),
      date: Value(e.date),
      amount: Value(e.amount),
      recordedAt: Value(e.recordedAt),
      quantity: Value(e.quantity),
      unitPrice: Value(e.unitPrice),
      feedType: Value(e.feedType),
      medicationName: Value(e.medicationName),
      description: Value(e.description),
    );
  }
}


/// Builds a [LocalExpenseRepository] wired to the shared Drift database.
/// Mobile only.
final localExpenseRepositoryProvider = Provider<LocalExpenseRepository>(
      (ref) => LocalExpenseRepository(ref.watch(appDatabaseProvider)),
);