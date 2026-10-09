import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/domain/domain_exception.dart';

/// Email OTP login, used by every role. Wraps Supabase Auth directly,
/// since there is no repository for authentication itself, only for
/// the Account data that exists once someone is signed in.
///
/// [onLoginSuccess] runs right after a code is verified. AuthDomain
/// itself never knows whether "who's signed in" is resolved through a
/// local cache (mobile) or a direct Supabase call (web) — each
/// platform's own provider supplies the right callback, so this file
/// stays free of any import that could reach dart:ffi.
class AuthDomain {
  AuthDomain({
    required SupabaseClient supabase,
    required Future<void> Function() onLoginSuccess,
  })
      : _supabase = supabase,
        _onLoginSuccess = onLoginSuccess;

  final SupabaseClient _supabase;
  final Future<void> Function() _onLoginSuccess;

  Future<void> sendLoginCode(String email) async {
    try {
      await _supabase.auth.signInWithOtp(email: email);
    } on AuthException catch (e) {
      throw DomainException(e.message);
    }
  }

  Future<void> verifyLoginCode({
    required String email,
    required String code,
  }) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.magiclink,
      );
    } on AuthException {
      try {
        await _supabase.auth.verifyOTP(
          email: email,
          token: code,
          type: OtpType.signup,
        );
      } on AuthException {
        throw const DomainException(
          'That code is incorrect or has expired.',
        );
      }
    }
    await _onLoginSuccess();
  }

  Future<void> logOut() async {
    await _supabase.auth.signOut();
  }
}