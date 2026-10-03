import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/repository/account/local_account_repository.dart';
import 'package:broiler_fms/repository/account/remote_account_repository.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';

/// Who is signed into this device, resolved once at login and cached
/// locally so every other Domain class can read it with zero
/// connectivity afterwards.
class CurrentAccountDomain {
  CurrentAccountDomain({
    required SupabaseClient supabase,
    required RemoteAccountRepository remoteAccountRepo,
    required LocalAccountRepository localAccountRepo,
  })  : _supabase = supabase,
        _remoteAccountRepo = remoteAccountRepo,
        _localAccountRepo = localAccountRepo;

  final SupabaseClient _supabase;
  final RemoteAccountRepository _remoteAccountRepo;
  final LocalAccountRepository _localAccountRepo;

  /// Called once, right after login succeeds. Pulls this device's own
  /// account from Supabase, and the Staff pool too if this account is
  /// a Manager, then writes both into the local cache.
  Future<void> resolveAndCacheMyAccount() async {
    final authUserId = _supabase.auth.currentUser?.id;
    if (authUserId == null) {
      throw const DomainException('No signed-in session found.');
    }

    final myAccount = await _remoteAccountRepo.getMyAccount(authUserId);
    if (myAccount == null) {
      throw const DomainException('No account found for this session.');
    }
    await _localAccountRepo.upsertAll([myAccount]);

    if (myAccount.role == 'manager' && myAccount.businessId != null) {
      final staffPool =
      await _remoteAccountRepo.getStaffPool(myAccount.businessId!);
      await _localAccountRepo.upsertAll(staffPool);
    }
  }

  /// Who is using this device right now, read entirely from the local
  /// cache, works with zero connectivity. Null means nobody has logged
  /// in on this device yet, or the cache was cleared on logout.
  Future<Account?> getCurrentAccount() async {
    final authUserId = _supabase.auth.currentUser?.id;
    if (authUserId == null) return null;
    return _localAccountRepo.getMyAccount(authUserId);
  }
}



/// Builds a [CurrentAccountDomain], giving it the Supabase client and
/// both account repositories it needs to resolve and cache whoever is
/// signed into this device.
final currentAccountDomainProvider = Provider<CurrentAccountDomain>((ref) {
  return CurrentAccountDomain(
    supabase: ref.watch(supabaseClientProvider),
    remoteAccountRepo: ref.watch(remoteAccountRepositoryProvider),
    localAccountRepo: ref.watch(localAccountRepositoryProvider),
  );
});

/// The resolved Account for this device's session, read from the local
/// cache. Async because reading the cache is itself a database call,
/// not because it touches the network.
///
/// Null while nobody has signed in on this device yet, or after a
/// logout clears the cache. Also briefly in a "loading" state before
/// resolving, which this provider does not distinguish from null,
/// that is left for Presentation to handle once it is built.
final currentAccountProvider = FutureProvider<Account?>((ref) {
  return ref.watch(currentAccountDomainProvider).getCurrentAccount();
});