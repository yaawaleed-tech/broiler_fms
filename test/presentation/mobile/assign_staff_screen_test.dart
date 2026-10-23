import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/domain/account/account_domain.dart';
import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/presentation/mobile/batch/assign_staff_screen.dart';

/// The Manager's staff picker.
///
/// The list is read from the local cache, so it works offline, but the
/// cache is only ever filled by a pull. Before the fix the Assign Staff
/// screen read the cache and nothing ever refreshed it, so a Manager
/// whose phone had not pulled the Staff pool since login saw an empty
/// list and could not assign anybody. These tests cover the refresh on
/// opening, the list still rendering from the cache, and the empty
/// state.
class _FakeAccountDomain extends Fake implements AccountDomain {
  _FakeAccountDomain({this.staff = const []});

  /// The cached pool the screen lists.
  final List<Account> staff;

  /// How many times the screen asked the server for a fresh pool.
  int refreshCalls = 0;

  /// When set, the refresh fails the way an offline phone's does.
  bool failRefresh = false;

  @override
  Stream<List<Account>> watchStaffPool(String businessId) =>
      Stream.value(staff);

  @override
  Future<List<Account>> getStaffPool(String businessId) async => staff;

  @override
  Future<void> refreshStaffPool() async {
    refreshCalls++;
    if (failRefresh) throw Exception('offline');
  }
}

class _FakeBatchDomain extends Fake implements BatchDomain {
  @override
  Future<Batch?> getById(String batchId) async => Batch(
    batchId: batchId,
    businessId: 'biz-1',
    batchName: 'House 1',
    startingBirdCount: 100,
    startDate: DateTime(2026, 1, 1),
    isClosed: false,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  final manager = Account(
    accountId: 'acc-1',
    businessId: 'biz-1',
    role: 'manager',
    name: 'Ada',
    email: 'ada@example.com',
    status: 'active',
    createdAt: DateTime(2026, 1, 1),
  );

  Account staffMember(String name) => Account(
    accountId: 'acc-$name',
    businessId: 'biz-1',
    role: 'staff',
    name: name,
    email: '$name@example.com',
    status: 'active',
    createdAt: DateTime(2026, 1, 1),
  );

  Future<_FakeAccountDomain> mount(
    WidgetTester tester, {
    List<Account> staff = const [],
  }) async {
    final accountDomain = _FakeAccountDomain(staff: staff);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountDomainProvider.overrideWithValue(accountDomain),
          batchDomainProvider.overrideWithValue(_FakeBatchDomain()),
          currentAccountProvider.overrideWith((ref) async => manager),
        ],
        child: const MaterialApp(home: AssignStaffScreen(batchId: 'batch-1')),
      ),
    );
    await tester.pump();
    return accountDomain;
  }

  testWidgets('pulls the staff pool from the server when the screen opens', (
    tester,
  ) async {
    // Proves the screen asks for a fresh pool on open, which is what
    // makes the list current (use case: Manager assigns Staff to a batch).
    final accountDomain = await mount(tester);
    await tester.pump();

    expect(accountDomain.refreshCalls, 1);
  });

  testWidgets('lists the staff accounts the cache holds', (tester) async {
    // Proves the list still renders from the local cache, so it works
    // offline from the last copy.
    await mount(tester, staff: [staffMember('Sam'), staffMember('Ada2')]);
    await tester.pumpAndSettle();

    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('Ada2'), findsOneWidget);
  });

  testWidgets('shows the empty state when the pool has nobody in it', (
    tester,
  ) async {
    // Proves an empty pool explains itself instead of showing a blank
    // screen.
    await mount(tester);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No active Staff accounts yet.'),
      findsOneWidget,
    );
  });

  testWidgets('an offline pull still leaves the cached list showing', (
    tester,
  ) async {
    // Proves a failed refresh does not take the list away: the cached
    // copy keeps working offline.
    final accountDomain = _FakeAccountDomain(staff: [staffMember('Sam')]);
    accountDomain.failRefresh = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountDomainProvider.overrideWithValue(accountDomain),
          batchDomainProvider.overrideWithValue(_FakeBatchDomain()),
          currentAccountProvider.overrideWith((ref) async => manager),
        ],
        child: const MaterialApp(home: AssignStaffScreen(batchId: 'batch-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(accountDomain.refreshCalls, 1);
    expect(find.text('Sam'), findsOneWidget);
  });
}
