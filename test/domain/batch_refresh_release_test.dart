import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/data/local/database.dart'
    show
        AccountsCompanion,
        AppDatabase,
        BatchesCompanion,
        BusinessesCompanion;
import 'package:broiler_fms/data/local/local_sync_queue_repository.dart';
import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/repository/batch/remote_batch_repository.dart';
import 'package:broiler_fms/repository/expense/local_expense_repository.dart';
import 'package:broiler_fms/repository/feed/local_feed_repository.dart';
import 'package:broiler_fms/repository/harvest/local_harvest_repository.dart';
import 'package:broiler_fms/repository/mortality/local_mortality_repository.dart';
import 'package:broiler_fms/repository/sale/local_sale_repository.dart';
import 'package:broiler_fms/repository/weight/local_weight_repository.dart';

DynamicLibrary _openSqlite() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } on ArgumentError {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

class _StubRemoteBatchRepository extends RemoteBatchRepository {
  _StubRemoteBatchRepository(super.client, {this.rows = const [], this.error});

  final List<Batch> rows;
  final Object? error;

  @override
  Future<List<Batch>> getAll() async {
    if (error != null) throw error!;
    return rows;
  }
}

/// Covers the reassignment half of refreshBatches: marking the batches
/// the server stopped returning to this Staff member, and putting a
/// batch back when the server returns it again.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late LocalSyncQueueRepository queue;
  late LocalBatchRepository repo;
  late SupabaseClient client;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queue = LocalSyncQueueRepository(db);
    repo = LocalBatchRepository(db);
    client = SupabaseClient('https://example.supabase.co', 'anon-key');
    addTearDown(client.dispose);
  });

  tearDown(() => db.close());

  Future<void> seed() async {
    await db.into(db.businesses).insert(
          BusinessesCompanion.insert(businessId: 'biz-1', name: 'Sunny Farm'),
        );
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            accountId: 'acc-staff',
            businessId: const Value('biz-1'),
            role: 'staff',
            name: 'Sam',
            email: 'sam@example.com',
          ),
        );
  }

  /// A batch already cached on this device and still assigned to Staff.
  Future<void> cached({
    required String id,
    String? assignedStaffId = 'acc-staff',
    String name = 'House 1',
  }) async {
    await db.into(db.batches).insert(
          BatchesCompanion.insert(
            batchId: id,
            businessId: 'biz-1',
            assignedStaffId: Value(assignedStaffId),
            batchName: name,
            startingBirdCount: 100,
            startDate: DateTime(2026, 1, 1),
            isClosed: const Value(false),
            createdAt: Value(DateTime(2026, 1, 1)),
            closedAt: const Value(null),
          ),
        );
  }

  Batch remote({
    required String id,
    String? assignedStaffId = 'acc-staff',
    String name = 'House 1',
  }) {
    return Batch(
      batchId: id,
      businessId: 'biz-1',
      batchName: name,
      startingBirdCount: 100,
      startDate: DateTime(2026, 1, 1),
      isClosed: false,
      createdAt: DateTime(2026, 1, 1),
      assignedStaffId: assignedStaffId,
    );
  }

  BatchDomain buildDomain(RemoteBatchRepository remoteBatchRepo) {
    return BatchDomain(
      batchRepo: repo,
      remoteBatchRepo: remoteBatchRepo,
      harvestRepo: LocalHarvestRepository(db),
      mortalityRepo: LocalMortalityRepository(db),
      expenseRepo: LocalExpenseRepository(db),
      saleRepo: LocalSaleRepository(db),
      feedRepo: LocalFeedRepository(db),
      weightRepo: LocalWeightRepository(db),
      currentAccount: Account(
        accountId: 'acc-staff',
        businessId: 'biz-1',
        role: 'staff',
        name: 'Sam',
        email: 'sam@example.com',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  }

  group('BatchDomain.refreshBatches releases reassigned batches', () {
    test('a cached batch the server no longer returns is released', () async {
      await seed();
      await cached(id: 'b1');

      final domain =
          buildDomain(_StubRemoteBatchRepository(client, rows: const []));

      await domain.refreshBatches();

      expect((await repo.getById('b1'))!.assignedStaffId, isNull,
          reason: 'marked as no longer this account’s');
    });

    test('a batch the server still returns is not released', () async {
      await seed();
      await cached(id: 'b1');

      final domain = buildDomain(
        _StubRemoteBatchRepository(client, rows: [remote(id: 'b1')]),
      );

      await domain.refreshBatches();

      expect((await repo.getById('b1'))!.assignedStaffId, 'acc-staff');
    });

    test('only the missing one is released', () async {
      await seed();
      await cached(id: 'kept');
      await cached(id: 'lost', name: 'House 2');

      final domain = buildDomain(
        _StubRemoteBatchRepository(client, rows: [remote(id: 'kept')]),
      );

      await domain.refreshBatches();

      expect((await repo.getById('kept'))!.assignedStaffId, 'acc-staff');
      expect((await repo.getById('lost'))!.assignedStaffId, isNull);
    });

    test('a throwing getAll marks nothing at all', () async {
      await seed();
      await cached(id: 'b1');

      final domain = buildDomain(
        _StubRemoteBatchRepository(client, error: Exception('offline')),
      );

      await expectLater(domain.refreshBatches(), throwsA(isA<Exception>()));
      expect((await repo.getById('b1'))!.assignedStaffId, 'acc-staff',
          reason: 'a failed pull must never look like a reassignment');
    });

    test('the count returned includes the released rows', () async {
      await seed();
      await cached(id: 'lost');
      await cached(id: 'new', name: 'House 2');

      final domain = buildDomain(
        _StubRemoteBatchRepository(client, rows: [remote(id: 'new')]),
      );

      final count = await domain.refreshBatches();

      // 'new' is written, 'lost' is released.
      expect(count, 2);
    });

    test('releasing enqueues nothing', () async {
      await seed();
      await cached(id: 'b1');

      final domain =
          buildDomain(_StubRemoteBatchRepository(client, rows: const []));
      await domain.refreshBatches();

      expect(await queue.pendingCount(), 0,
          reason: 'a local mark is never pushed back up');
    });

    test('a queued local batch is not mistaken for a reassignment', () async {
      await seed();
      await cached(id: 'local');
      await queue.enqueue(
        entityTable: 'batches',
        recordId: 'local',
        operation: 'insert',
      );

      final domain =
          buildDomain(_StubRemoteBatchRepository(client, rows: const []));
      await domain.refreshBatches();

      expect((await repo.getById('local'))!.assignedStaffId, 'acc-staff');
    });
  });

  group('a released batch is restored when it comes back', () {
    test('the server returning it assigns it again', () async {
      await seed();
      await cached(id: 'b1');

      // First pull: the server has dropped it.
      final dropping =
          buildDomain(_StubRemoteBatchRepository(client, rows: const []));
      await dropping.refreshBatches();
      expect((await repo.getById('b1'))!.assignedStaffId, isNull);

      // Second pull: assigned back to this Staff member.
      final restoring = buildDomain(
        _StubRemoteBatchRepository(
          client,
          rows: [remote(id: 'b1', assignedStaffId: 'acc-staff')],
        ),
      );
      await restoring.refreshBatches();

      expect((await repo.getById('b1'))!.assignedStaffId, 'acc-staff',
          reason: 'upsertAll put the assignment back, unchanged');
    });

    test('and it is visible in the Staff list again', () async {
      await seed();
      await cached(id: 'b1');

      await buildDomain(_StubRemoteBatchRepository(client, rows: const []))
          .refreshBatches();

      await buildDomain(
        _StubRemoteBatchRepository(client, rows: [remote(id: 'b1')]),
      ).refreshBatches();

      final visible = await repo.watchForStaff('acc-staff').first;
      expect(
        visible.where((b) => b.batchId == 'b1').map((b) => b.assignedStaffId),
        ['acc-staff'],
      );
    });

    test('releasing and restoring twice settles back to assigned', () async {
      await seed();
      await cached(id: 'b1');

      for (var i = 0; i < 2; i++) {
        await buildDomain(_StubRemoteBatchRepository(client, rows: const []))
            .refreshBatches();
        await buildDomain(_StubRemoteBatchRepository(client, rows: [
          remote(id: 'b1'),
        ])).refreshBatches();
      }

      expect((await repo.getById('b1'))!.assignedStaffId, 'acc-staff');
    });
  });
}