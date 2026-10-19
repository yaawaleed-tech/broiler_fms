import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import '../pull_service.dart';
import '../sync_service.dart';

/// Runs a drain and then a pull automatically, for every role alike.
///
/// Three things can start a run — the app opening, the app coming back to
/// the foreground, and the network coming back — and all three share one
/// throttle and one in-flight guard, so a phone that wakes up while
/// offline does not fire three passes in a row when it reconnects.
///
/// App start and app resume check there is a network first and do nothing
/// at all without one. The reconnect trigger skips that check, since the
/// network coming back is the whole point of it.
///
/// The shared throttle only opens for a run that succeeded. A failed run
/// leaves no window behind it, so whatever triggers next retries at once.
///
/// There is deliberately no role check anywhere in this file. What each
/// account receives is decided by Row Level Security on the pull, not by
/// anything here: a Manager gets their whole business, a Staff member gets
/// the batches assigned to them. The only question this trigger asks is
/// whether somebody is signed in.
///
/// The push always runs first and is awaited, because a pull must never
/// land on a row a push is still trying to send.
///
/// Failures are swallowed. Nobody is looking at a phone when this happens,
/// so there is nothing to show a message to; the next trigger tries again.
///
/// [onChangesArrived] is called after a run that actually brought
/// something back — see `AutoPullHost` in the presentation layer, which is
/// where the providers that need refreshing are invalidated. This class
/// stays free of any presentation import so `lib/sync` keeps no dependency
/// on `lib/presentation`.
class AutoPullTrigger with WidgetsBindingObserver {
  AutoPullTrigger(
    this._syncService,
    this._pullService, {
    Connectivity? connectivity,
    this.throttle = const Duration(seconds: 60),
    bool Function()? hasAccount,
    Future<bool> Function()? isConnected,
    DateTime Function()? now,
  })  : _connectivity = connectivity ?? Connectivity(),
        _isConnectedOverride = isConnected,
        _hasAccount = hasAccount ?? (() => false),
        _now = now ?? DateTime.now;

  final SyncService _syncService;
  final PullService _pullService;
  final Connectivity _connectivity;

  /// How long to wait after a run before allowing another one.
  ///
  /// The window opens when a run *finishes successfully* — when at least
  /// one table came down without error — and is counted from that moment.
  /// A run that failed, or that never started because there was no
  /// network, leaves no window at all, so the next trigger is free to
  /// retry straight away.
  final Duration throttle;

  /// Whether an account is signed in. Injected so the trigger does not
  /// have to know how the app stores that, and so tests can drive it.
  final bool Function() _hasAccount;

  /// Injectable clock, so the throttle can be tested without waiting a
  /// minute for it.
  final DateTime Function() _now;

  /// Set only by tests. When null the connection is read from the same
  /// [Connectivity] the reconnect listener uses.
  final Future<bool> Function()? _isConnectedOverride;

  /// Whether the phone currently has a network, checked the same way the
  /// reconnect trigger checks it.
  Future<bool> _isConnectedNow() async {
    final override = _isConnectedOverride;
    if (override != null) return override();
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  /// Called with the number of genuinely new or changed rows when a run
  /// brought something back. Left null by anything that has no
  /// presentation to refresh.
  void Function(int updated)? onChangesArrived;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// True while a run is in progress, so overlapping triggers are skipped.
  bool _running = false;

  /// When the last *successful* run finished, or null if none has.
  /// A failed run does not move it, which is what lets the next trigger
  /// retry immediately.
  DateTime? _lastRunAt;

  /// Idempotent: starting twice would register the observer and the
  /// connectivity listener twice, and every event would run twice.
  void start() {
    WidgetsBinding.instance.addObserver(this);
    _subscription ??= _connectivity.onConnectivityChanged.listen((result) {
      if (!result.contains(ConnectivityResult.none)) {
        unawaited(runNow());
      }
    });
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _subscription = null;
  }

  /// Opening the app is one of the three moments a run is wanted.
  ///
  /// Named so the wiring layer can call it explicitly once an account is
  /// known, rather than this class guessing when that happens.
  ///
  /// Requires a network: opening the app offline should cost nothing and
  /// change nothing.
  void onAppStart() => unawaited(runNow(requireConnection: true));

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pausing and resuming fire as a pair; the resume is the moment worth
    // syncing, and the one that means the device may have been away for a
    // while with a different Staff member or Manager on another phone.
    if (state == AppLifecycleState.resumed) {
      unawaited(runNow(requireConnection: true));
    }
  }

  /// Runs a drain and then a pull, unless one of the guards says no.
  ///
  /// Returns without doing anything when there is nobody signed in, when a
  /// run is already in flight, when the last successful one finished less
  /// than [throttle] ago, or — if [requireConnection] is set — when the
  /// phone is offline.
  ///
  /// [requireConnection] is for the two moments that can fire without a
  /// network (app start, app resume). The reconnect listener leaves it off,
  /// because it only runs once the network is already back.
  Future<void> runNow({bool requireConnection = false}) async {
    if (!_hasAccount()) return;
    if (_running) return;

    // Claimed before the first await, so a run still waiting on the
    // connectivity check cannot be joined by a second trigger.
    _running = true;
    try {
      // The connection gate. Failing it returns before the throttle is
      // even looked at, so an offline start or resume leaves the window
      // exactly as it found it and the next trigger is not penalised for
      // asking while there was no network.
      if (requireConnection && !await _isConnectedNow()) return;

      final last = _lastRunAt;
      if (last != null && _now().difference(last) < throttle) return;

      await _syncService.drain();
      final result = await _pullService.pullAll();
      // The window opens only for a run that actually landed. A pull where
      // every table failed must not lock the app out for a minute: the next
      // trigger is precisely the retry it needs.
      if (result.errors.length < result.tablesPulled) _lastRunAt = _now();
      final updated = result.updated;
      if (updated > 0) onChangesArrived?.call(updated);
    } catch (_) {
      // Silent by design: nobody is watching, and the next trigger will
      // try again. A run that threw never opened the window either, so
      // that retry is not held up.
    } finally {
      _running = false;
    }
  }
}