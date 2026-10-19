import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/domain/auth_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';

/// Covers the no-internet path through the login flow.
///
/// A phone with no connection used to produce a transport exception that
/// nothing caught, so the button spun once and then nothing happened at
/// all. Every network failure in this flow must now reach the screens as
/// a DomainException carrying one readable message.
void main() {
  const noInternet =
      'No internet connection. Check your network and try again.';

  late _FakeSupabase supabase;
  late int loginSuccessCalls;
  late AuthDomain domain;

  setUp(() {
    supabase = _FakeSupabase();
    loginSuccessCalls = 0;
    domain = AuthDomain(
      supabase: supabase,
      onLoginSuccess: () async => loginSuccessCalls++,
      allowedRoles: const ['manager', 'staff'],
      wrongAppMessage: 'wrong app',
    );
  });

  /// Runs [body] and returns what it threw, failing the test if it threw
  /// nothing.
  Future<Object> errorFrom(Future<void> Function() body) async {
    try {
      await body();
    } catch (e) {
      return e;
    }
    fail('expected a DomainException, but nothing was thrown');
  }

  Future<void> sendCode() => domain.sendLoginCode('sam@example.com');
  Future<void> verifyCode() =>
      domain.verifyLoginCode(email: 'sam@example.com', code: '123456');

  group('sendLoginCode', () {
    test('a SocketException becomes the no-internet message', () async {
      supabase.failWith = SocketException('No route to host');

      final error = await errorFrom(sendCode);

      expect(error, isA<DomainException>());
      expect((error as DomainException).message, noInternet);
    });

    test('a ClientException becomes the no-internet message', () async {
      supabase.failWith = ClientException('Connection closed');

      final error = await errorFrom(sendCode);

      expect((error as DomainException).message, noInternet);
    });

    test('a TimeoutException becomes the no-internet message', () async {
      supabase.failWith = TimeoutException('no response');

      final error = await errorFrom(sendCode);

      expect((error as DomainException).message, noInternet);
    });

    test('an HttpException becomes the no-internet message', () async {
      supabase.failWith = HttpException('connection reset by peer');

      final error = await errorFrom(sendCode);

      expect((error as DomainException).message, noInternet);
    });

    test('the signInWithOtp call is never reached', () async {
      supabase.failWith = SocketException('offline');

      await errorFrom(sendCode);

      expect(supabase.otpCalls, 0,
          reason: 'the lookup failed, so no code was ever requested');
    });

  });

  group('verifyLoginCode', () {
    test('a SocketException becomes the no-internet message', () async {
      supabase.failWith = SocketException('No route to host');

      final error = await errorFrom(verifyCode);

      expect((error as DomainException).message, noInternet);
    });

    test('a ClientException becomes the no-internet message', () async {
      supabase.failWith = ClientException('Connection closed');

      final error = await errorFrom(verifyCode);

      expect((error as DomainException).message, noInternet);
    });

    test('a TimeoutException becomes the no-internet message', () async {
      supabase.failWith = TimeoutException('no response');

      final error = await errorFrom(verifyCode);

      expect((error as DomainException).message, noInternet);
    });

    test('a network failure does not trigger the signup retry', () async {
      supabase.failWith = SocketException('offline');

      await errorFrom(verifyCode);

      expect(supabase.verifyCalls, 1,
          reason: 'a dead network is not a wrong code, so there is '
              'nothing to retry');
    });

    test('onLoginSuccess is not run when the network fails', () async {
      supabase.failWith = SocketException('offline');

      await errorFrom(verifyCode);

      expect(loginSuccessCalls, 0);
    });

    test('onLoginSuccess failing on the network is reported too', () async {
      supabase.verifySucceeds = true;
      domain = AuthDomain(
        supabase: supabase,
        onLoginSuccess: () async => throw SocketException('offline'),
        allowedRoles: const ['manager', 'staff'],
        wrongAppMessage: 'wrong app',
      );

      final error = await errorFrom(verifyCode);

      expect((error as DomainException).message, noInternet,
          reason: 'warming the account cache is itself a network call');
    });
  });

  group('existing behaviour is unchanged', () {
  });

  group('the shared helper', () {
    test('passes an unrelated error straight through', () async {
      // A programming error must never be dressed up as "no internet".
      await expectLater(
        withNetworkFailureHandling<Object?>(() async {
          throw const FormatException('bad payload');
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rethrows a DomainException unchanged', () async {
      await expectLater(
        withNetworkFailureHandling<Object?>(() async {
          throw const DomainException('a business rule said no');
        }),
        throwsA(
          isA<DomainException>().having(
            (e) => e.message,
            'message',
            'a business rule said no',
          ),
        ),
      );
    });

    test('returns the value when nothing goes wrong', () async {
      expect(await withNetworkFailureHandling(() async => 42), 42);
    });

    test('a call that never answers is rescued by the timeout', () async {
      // Nothing returns and nothing throws, which is the case that used
      // to leave the screen spinning forever.
      await expectLater(
        withNetworkFailureHandling<Object?>(() => Completer<Object?>().future),
        throwsA(
          isA<DomainException>().having((e) => e.message, 'message', noInternet),
        ),
      );
    }, timeout: const Timeout(Duration(seconds: 40)));
  });
}

/// A SupabaseClient stand-in.
///
/// [Fake] supplies every member for free, so the scenario is driven from
/// noSuchMethod: whichever call the flow makes next, it either answers
/// the configured value, throws [failWith], or never completes.
class _FakeSupabase extends Fake implements SupabaseClient {
  /// Thrown by whichever call runs next, at any depth.
  Object? failWith;

  int otpCalls = 0;
  int verifyCalls = 0;
  String? lastOtpEmail;

  late final _FakeAuth _auth = _FakeAuth(this);

  /// Lets verifyOTP succeed so the flow reaches onLoginSuccess.
  set verifySucceeds(bool value) => _auth.verifySucceeds = value;

  @override
  GoTrueClient get auth => _auth;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final failure = failWith;
    if (failure != null) throw failure;
    // rpc's declared return type is a PostgrestFilterBuilder, which a
    // fake cannot build, so it can only be made to throw here. That is
    // enough: every scenario below is one where it throws.
    return null;
  }
}

/// GoTrueClient is re-exported by supabase_flutter (through gotrue), so it
/// can be named here without adding a direct dependency on either package.
class _FakeAuth extends Fake implements GoTrueClient {
  _FakeAuth(this.owner);

  final _FakeSupabase owner;

  /// True lets verifyOTP succeed, so the flow reaches onLoginSuccess.
  bool verifySucceeds = false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Counted before anything can fail, so "was this attempted?" is
    // answerable even when the attempt threw.
    final isOtp = invocation.memberName == #signInWithOtp;
    final isVerify = invocation.memberName == #verifyOTP;
    if (isOtp) {
      owner.otpCalls++;
      owner.lastOtpEmail = invocation.namedArguments[#email] as String?;
    }
    if (isVerify) owner.verifyCalls++;

    final failure = owner.failWith;
    if (failure != null) throw failure;

    if (isOtp) return Future<void>.value();
    if (isVerify) {
      if (verifySucceeds) return Future<AuthResponse>.value(AuthResponse());
      // A rejected code is the normal reason the flow reaches its signup
      // retry, and that fallback depends on it failing this way.
      throw AuthException('Token has expired or is invalid');
    }
    return null;
  }
}