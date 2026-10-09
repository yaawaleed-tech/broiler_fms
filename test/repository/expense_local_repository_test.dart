import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;

import 'package:broiler_fms/data/local/database.dart'
    show AccountsCompanion, AppDatabase, BusinessesCompanion;
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/domain/models/expense.dart';
import 'package:broiler_fms/repository/expense/local_expense_repository.dart';

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

/// Covers the one pull-direction write LocalExpenseRepository has: overwriting
/// the cache with expenses that came down from Supabase. The
/// local-origin write (record) keeps its own queue wiring, tested
/// over in test/sync/sync_service_test.dart.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late LocalExpenseRepository repo;
  late LocalSyncQueueRepository queue;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalExpenseRepository(db);
    queue = LocalSyncQueueRepository(db);
  });

  tearDown(() => db.close());

  /// One business and one account, the parents the table points at.
  Future<void> seed() async {
    await db
        .into(db.businesses)
        .insert(
          BusinessesCompanion.insert(businessId: 'biz-1', name: 'Sunny Farm'),
        );
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            accountId: 'acc-1',
            businessId: const Value('biz-1'),
            role: 'manager',
            name: 'Mia',
            email: 'mia@example.com',
          ),
        );
  }

  group('LocalExpenseRepository.upsertAll', () {
    test('writes pulled expenses without enqueueing them for push', () async {
      await seed();

      await repo.upsertAll([
        Expense(
          expenseId: 'exp-9',
          batchId: 'batch-1',
          recordedBy: 'acc-1',
          category: 'chicks',
          date: DateTime(2026, 2, 1),
          amount: 100,
          recordedAt: DateTime(2026, 2, 1),
        ),
      ]);

      final stored = await repo.getById('exp-9');
      expect(stored, isNotNull);
      expect(
        await queue.pendingCount(),
        0,
        reason: 'data that came down from Supabase must never be pushed back',
      );
    });

    test(
      'overwrites a cached expense with every field the server returned',
      () async {
        await seed();
        // The local-origin path: record() writes the row and queues it.
        final created = await repo.record(
          batchId: 'batch-1',
          recordedBy: 'acc-1',
          category: 'feed',
          date: DateTime(2026, 1, 1),
          amount: 10,
          quantity: 2,
          unitPrice: 5,
          feedType: 'starter',
          description: 'local row',
        );
        expect(await queue.pendingCount(), 1);

        // The same row arrives from the server carrying changed values —
        // exactly what a second device recording first looks like.
        await repo.upsertAll([
          Expense(
            expenseId: created.expenseId,
            batchId: 'batch-1',
            recordedBy: 'acc-1',
            category: 'vet_medication',
            date: DateTime(2026, 3, 1),
            amount: 42.5,
            recordedAt: DateTime(2026, 3, 2),
            quantity: 1.5,
            unitPrice: 3.0,
            feedType: null,
            medicationName: 'Albex',
            description: null,
          ),
        ]);

        final stored = await repo.getById(created.expenseId);
        expect(stored, isNotNull);
        expect(stored!.batchId, 'batch-1');
        expect(stored.recordedBy, 'acc-1');
        expect(stored.category, 'vet_medication');
        expect(stored.date, DateTime(2026, 3, 1));
        expect(stored.amount, 42.5);
        expect(stored.recordedAt, DateTime(2026, 3, 2));
        expect(stored.quantity, 1.5);
        expect(stored.unitPrice, 3.0);
        expect(stored.feedType, null);
        expect(stored.medicationName, 'Albex');
        expect(stored.description, null);
        expect(
          await queue.pendingCount(),
          1,
          reason: 'the pull added no queue rows; record()s row is the only one',
        );
      },
    );
  });
}
