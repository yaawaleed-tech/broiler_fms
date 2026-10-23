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
    show AccountsCompanion, AppDatabase, BatchesCompanion, BusinessesCompanion;
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

/// A CurrentAccountDomain that returns one fixed account, so
/// AccountDomain can be built without a real session.
class _StubCurrentAccountDomain extends Fake implements CurrentAccountDomain {
  _StubCurrentAccountDomain(this._account);

  final Account _account;

  @override
  Future<Account?> getCurrentAccount() async => _account;
}

DynamicLibrary _openSqlite() {
  try {
    return DynamicLibrary.open('libsqlite3.so');
  } on ArgumentError {
    return DynamicLibrary.open('libsqlite3.so.0');
  }
}

/// The unpriced-harvest row on the batch detail screen.
///
/// Birds that have been harvested but not yet priced are money the farm
/// is owed but has not recorded. The screen used to show only the total
/// harvested, so a Manager had to open the price list to find out that
/// pricing was still outstanding.
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

  Future<void> seedBatch() async {
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
            name: 'Ada',
            email: 'ada@example.com',
          ),
        );
    await db
        .into(db.batches)
        .insert(
          BatchesCompanion.insert(
            batchId: 'batch-1',
            businessId: 'biz-1',
            assignedStaffId: const Value(null),
            batchName: 'House 1',
            startingBirdCount: 100,
            startDate: DateTime(2026, 1, 1),
            isClosed: Value(false),
            createdAt: Value(DateTime(2026, 1, 1)),
          ),
        );
  }

  /// Records a harvest of [birdCount] birds that has not been priced.
  Future<void> seedUnpricedHarvest({int birdCount = 60}) async {
    await LocalHarvestRepository(db).record(
      batchId: 'batch-1',
      recordedBy: 'acc-1',
      date: DateTime(2026, 1, 2),
      birdCount: birdCount,
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

  testWidgets('a Manager sees how many birds are still waiting for a price', (
    tester,
  ) async {
    // Proves the outstanding pricing is visible on the batch screen
    // itself (use case: Manager checks what is still owed).
    await seedBatch();
    await seedUnpricedHarvest(birdCount: 60);
    await mount(tester, role: 'manager');

    expect(find.text('Unpriced harvests'), findsOneWidget);
    expect(find.textContaining('60'), findsWidgets);
    expect(find.textContaining('waiting for a price'), findsOneWidget);
    expect(find.text('Price'), findsOneWidget);
  });

  testWidgets('the row is absent when everything has been priced', (
    tester,
  ) async {
    // Proves the row does not linger once the pricing is done.
    await seedBatch();
    await mount(tester, role: 'manager');

    expect(find.text('Unpriced harvests'), findsNothing);
    expect(find.textContaining('waiting for a price'), findsNothing);
  });

  testWidgets(
    'Staff sees the outstanding pricing but cannot open the price page',
    (tester) async {
      // Proves Staff is told the same thing, without a control they are not
      // allowed to use.
      await seedBatch();
      await seedUnpricedHarvest(birdCount: 25);
      await mount(tester, role: 'staff');

      expect(find.text('Unpriced harvests'), findsOneWidget);
      expect(find.textContaining('waiting for a price'), findsOneWidget);
      expect(find.text('Price'), findsNothing);
    },
  );
}
