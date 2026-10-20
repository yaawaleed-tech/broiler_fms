import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/domain/account/remote_account_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/rules/staff_limit_rule.dart';
import 'package:broiler_fms/repository/account/remote_account_repository.dart';

/// A stand-in for RemoteAccountRepository that answers the three reads
/// createStaffOrManager makes — manager existence, the accounts list,
/// and the final create — without a network.
class _FakeAccountRepo extends Fake implements RemoteAccountRepository {
  _FakeAccountRepo({this.hasManager = false, this.accounts = const []});

  bool hasManager;
  List<Account> accounts;
  int createCalls = 0;

  @override
  Future<bool> hasActiveManager(
    String businessId, {
    String? excludingAccountId,
  }) async =>
      hasManager;

  @override
  Future<List<Account>> getAccountsForBusiness(String businessId) async =>
      accounts;

  @override
  Future<Account> createStaffOrManager({
    required String businessId,
    required String role,
    required String name,
    required String email,
  }) async {
    createCalls++;
    return Account(
      accountId: 'new-$createCalls',
      businessId: businessId,
      role: role,
      name: name,
      email: email,
      status: 'pending',
      createdAt: DateTime(2026, 1, 1),
    );
  }
}

Account staff(String id, {String status = 'active'}) => Account(
      accountId: id,
      businessId: 'biz-1',
      role: 'staff',
      name: id,
      email: '$id@example.com',
      status: status,
      createdAt: DateTime(2026, 1, 1),
    );

/// The web-side guardrails around creating a Manager or Staff account,
/// mirroring the Admin web app. Proves a second Manager is refused and
/// the Staff limit is counted over active-or-pending Staff only.
void main() {
  group('createStaffOrManager role manager', () {
    test('refuses a second Manager for the business', () async {
      // Proves the already-has-manager check stops a duplicate, with
      // the exact message.
      final repo = _FakeAccountRepo(hasManager: true);
      final domain = RemoteAccountDomain(repo);
      await expectLater(
        domain.createStaffOrManager(
          businessId: 'biz-1',
          role: 'manager',
          name: 'Ada',
          email: 'ada@example.com',
        ),
        throwsA(
          isA<DomainException>().having(
            (e) => e.message,
            'message',
            'This business already has an active Manager.',
          ),
        ),
      );
      expect(repo.createCalls, 0, reason: 'nothing was written');
    });

    test('creates a Manager when none exists yet', () async {
      // Proves the happy path writes the account (use case: Admin
      // appoints the first Manager).
      final repo = _FakeAccountRepo(hasManager: false);
      final domain = RemoteAccountDomain(repo);
      final created = await domain.createStaffOrManager(
        businessId: 'biz-1',
        role: 'manager',
        name: 'Ada',
        email: 'ada@example.com',
      );
      expect(created.role, 'manager');
      expect(repo.createCalls, 1);
    });
  });

  group('createStaffOrManager role staff', () {
    test('refuses once the business has reached the Staff limit',
        () async {
      // Proves the count hits maxStaffPerBusiness and the exact message
      // is raised without writing.
      final repo = _FakeAccountRepo(
        accounts: [
          for (var i = 0; i < maxStaffPerBusiness; i++) staff('s$i'),
        ],
      );
      final domain = RemoteAccountDomain(repo);
      await expectLater(
        domain.createStaffOrManager(
          businessId: 'biz-1',
          role: 'staff',
          name: 'Sam',
          email: 'sam@example.com',
        ),
        throwsA(
          isA<DomainException>().having(
            (e) => e.message,
            'message',
            'This business has reached its staff account limit.',
          ),
        ),
      );
      expect(repo.createCalls, 0);
    });

    test('accepts a new Staff one below the limit', () async {
      // Proves 17 active-or-pending Staff still leaves room for one.
      final repo = _FakeAccountRepo(
        accounts: [
          for (var i = 0; i < maxStaffPerBusiness - 1; i++) staff('s$i'),
        ],
      );
      final domain = RemoteAccountDomain(repo);
      final created = await domain.createStaffOrManager(
        businessId: 'biz-1',
        role: 'staff',
        name: 'Sam',
        email: 'sam@example.com',
      );
      expect(created.role, 'staff');
      expect(repo.createCalls, 1);
    });

  test('counts pending Staff against the limit, not only active ones',
      () async {
    // Proves a pending invite still occupies a slot: 17 active + 1
    // pending is 18, so the next Staff is refused. This flips if the
    // count is narrowed to status == 'active'.
    final repo = _FakeAccountRepo(
      accounts: [
        for (var i = 0; i < maxStaffPerBusiness - 1; i++) staff('a$i'),
        staff('p0', status: 'pending'),
      ],
    );
    final domain = RemoteAccountDomain(repo);
    await expectLater(
      domain.createStaffOrManager(
        businessId: 'biz-1',
        role: 'staff',
        name: 'Sam',
        email: 'sam@example.com',
      ),
      throwsA(
        isA<DomainException>().having(
          (e) => e.message,
          'message',
          'This business has reached its staff account limit.',
        ),
      ),
    );
    expect(repo.createCalls, 0);
  });

  test('does not count inactive Staff against the limit', () async {
    // Proves only active-or-pending Staff are counted: 17 active plus
    // 5 inactive is still 17, so one more fits.
    final repo = _FakeAccountRepo(
      accounts: [
        for (var i = 0; i < maxStaffPerBusiness - 1; i++) staff('a$i'),
        for (var i = 0; i < 5; i++) staff('i$i', status: 'inactive'),
      ],
    );
    final domain = RemoteAccountDomain(repo);
    final created = await domain.createStaffOrManager(
      businessId: 'biz-1',
      role: 'staff',
      name: 'Sam',
      email: 'sam@example.com',
    );
    expect(created.role, 'staff');
    expect(repo.createCalls, 1);
  });

    test('ignores manager accounts when counting Staff', () async {
      // Proves only role == staff rows count: a business with one
      // Manager and 17 Staff still fits one more Staff.
      final repo = _FakeAccountRepo(
        accounts: [
          Account(
            accountId: 'mgr',
            businessId: 'biz-1',
            role: 'manager',
            name: 'Mgr',
            email: 'mgr@example.com',
            status: 'active',
            createdAt: DateTime(2026, 1, 1),
          ),
          for (var i = 0; i < maxStaffPerBusiness - 1; i++) staff('s$i'),
        ],
      );
      final domain = RemoteAccountDomain(repo);
      final created = await domain.createStaffOrManager(
        businessId: 'biz-1',
        role: 'staff',
        name: 'Sam',
        email: 'sam@example.com',
      );
      expect(created.role, 'staff');
      expect(repo.createCalls, 1);
    });
  });
}
