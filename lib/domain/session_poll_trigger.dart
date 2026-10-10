import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';

/// Message carried to the login screen when a session poll forces a
/// logout, so the person knows this was not a voluntary sign-out.
const forcedLogoutMessage =
    'Your access has changed. Please sign in again.';

/// Polls "is my session still valid" on a timer, for forced logout.
///
/// Mirrors LifecycleSyncTrigger's shape on purpose: a plain class
/// wrapping a Timer with start/stop/dispose, owned by a provider with
/// ref.onDispose cleanup, started and stopped by the widget watching
/// it.
///
/// Every [interval], it calls the session_is_active() RPC, which
/// answers from the account's *current* status (including the
/// business-cascade for Manager/Staff), so a deactivation made from
/// another device is picked up without re-running login:
///
/// * explicit false → the session lost access: [onAccessLost] runs
///   (the watching widget's forced-logout sequence).
/// * anything else — true, or any error (offline, timeout,
///   PostgrestException) — means "unknown, assume still valid": stay
///   logged in and try again next tick. An offline-first phone in
///   poor connectivity must never be logged out by a failed poll.
///
/// Ticks with no signed-in session are skipped outright, so one
/// trigger instance can live at an app root that outlives login.
class SessionPollTrigger {
  SessionPollTrigger(
    this._client, {
    this.interval = const Duration(seconds: 30),
  });

  final SupabaseClient _client;
  final Duration interval;
  Timer? _timer;

  /// Runs when a poll explicitly reports the session lost access. Set
  /// by the watching widget; may be async (logout writes).
  Future<void> Function()? onAccessLost;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _pollOnce());
  }

  void stop() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
  }

  Future<void> _pollOnce() async {
    if (_client.auth.currentUser == null) return;
    var lost = false;
    try {
      final active = await _client.rpc('session_is_active') as bool?;
      lost = active == false;
    } catch (_) {
      return;
    }
    if (lost) {
      try {
        await onAccessLost?.call();
      } catch (_) {
        // The watching widget owns logout errors; a failed attempt
        // simply retries on the next tick.
      }
    }
  }
}

/// How often a signed-in session re-checks its own validity.
///
/// Thirty seconds: fast enough that a deactivation lands within half
/// a minute, slow enough to be noise-level traffic. A provider rather
/// than a hard-coded default so tests can shorten it instead of
/// waiting out the full window.
final sessionPollIntervalProvider =
    Provider<Duration>((ref) => const Duration(seconds: 30));

/// The one session poller, shared the way the sync triggers are:
/// created on first watch, cleaned up when the scope goes away. The
/// watching widget starts and stops it; only one authenticated root
/// is ever mounted at a time, so callbacks never collide.
final sessionPollTriggerProvider = Provider<SessionPollTrigger>((ref) {
  final trigger = SessionPollTrigger(
    ref.watch(supabaseClientProvider),
    interval: ref.watch(sessionPollIntervalProvider),
  );
  ref.onDispose(trigger.dispose);
  return trigger;
});
