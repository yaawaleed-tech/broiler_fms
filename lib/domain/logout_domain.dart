import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/repository/logout/local_logout_repository.dart';
import 'package:broiler_fms/sync/sync_providers.dart';
import 'package:broiler_fms/sync/sync_service.dart';

/// What the logout flow needs to know about the queue after the
/// last-chance drain:
///
/// * [total] — every row that never reached Supabase, rejected ones
///   included. Drives the informational warning, so nobody is
///   surprised by work that disappears with the wipe.
/// * [blocking] — the pending/failed subset, rejected rows excluded.
///   While this is above zero, logout is hard-blocked: these rows can
///   still sync, they just need connectivity, and throwing the phone
///   away mid-flight is exactly what the block exists to prevent.
typedef UnsyncedCounts = ({int total, int blocking});

/// Mobile-only logout: end the Supabase session, then wipe everything
/// this device has stored, so the next person to sign in on this phone
/// cannot see the previous person's data.
///
/// Never imported by the web build — it reaches for the local Drift
/// database, which cannot cross into web (dart:ffi). Web keeps using
/// AuthDomain.logOut, which only signs out of Supabase.
///
/// The order below is deliberate and must not be shuffled: Supabase
/// first, then local storage. gotrue removes the local session *before*
/// it calls the server (gotrue_client.dart, `_signOut`), so an offline
/// phone throws from `signOut()` only after this device is already
/// signed out — in that case the wipe still has to happen, otherwise
/// the user ends up signed out but staring at the previous cache.
class LogoutDomain {
  LogoutDomain({
    required SupabaseClient supabase,
    required LocalLogoutRepository localLogoutRepo,
    SyncService? syncService,
  })  : _supabase = supabase,
        _localLogoutRepo = localLogoutRepo,
        _syncService = syncService;

  final SupabaseClient _supabase;
  final LocalLogoutRepository _localLogoutRepo;

  /// The sync engine the logout flow uses to make a last-chance pass
  /// over the queue before asking the user what they're about to lose.
  /// Null only in tests that do not exercise the sync path.
  final SyncService? _syncService;

  /// How long the last-chance drain gets before the count is read from
  /// whatever the queue actually looks like at that moment — a slow
  /// or hanging connection must not freeze the logout flow.
  static const _drainTimeout = Duration(seconds: 15);

  /// Rows recorded on this device that have never reached Supabase,
  /// read before any dialog so the UI can decide what to show.
  ///
  /// Unlike the other automatic drains (connectivity, writes, login),
  /// this one is awaited: logout needs to know the post-drain state
  /// before deciding whether to hard-block, warn, or proceed silently.
  /// A timeout or partial pass is handled by counting what is
  /// genuinely still there.
  ///
  /// Returns both counts (see [UnsyncedCounts]): [UnsyncedCounts.total]
  /// for the informational warning — including rejected rows, which
  /// never sync and need manual resolution — and
  /// [UnsyncedCounts.blocking] for the hard block, which rejected rows
  /// are deliberately exempt from.
  Future<UnsyncedCounts> drainAndCountUnsyncedRows() async {
    if (_syncService != null) {
      try {
        await _syncService.drain().timeout(_drainTimeout);
      } on TimeoutException {
        // Timed out — take the queue's actual state, partial or all.
      }
    }
    final total = await _localLogoutRepo.countUnsyncedRows();
    final blocking = await _localLogoutRepo.countBlockingUnsyncedRows();
    return (total: total, blocking: blocking);
  }

  /// Runs the whole logout.
  ///
  /// Returns null when the server half succeeded too, or a message for
  /// Presentation to show when it did not (the usual case on a phone
  /// with no network). Throws [DomainException] only when local
  /// storage could not be wiped, or when even the local Supabase
  /// session could not be ended — Presentation must then show
  /// [DomainException.message] and stop, leaving the app signed in and
  /// the data intact so the person can retry.
  Future<String?> logOut() async {
    String? serverWarning;
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      // The local session is removed before the network call, so
      // check it really is gone before deciding this is survivable.
      if (_supabase.auth.currentSession != null) {
        throw DomainException('Could not sign out on this device: $e');
      }
      serverWarning = e is AuthRetryableFetchException
          ? 'You are signed out on this device, but the phone looks '
              'offline, so the server was never told. The online session '
              'may stay active until it expires.'
          : 'You are signed out on this device, but ending the online '
              'session failed (${e is AuthException ? e.message : e}). '
              'It may stay active until it expires.';
    }

    try {
      await _localLogoutRepo.clearAll();
    } catch (e) {
      throw DomainException(
        'Signed out, but the data stored on this phone could not be '
        'cleared ($e). Please try logging out again.',
      );
    }
    return serverWarning;
  }
}



/// Builds a [LogoutDomain]. Mobile only: importing this from web would
/// pull in the Drift database, which web must never reach.
final logoutDomainProvider = Provider<LogoutDomain>((ref) {
  return LogoutDomain(
    supabase: ref.watch(supabaseClientProvider),
    localLogoutRepo: ref.watch(localLogoutRepositoryProvider),
    syncService: ref.watch(syncServiceProvider),
  );
});
