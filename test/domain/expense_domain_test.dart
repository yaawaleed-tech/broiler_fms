import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/data/local/database.dart'
    show AccountsCompanion, AppDatabase, BusinessesCompanion, BatchesCompanion;
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/domain/expense/expense_domain.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/models/expense.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/repository/expense/local_expense_repository.dart';
import 'package:broiler_fms/repository/expense/remote_expense_repository.dart';

/// sqlite3_flutter_libs bundles the library into phone builds only,
/// so desktop tests open the system sqlite3. Prefer the normal soname,
/// fall back to the versioned one for machines that have no unversioned
/// development symlink. Top level because drift may open the database
/// from another isolate.
DynamicLibrary _openSqlite() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } on ArgumentError {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

/// A RemoteExpenseRepository that never talks to the network: it hands
/// back whatever rows the test gave it, or throws if told to.
class _StubRemoteExpenseRepository extends RemoteExpenseRepository {
  _StubRemoteExpenseRepository(super.client, {this.rows = const [], this.error});

  final List<Expense> rows;
  final Object? error;

  @override
  Future<List<Expense>> getAll() async {
    if (error != null) throw error!;
    return rows;
  }
}

/// Covers the pull half of ExpenseDomain.refreshExpenses(): the
/// login-time download that finally tells a Manager device what was
/// recorded elsewhere. Same contract as BatchDomain.refreshBatches().
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late LocalSyncQueueRepository queue;
  late SupabaseClient client;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queue = LocalSyncQueueRepository(db);
    client = SupabaseClient('https://example.supabase.co', 'anon-key');
    addTearDown(client.dispose);
  });

  tearDown(() => db.close());

  /// One business, one account, and an open batch — the parents an
  /// expense row points at. The batch is inserted directly so it
  /// never lands in the sync queue; this test only watches the
  /// expense queue.
  Future<void> seed() async {
    await db.into(db.businesses).insert(
          BusinessesCompanion.insert(businessId: 'biz-1', name: 'Sunny Farm'),
        );
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            accountId: 'acc-mgr',
            businessId: const Value('biz-1'),
            role: 'manager',
            name: 'Mia',
            email: 'mia@example.com',
          ),
        );
    await db.into(db.batches).insert(
          BatchesCompanion.insert(
            batchId: 'batch-1',
            businessId: 'biz-1',
            batchName: 'House 1',
            startingBirdCount: 100,
            startDate: DateTime(2026, 1, 1),
          ),
        );
  }

  ExpenseDomain buildDomain(RemoteExpenseRepository remoteExpenseRepo) {
    return ExpenseDomain(
      expenseRepo: LocalExpenseRepository(db),
      remoteExpenseRepo: remoteExpenseRepo,
      batchRepo: LocalBatchRepository(db),
      currentAccount: Account(
        accountId: 'acc-mgr',
        businessId: 'biz-1',
        role: 'manager',
        name: 'Mia',
        email: 'mia@example.com',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  }

  group('ExpenseDomain.refreshExpenses', () {
    test('an expense recorded on another device lands in the local cache',
        () async {
      await seed();
      final domain = buildDomain(_StubRemoteExpenseRepository(
        client,
        rows: [
          Expense(
            expenseId: 'exp-1',
            batchId: 'batch-1',
            recordedBy: 'acc-mgr',
            category: 'feed',
            date: DateTime(2026, 2, 1),
            amount: 42.5,
            recordedAt: DateTime(2026, 2, 1),
          ),
        ],
      ));

      expect(await domain.getByBatch('batch-1'), isEmpty);

      await domain.refreshExpenses();

      final visible = await domain.getByBatch('batch-1');
      expect(visible, hasLength(1));
      expect(visible.single.amount, 42.5);
      expect(
        await queue.pendingCount(),
        0,
        reason: 'pulled rows must never be queued for push back up',
      );
    });

    test('a failed pull throws and leaves the cache untouched', () async {
      await seed();
      final domain = buildDomain(_StubRemoteExpenseRepository(client));
      // A locally recorded expense, still waiting in the queue.
      await domain.recordExpense(
        batchId: 'batch-1',
        category: 'feed',
        date: DateTime(2026, 1, 1),
        amount: 10,
      );
      expect(await queue.pendingCount(), 1);

      final offline = buildDomain(_StubRemoteExpenseRepository(
        client,
        error: Exception('offline'),
      ));

      await expectLater(offline.refreshExpenses(), throwsA(isA<Exception>()));

      final cached = await domain.getByBatch('batch-1');
      expect(cached, hasLength(1));
      expect(cached.single.amount, 10);
      expect(await queue.pendingCount(), 1);
    });
  });
}
