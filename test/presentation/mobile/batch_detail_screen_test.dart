import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqlite3/open.dart' show open;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/data/local/database.dart'
    show
        AccountsCompanion,
        AppDatabase,
        BatchesCompanion,
        BusinessesCompanion;
import 'package:broiler_fms/domain/account/account_domain.dart';
import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/presentation/mobile/batch/batch_detail_screen.dart';
import 'package:broiler_fms/repository/account/local_account_repository.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/repository/batch/remote_batch_repository.dart';
import 'package:broiler_fms/repository/expense/local_expense_repository.dart';
import 'package:broiler_fms/repository/feed/local_feed_repository.dart';
import 'package:broiler_fms/repository/harvest/local_harvest_repository.dart';
import 'package:broiler_fms/repository/mortality/local_mortality_repository.dart';
import 'package:broiler_fms/repository/sale/local_sale_repository.dart';
import 'package:broiler_fms/repository/weight/local_weight_repository.dart';

class _UnusedRemoteBatch extends RemoteBatchRepository {
  _UnusedRemoteBatch(super.client);

  @override
  Future<List<Batch>> getAll() async => const [];
}

DynamicLibrary _openSqlite() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } on ArgumentError {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

/// The batch detail screen's close/reopen affordances. Proves the
/// "Fully accounted for" banner and its buttons appear exactly when the
/// remaining count and role allow, and that the reopen button is
/// Manager-only.
void main() {
  if (Platform.isLinux) {
    open.overrideForAll(_openSqlite);
  }

  late AppDatabase db;
  late SupabaseClient client;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    client = SupabaseClient('https://example.supabase.co', 'anon-key');
    addTearDown(client.dispose);
  });

  tearDown(() => db.close());

  Account account({String role = 'manager'}) => Account(
        accountId: 'acc-1',
        businessId: 'biz-1',
        role: role,
        name: 'Ada',
        email: 'ada@example.com',
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
      );

  BatchDomain domain() => BatchDomain(
        batchRepo: LocalBatchRepository(db),
        remoteBatchRepo: _UnusedRemoteBatch(client),
        harvestRepo: LocalHarvestRepository(db),
        mortalityRepo: LocalMortalityRepository(db),
        expenseRepo: LocalExpenseRepository(db),
        saleRepo: LocalSaleRepository(db),
        feedRepo: LocalFeedRepository(db),
        weightRepo: LocalWeightRepository(db),
        currentAccount: account(),
      );

  Future<void> seedBatch({
    bool isClosed = false,
    int startingBirdCount = 100,
  }) async {
    await db.into(db.businesses).insert(
          BusinessesCompanion.insert(businessId: 'biz-1', name: 'Sunny Farm'),
        );
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            accountId: 'acc-1',
            businessId: const Value('biz-1'),
            role: 'manager',
            name: 'Ada',
            email: 'ada@example.com',
          ),
        );
    await db.into(db.batches).insert(
          BatchesCompanion.insert(
            batchId: 'batch-1',
            businessId: 'biz-1',
            assignedStaffId: const Value(null),
            batchName: 'House 1',
            startingBirdCount: startingBirdCount,
            startDate: DateTime(2026, 1, 1),
            isClosed: Value(isClosed),
            createdAt: Value(DateTime(2026, 1, 1)),
          ),
        );
  }

  Future<void> accountForAllBirds() async {
    final mortality = LocalMortalityRepository(db);
    final harvest = LocalHarvestRepository(db);
    await mortality.record(
      batchId: 'batch-1',
      recordedBy: 'acc-1',
      date: DateTime(2026, 1, 2),
      count: 40,
    );
    await harvest.record(
      batchId: 'batch-1',
      recordedBy: 'acc-1',
      date: DateTime(2026, 1, 2),
      birdCount: 60,
    );
  }

  Future<void> mount(WidgetTester tester, {required String role}) async {
    final current = account(role: role);
    final accountDomain = AccountDomain(
      localAccountRepo: LocalAccountRepository(db),
      currentAccountDomain: _StubCurrentAccountDomain(current),
    );
    final router = GoRouter(
      initialLocation: '/batches/batch-1',
      routes: [
        GoRoute(
          path: '/batches/:id',
          builder: (context, state) =>
              BatchDetailScreen(batchId: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          batchDomainProvider.overrideWithValue(domain()),
          currentAccountProvider.overrideWith((ref) async => current),
          accountDomainProvider.overrideWithValue(accountDomain),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('no banner while birds are still unaccounted for',
      (tester) async {
    // Proves a running batch with birds left shows no close/reopen
    // controls.
    await seedBatch();
    await mount(tester, role: 'manager');
    expect(find.text('Fully accounted for'), findsNothing);
    expect(find.text('Close batch'), findsNothing);
  });

  testWidgets('Manager sees Close once every bird is accounted for',
      (tester) async {
    // Proves the close action appears exactly at full accounting
    // (use case: Manager closes a finished batch).
    await seedBatch();
    await accountForAllBirds();
    await mount(tester, role: 'manager');
    expect(find.text('Fully accounted for'), findsOneWidget);
    expect(find.text('Close batch'), findsOneWidget);
    expect(find.text('Reopen batch'), findsNothing);
  });

  testWidgets('a closed batch matches Reopen and no Close', (tester) async {
    // Proves a closed batch shows the reopen affordance, and the close
    // button is gone once it has been closed.
    await seedBatch(isClosed: true);
    await mount(tester, role: 'manager');
    expect(find.text('Fully accounted for'), findsOneWidget);
    expect(find.text('Reopen batch'), findsOneWidget);
    expect(find.text('Close batch'), findsNothing);
  });

  testWidgets('Staff never sees the Close or Reopen controls',
      (tester) async {
    // Proves closing and reopening are Manager-only, even on a fully
    // accounted-for batch.
    await seedBatch();
    await accountForAllBirds();
    await mount(tester, role: 'staff');
    expect(find.text('Fully accounted for'), findsOneWidget);
    expect(find.text('Close batch'), findsNothing);
    expect(find.text('Reopen batch'), findsNothing);
  });
}

/// A CurrentAccountDomain that returns one fixed account, so
/// AccountDomain can be built without a real session.
class _StubCurrentAccountDomain extends Fake
    implements CurrentAccountDomain {
  _StubCurrentAccountDomain(this._account);

  final Account _account;

  @override
  Future<Account?> getCurrentAccount() async => _account;
}
