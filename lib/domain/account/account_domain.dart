import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/repository/account/local_account_repository.dart';

/// Mobile-side account actions, used by Manager.
///
/// Unlike every other mobile Domain class, this one never writes an
/// Account, mobile has no permission to. Its job is reading the cached
/// Staff pool for the batch assignment screen, and triggering a fresh
/// pull from Supabase when asked.
class AccountDomain {
  AccountDomain({
    required LocalAccountRepository localAccountRepo,
    required CurrentAccountDomain currentAccountDomain,
  })  : _localAccountRepo = localAccountRepo,
        _currentAccountDomain = currentAccountDomain;

  final LocalAccountRepository _localAccountRepo;
  final CurrentAccountDomain _currentAccountDomain;

  /// Cached active Staff accounts in one business, readable offline.
  Future<List<Account>> getStaffPool(String businessId) {
    return _localAccountRepo.getStaffPool(businessId);
  }

  /// Same as [getStaffPool], but emits a new list when the cache
  /// changes.
  Stream<List<Account>> watchStaffPool(String businessId) {
    return _localAccountRepo.watchStaffPool(businessId);
  }

  /// Pulls the latest account and Staff pool data from Supabase and
  /// refreshes the local cache. Needs connectivity to succeed.
  Future<void> refreshStaffPool() {
    return _currentAccountDomain.resolveAndCacheMyAccount();
  }
}

/// Builds an [AccountDomain]. Does not need a currentAccount itself,
/// unlike every other mobile Domain class, since it never writes
/// anything on the current account's behalf.
final accountDomainProvider = Provider<AccountDomain>((ref) {
  return AccountDomain(
    localAccountRepo: ref.watch(localAccountRepositoryProvider),
    currentAccountDomain: ref.watch(currentAccountDomainProvider),
  );
});