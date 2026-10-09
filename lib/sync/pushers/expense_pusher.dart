import 'package:broiler_fms/data/local/database.dart' show SyncQueueData;
import 'package:broiler_fms/domain/models/expense.dart';
import 'package:broiler_fms/repository/expense/local_expense_repository.dart';
import 'package:broiler_fms/sync/pushers/entity_pusher.dart';
import 'package:broiler_fms/sync/sync_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pushes queued expenses to Supabase's `expense` table.
class ExpensePusher extends EntityPusher {
  ExpensePusher(this._local);

  final LocalExpenseRepository _local;

  @override
  String get entityTable => 'expenses';

  @override
  Future<SyncPushResult> push(SyncQueueData row, SupabaseClient client) async {
    final expense = await _local.getById(row.recordId);
    if (expense == null) return const SyncPushDropped();

    try {
      await client.from('expense').upsert(_payload(expense));
      await _local.markSynced(row.recordId, DateTime.now());
      return const SyncPushSuccess();
    } on PostgrestException catch (e) {
      return SyncPushFailure(e.message);
    } catch (e) {
      return SyncPushFailure(e.toString());
    }
  }

  Map<String, dynamic> _payload(Expense e) {
    return {
      'expense_id': e.expenseId,
      'batch_id': e.batchId,
      'recorded_by': e.recordedBy,
      'category': e.category,
      'date': dateOnly(e.date),
      'amount': e.amount,
      'recorded_at': e.recordedAt.toIso8601String(),
      'quantity': e.quantity,
      'unit_price': e.unitPrice,
      'feed_type': e.feedType,
      'medication_name': e.medicationName,
      'description': e.description,
    };
  }
}


/// Builds a [ExpensePusher] for the sync engine. Mobile only.
final expensePusherProvider = Provider<ExpensePusher>(
      (ref) => ExpensePusher(ref.watch(localExpenseRepositoryProvider)),
);
