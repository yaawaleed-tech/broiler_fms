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
    required List<String> allowedRoles,
    required String wrongAppMessage,
  })
      : _supabase = supabase,
        _onLoginSuccess = onLoginSuccess,
        _allowedRoles = allowedRoles,
        _wrongAppMessage = wrongAppMessage;

  final SupabaseClient _supabase;
  final Future<void> Function() _onLoginSuccess;
  // Roles this app accepts, and the message shown for any other role.
  final List<String> _allowedRoles;
  final String _wrongAppMessage;

  Future<void> sendLoginCode(String email) async {
    try {
      final status = await _supabase.rpc(
        'check_account_login_status',
        params: {'p_email': email},
      ) as String?;
      if (status == 'inactive') {
        throw const DomainException(
          'This account has been deactivated. Contact your Admin for help.',
        );
      }
      // An email with no account never gets a code.
      if (status == null) {
        throw const DomainException(
          'No account was found for this email. Contact your Admin for help.',
        );
      }
      // An account that belongs to the other app never gets a code.
      final role = await _supabase.rpc(
        'check_account_login_role',
        params: {'p_email': email},
      ) as String?;
      if (role != null && !_allowedRoles.contains(role)) {
        throw DomainException(_wrongAppMessage);
      }
      // 'active' and 'pending' accounts continue to the code request.
      await _supabase.auth.signInWithOtp(email: email);
    } on AuthException catch (e) {
      throw DomainException(e.message);
    } on PostgrestException catch (e) {
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