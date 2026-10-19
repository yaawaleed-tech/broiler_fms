import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/domain/domain_exception.dart';

/// How long any one Supabase call in the login flow may take before it
/// is treated as a dead network.
///
/// Fifteen seconds: long enough for a slow connection on a rural farm to
/// finish a sign-in, short enough that a phone with no signal explains
/// itself well before anyone assumes the app has hung. Applied per call,
/// so the two lookups in [AuthDomain.sendLoginCode] may take half a
/// minute in total — deliberately, since each is a separate round trip.
const _supabaseCallTimeout = Duration(seconds: 15);

/// The one message shown whenever the network, rather than the account,
/// is what stopped the request.
const _noInternetMessage = 'No internet connection. Check your network and try again.';

/// Turns a transport failure into a [DomainException] the screens know how
/// to show.
///
/// Without this a phone with no connection produces a
/// [SocketException] or [ClientException] that no screen catches, so the
/// button spins once and then nothing at all happens — the worst possible
/// outcome, because it looks exactly like the app ignoring the tap.
///
/// Deliberately narrow: only failures of the connection itself are
/// translated. An [AuthException] or [PostgrestException] means the
/// server was reached and had an opinion, and keeps its own message.
void translateNetworkFailure(Object error) {
  if (error is SocketException ||
      error is HttpException ||
      error is ClientException ||
      error is TimeoutException) {
    throw DomainException(_noInternetMessage);
  }
}

/// Runs a Supabase call under [_supabaseCallTimeout], translating a dead
/// network into a [DomainException] and leaving every other exception
/// exactly as it was thrown.
///
/// Used for the calls in this file that are not already wrapped in a
/// caller-supplied catch.
Future<T> withNetworkFailureHandling<T>(Future<T> Function() call) async {
  try {
    return await call().timeout(_supabaseCallTimeout);
  } catch (e) {
    translateNetworkFailure(e);
    rethrow;
  }
}

/// Email OTP login, used by every role. Wraps Supabase Auth directly,
/// since there is no repository for authentication itself, only for
/// the Account data that exists once someone is signed in.
///
/// [onLoginSuccess] runs right after a code is verified. AuthDomain
/// itself never knows whether "who's signed in" is resolved through a
/// local cache (mobile) or a direct Supabase call (web) — each
/// platform's own provider supplies the right callback, so this file
/// stays free of any import that could reach dart:ffi.
///
/// Every call to Supabase goes through [withNetworkFailureHandling], so a
/// phone with no connection always ends in a [DomainException] the screens
/// already render, rather than an exception nobody catches.
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
      final status = await withNetworkFailureHandling(
        () => _supabase.rpc(
          'check_account_login_status',
          params: {'p_email': email},
        ),
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
      final role = await withNetworkFailureHandling(
        () => _supabase.rpc(
          'check_account_login_role',
          params: {'p_email': email},
        ),
      ) as String?;
      if (role != null && !_allowedRoles.contains(role)) {
        throw DomainException(_wrongAppMessage);
      }
      // 'active' and 'pending' accounts continue to the code request.
      await withNetworkFailureHandling(
        () => _supabase.auth.signInWithOtp(email: email),
      );
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
      await withNetworkFailureHandling(
        () => _supabase.auth.verifyOTP(
          email: email,
          token: code,
          type: OtpType.magiclink,
        ),
      );
    } on AuthException {
      // The magic-link attempt failing is the normal path, not an error:
      // the second try covers a code sent as a sign-up instead.
      try {
        await withNetworkFailureHandling(
          () => _supabase.auth.verifyOTP(
            email: email,
            token: code,
            type: OtpType.signup,
          ),
        );
      } on AuthException {
        throw const DomainException(
          'That code is incorrect or has expired.',
        );
      }
    }
    // Inside the try, so a failure to reach the network while warming
    // the account cache is reported the same way a failed sign-in is,
    // instead of escaping as something no screen catches.
    await withNetworkFailureHandling(_onLoginSuccess);
  }

  Future<void> logOut() async {
    await _supabase.auth.signOut();
  }
}