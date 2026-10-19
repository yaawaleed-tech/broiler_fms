import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart' show open;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/data/local/database.dart'
    show AppDatabase, BatchesCompanion;
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
import 'package:broiler_fms/presentation/mobile/home/batch_card.dart';
import 'package:broiler_fms/presentation/mobile/home/closed_batches_section.dart';

/// A RemoteBatchRepository that never talks to the network. The widgets
/// under test only ever ask the domain for a remaining bird count, so
/// this is never called.
class _UnusedRemote extends RemoteBatchRepository {
  _UnusedRemote(super.client);

  @override
  Future<List<Batch>> getAll() async => const [];
}

/// Widget-level checks on the Staff "Past batches" change.
///
/// The card is exercised through a real BatchDomain over an in-memory
/// database, because it reads the remaining bird count through
/// batchDomainProvider — the same provider the app hands it. Tappability
/// is checked by looking for the InkWell the card renders, and by what
/// happens on tap.
DynamicLibrary _openSqlite() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } on ArgumentError {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late SupabaseClient client;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    client = SupabaseClient('https://example.supabase.co', 'anon-key');
    addTearDown(client.dispose);
  });

  tearDown(() => db.close());

  /// A BatchDomain wired to the in-memory database. Only the remaining
  /// bird count is ever reached from these widgets.
  BatchDomain buildDomain() {
    final account = Account(
      accountId: 'acc-staff',
      businessId: 'biz-1',
      role: 'staff',
      name: 'Sam',
      email: 'sam@example.com',
      status: 'active',
      createdAt: DateTime(2026, 1, 1),
    );
    return BatchDomain(
      batchRepo: LocalBatchRepository(db),
      remoteBatchRepo: _UnusedRemote(client),
      harvestRepo: LocalHarvestRepository(db),
      mortalityRepo: LocalMortalityRepository(db),
      expenseRepo: LocalExpenseRepository(db),
      saleRepo: LocalSaleRepository(db),
      feedRepo: LocalFeedRepository(db),
      weightRepo: LocalWeightRepository(db),
      currentAccount: account,
    );
  }

  Future<void> seedBatch({
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

  Batch batch({
    required String id,
    String? assignedStaffId = 'acc-staff',
    String name = 'House 1',
    bool isClosed = false,
    DateTime? closedAt,
  }) {
    return Batch(
      batchId: id,
      businessId: 'biz-1',
      batchName: name,
      startingBirdCount: 100,
      startDate: DateTime(2026, 1, 1),
      isClosed: isClosed,
      createdAt: DateTime(2026, 1, 1),
      assignedStaffId: assignedStaffId,
      closedAt: closedAt,
    );
  }

  /// Mounts [child] with the overridden domain, inside a MaterialApp so
  /// Directionality and theme exist.
  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    BatchDomain? domain,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          batchDomainProvider.overrideWithValue(domain ?? buildDomain()),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('BatchCard, read-only (a Staff past card)', () {
    testWidgets('renders no InkWell, so a tap does nothing', (tester) async {
      await seedBatch(id: 'b1');
      await mount(
        tester,
        BatchCard(batch: batch(id: 'b1'), muted: true, onTap: false),
      );

      expect(find.byType(InkWell), findsNothing,
          reason: 'no ripple and no navigation target');

      await tester.tap(find.byType(BatchCard), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull,
          reason: 'a tap on a read-only card is simply nothing');
    });

    testWidgets('a reassigned card says why it is there', (tester) async {
      await seedBatch(id: 'b1');
      await mount(
        tester,
        BatchCard(
          batch: batch(id: 'b1', assignedStaffId: null),
          muted: true,
          onTap: false,
          reassigned: true,
        ),
      );

      expect(find.text('No longer assigned to you'), findsOneWidget);
      expect(find.text('Reassigned'), findsOneWidget);
    });

    testWidgets('a reassigned card shows no remaining count', (tester) async {
      await seedBatch(id: 'b1');
      await mount(
        tester,
        BatchCard(
          batch: batch(id: 'b1', assignedStaffId: null),
          muted: true,
          onTap: false,
          reassigned: true,
        ),
      );

      expect(find.text('remaining'), findsNothing);
      expect(find.text('100'), findsNothing);
    });

    testWidgets('a closed card still reads Closed, not Reassigned',
        (tester) async {
      await seedBatch(id: 'b1');
      await mount(
        tester,
        BatchCard(
          batch: batch(id: 'b1', isClosed: true, closedAt: DateTime(2026, 2, 3)),
          muted: true,
          onTap: false,
          reassigned: false,
        ),
      );

      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('Reassigned'), findsNothing);
      expect(find.text('No longer assigned to you'), findsNothing);
    });

    testWidgets('a tappable card (Manager) still renders an InkWell',
        (tester) async {
      await seedBatch(id: 'b1');
      await mount(tester, BatchCard(batch: batch(id: 'b1')));

      expect(find.byType(InkWell), findsWidgets,
          reason: 'unchanged for the Manager path');
    });
  });

  group('ClosedBatchesSection', () {
    testWidgets('Manager sees "Closed batches"', (tester) async {
      await seedBatch(id: 'b1');
      await mount(
        tester,
        ClosedBatchesSection(
          closed: [batch(id: 'b1', isClosed: true)],
          startExpanded: true,
        ),
      );

      expect(find.text('Closed batches'), findsOneWidget);
      expect(find.text('Past batches'), findsNothing);
    });

    testWidgets('Staff sees "Past batches"', (tester) async {
      await seedBatch(id: 'b1');
      await mount(
        tester,
        ClosedBatchesSection(
          closed: [batch(id: 'b1', isClosed: true)],
          startExpanded: true,
          readOnly: true,
        ),
      );

      expect(find.text('Past batches'), findsOneWidget);
      expect(find.text('Closed batches'), findsNothing);
    });

    testWidgets('Manager cards stay tappable', (tester) async {
      await seedBatch(id: 'b1');
      await mount(
        tester,
        ClosedBatchesSection(
          closed: [batch(id: 'b1', isClosed: true)],
          startExpanded: true,
        ),
      );

      // The header row is itself an InkWell, so count only the cards:
      // one header plus one tappable card.
      expect(find.byType(InkWell), findsNWidgets(2));
    });

    testWidgets('Staff cards are not tappable at all', (tester) async {
      await seedBatch(id: 'b1');
      await mount(
        tester,
        ClosedBatchesSection(
          closed: [batch(id: 'b1', isClosed: true)],
          startExpanded: true,
          readOnly: true,
        ),
      );

      // Only the header row remains tappable.
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('a reassigned card in the Staff section says so',
        (tester) async {
      await seedBatch(id: 'b1');
      await mount(
        tester,
        ClosedBatchesSection(
          closed: [
            batch(id: 'closed', isClosed: true, name: 'Closed one'),
            batch(
              id: 'released',
              assignedStaffId: null,
              name: 'Released one',
            ),
          ],
          startExpanded: true,
          readOnly: true,
        ),
      );

      expect(find.text('Reassigned'), findsOneWidget);
      expect(find.text('No longer assigned to you'), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);
    });

    testWidgets('the header counts every card in the section', (tester) async {
      await seedBatch(id: 'b1');
      await seedBatch(id: 'b2');
      await mount(
        tester,
        ClosedBatchesSection(
          closed: [
            batch(id: 'b1', isClosed: true),
            batch(id: 'b2', assignedStaffId: null),
          ],
          startExpanded: true,
          readOnly: true,
        ),
      );

      expect(find.text('2'), findsOneWidget);
    });
  });
}