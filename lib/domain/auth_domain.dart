import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';
import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';

/// Email OTP login, used by every role. Wraps Supabase Auth directly,
/// since there is no repository for authentication itself, only for
/// the Account data that exists once someone is signed in.
class AuthDomain {
  AuthDomain({
    required SupabaseClient supabase,
    required CurrentAccountDomain currentAccountDomain,
  })  : _supabase = supabase,
        _currentAccountDomain = currentAccountDomain;

  final SupabaseClient _supabase;
  final CurrentAccountDomain _currentAccountDomain;

  /// Sends a 6-digit login code to [email]. Throws if Supabase
  /// rejects the request, e.g. no account exists for that email.
  Future<void> sendLoginCode(String email) async {
    try {
      await _supabase.auth.signInWithOtp(email: email);
    } on AuthException catch (e) {
      throw DomainException(e.message);
    }
  }

  /// Verifies [code] for [email]. On success, immediately resolves
  /// and caches this device's own Account, so every other Domain
  /// class has a currentAccount ready the moment login finishes.
  Future<void> verifyLoginCode({
    required String email,
    required String code,
  }) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.email,
      );
    } on AuthException {
      throw const DomainException(
        'That code is incorrect or has expired.',
      );
    }
    await _currentAccountDomain.resolveAndCacheMyAccount();
  }

  /// Signs out and clears this device's local state.
  Future<void> logOut() async {
    await _supabase.auth.signOut();
  }
}

/// Builds an [AuthDomain] wired to the shared Supabase client and
/// [CurrentAccountDomain].
final authDomainProvider = Provider<AuthDomain>((ref) {
  return AuthDomain(
    supabase: ref.watch(supabaseClientProvider),
    currentAccountDomain: ref.watch(currentAccountDomainProvider),
  );
});