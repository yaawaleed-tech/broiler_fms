import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/repository/account/remote_account_repository.dart';

import 'package:broiler_fms/domain/rules/staff_limit_rule.dart';

/// Web-side account actions, used by Super Admin and Admin. Creates
/// and changes status, unlike the other remote Domain classes, since
/// these two roles are the ones allowed to write an account at all.
class RemoteAccountDomain {
  RemoteAccountDomain(this._accountRepo);

  final RemoteAccountRepository _accountRepo;

  /// Super Admin creates an Admin account.
  Future<Account> createAdmin({
    required String name,
    required String email,
  }) {
    return _accountRepo.createAdmin(name: name, email: email);
  }

  Future<Account> createStaffOrManager({
    required String businessId,
    required String role,
    required String name,
    required String email,
  }) async {
    if (role == 'manager') {
      final alreadyHasManager =
      await _accountRepo.hasActiveManager(businessId);
      if (alreadyHasManager) {
        throw const DomainException(
          'This business already has an active Manager.',
        );
      }
    }
    if (role == 'staff') {
      final staffCount = await _activeOrPendingStaffCount(businessId);
      if (!canAddMoreStaff(staffCount)) {
        throw const DomainException(
          'This business has reached its staff account limit.',
        );
      }
    }
    return _accountRepo.createStaffOrManager(
      businessId: businessId,
      role: role,
      name: name,
      email: email,
    );
  }

  /// How many Staff accounts in this business are either active or
  /// still pending their first login. Reuses the same accounts list
  /// already fetched for Admin's own accounts screen, rather than
  /// adding a new repository method just to count a subset of it.
  Future<int> _activeOrPendingStaffCount(String businessId) async {
    final accounts = await _accountRepo.getAccountsForBusiness(businessId);
    return accounts
        .where((a) => a.role == 'staff' && a.status != 'inactive')
        .length;
  }

  /// Sets an account's status to 'active' or 'inactive'.
  Future<void> updateStatus(String accountId, String status) {
    return _accountRepo.updateStatus(accountId, status);
  }

  /// Reactivates a deactivated Manager, restoring [targetStatus]
  /// ('active' if they logged in before, 'pending' if not). Refuses
  /// when a *different* Manager is already active or pending, so a
  /// business can never hold two at once through this path either.
  Future<void> reactivateManager({
    required String accountId,
    required String businessId,
    required String targetStatus,
  }) async {
    final blocked = await _accountRepo.hasActiveManager(
      businessId,
      excludingAccountId: accountId,
    );
    if (blocked) {
      throw const DomainException(
        'This business already has an active or pending Manager. '
        'Deactivate them first before reactivating another.',
      );
    }
    await _accountRepo.updateStatus(accountId, targetStatus);
  }

  /// Checks whether an email is already registered among accounts.
  /// If [excludingAccountId] is provided, that account is excluded
  /// from the check — this prevents flagging an account's own current
  /// email when the validation is reused in an edit flow.
  Future<bool> emailExists({
    required String email,
    String? excludingAccountId,
  }) {
    return _accountRepo.emailExists(
      email: email,
      excludingAccountId: excludingAccountId,
    );
  }

  /// All Admin accounts. Super Admin's own account management screen.
  Future<List<Account>> getAdmins() {
    return _accountRepo.getAdmins();
  }

  /// All Manager and Staff accounts in one business. Admin's own
  /// account management screen.
  Future<List<Account>> getAccountsForBusiness(String businessId) {
    return _accountRepo.getAccountsForBusiness(businessId);
  }
} /// Builds a [RemoteAccountDomain] wired to the shared Supabase client.
/// Web only, used by Super Admin and Admin.
final remoteAccountDomainProvider = Provider<RemoteAccountDomain>(
      (ref) => RemoteAccountDomain(ref.watch(remoteAccountRepositoryProvider)),
);