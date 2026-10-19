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
    this.periodicInterval = defaultPeriodicInterval,
    bool Function()? hasAccount,
    Future<bool> Function()? accountReady,
    Future<bool> Function()? isConnected,
    DateTime Function()? now,
  })  : _connectivity = connectivity ?? Connectivity(),
        _isConnectedOverride = isConnected,
        _hasAccount = hasAccount ?? (() => false),
        _accountReady = accountReady ?? (() async => true),
        _now = now ?? DateTime.now;

  /// How often the periodic pull asks for fresh data while the app is
  /// open. One named constant so the cadence can be changed in one place.
  static const Duration defaultPeriodicInterval = Duration(seconds: 45);

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

  /// Gap between periodic pulls. See [defaultPeriodicInterval].
  final Duration periodicInterval;

  /// Whether an account is signed in. Injected so the trigger does not
  /// have to know how the app stores that, and so tests can drive it.
  final bool Function() _hasAccount;

  /// Resolves once the account behind that session is actually readable,
  /// false if it never becomes readable (error, null, or the wait times
  /// out).
  ///
  /// This is what closes the cold-start race. [hasAccount] answers "is
  /// there a session", which is true the moment Supabase restores one —
  /// well before the account has been read out of the local cache, and so
  /// long before the Domain classes behind a pull can be built. Asking
  /// for readiness here means the first pull waits instead of failing
  /// silently on every table.
  final Future<bool> Function() _accountReady;

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

  /// Publicly readable so the periodic tick can skip rather than queue.
  bool get isRunning => _running;

  /// The periodic pull's timer. Lives only while the app is in the
  /// foreground with somebody signed in.
  Timer? _periodic;

  /// False as soon as the app leaves the foreground, so no tick is even
  /// scheduled while nobody is looking.
  bool _foreground = true;

  /// When the last *successful* run finished, or null if none has.
  /// A failed run does not move it, which is what lets the next trigger
  /// retry immediately.
  DateTime? _lastRunAt;

  /// Idempotent: starting twice would register the observer and the
  /// connectivity listener twice, and every event would run twice.
  void start() {
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _subscription ??= _connectivity.onConnectivityChanged.listen((result) {
      if (!result.contains(ConnectivityResult.none)) {
        unawaited(runNow());
      }
    });
    _syncPeriodic();
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _subscription = null;
    _periodic?.cancel();
    _periodic = null;
  }

  /// Keeps the periodic timer running exactly while the app is in the
  /// foreground. Backgrounded, it is cancelled outright: there is nothing
  /// to look at, and a background phone is one the OS may not even wake
  /// for.
  void _syncPeriodic() {
    // Only once started: a trigger nobody has started has no reason to be
    // waking anything up on a timer.
    if (!_started) return;
    final wanted = _foreground && !_disposed;
    if (!wanted) {
      _periodic?.cancel();
      _periodic = null;
      return;
    }
    _periodic ??= Timer.periodic(periodicInterval, (_) => unawaited(_tick()));
  }

  /// True once [dispose] has run, so a tick that was already scheduled
  /// cannot re-arm the timer behind the widget's back.
  bool _disposed = false;

  /// True once [start] has run. The periodic timer exists only for a
  /// trigger the app actually started.
  bool _started = false;

  /// One periodic tick. Skips quietly when a pull is already running, when
  /// there is no network, or when nobody is signed in — and never throws,
  /// because nobody is watching a timer fire.
  Future<void> _tick() async {
    if (_disposed) return;
    if (!_hasAccount()) {
      // Signed out: stop entirely rather than keep waking up to do
      // nothing. Any later trigger starts it again.
      _periodic?.cancel();
      _periodic = null;
      return;
    }
    if (_running) return;
    if (!await _isConnectedNow()) return;
    await runNow(bypassThrottle: true);
    // Re-arm if the tick above cancelled it, or if a previous sign-out did.
    _syncPeriodic();
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
    // The periodic pull only ever runs in the foreground, so the timer is
    // armed and cancelled from here rather than checked inside itself.
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
        _syncPeriodic();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _foreground = false;
        _syncPeriodic();
    }
    // Pausing and resuming fire as a pair; the resume is the moment worth
    // syncing, and the one that means the device may have been away for a
    // while with a different Staff member or Manager on another phone.
    if (state == AppLifecycleState.resumed) {
      unawaited(runNow(requireConnection: true));
    }
  }

  /// Runs a drain and then a pull, unless one of the guards says no.
  ///
  /// Returns what the pull brought, or null when the run never got as far
  /// as pulling — so a caller that asked for it (pull-to-refresh) can tell
  /// "nothing changed" from "nothing ran".
  ///
  /// The guards, in order:
  ///   1. a session must exist at all — the cheap check, so a signed-out
  ///      phone costs nothing and never waits;
  ///   2. the account behind that session must be readable (see
  ///      [accountReady]), which is what makes the cold start wait rather
  ///      than fail;
  ///   3. the session must still exist — somebody can sign out while this
  ///      is waiting;
  ///   4. nothing else may be in flight;
  ///   5. a network, when [requireConnection] says this moment needs one;
  ///   6. [throttle], unless [bypassThrottle] is set.
  ///
  /// [bypassThrottle] is for a person asking now — pull-to-refresh, or
  /// the periodic pull — who should never be told to wait. It does not
  /// bypass the in-flight guard: a second ask joins the run already going.
  ///
  /// [requireConnection] is for the two moments that can fire without a
  /// network (app start, app resume). The reconnect listener leaves it off,
  /// because it only runs once the network is already back.
  Future<PullResult?> runNow({
    bool requireConnection = false,
    bool bypassThrottle = false,
  }) async {
    if (!_hasAccount()) return null;
    if (_running) return null;

    // Claimed before the first await, so a run still waiting for the
    // account cannot be joined by a second trigger — and so two triggers
    // arriving together produce one pull, not two.
    _running = true;
    try {
      // Wait for the account behind the session. Anything that goes wrong
      // — an error, a null account, a wait that runs long — simply means
      // this run is skipped. Never a throw: nothing is watching.
      if (!await _accountReady()) return null;

      // The session can have been ended while the account was resolving.
      if (!_hasAccount()) return null;

      // The connection gate. Failing it returns before the throttle is
      // even looked at, so an offline start or resume leaves the window
      // exactly as it found it and the next trigger is not penalised for
      // asking while there was no network.
      if (requireConnection && !await _isConnectedNow()) return null;

      final last = _lastRunAt;
      if (!bypassThrottle &&
          last != null &&
          _now().difference(last) < throttle) {
        return null;
      }

      await _syncService.drain();
      final result = await _pullService.pullAll();
      // The window opens only for a run that actually landed. A pull where
      // every table failed must not lock the app out for a minute: the next
      // trigger is precisely the retry it needs.
      if (result.errors.length < result.tablesPulled) _lastRunAt = _now();
      final updated = result.updated;
      if (updated > 0) onChangesArrived?.call(updated);
      // Any trigger at all re-arms the periodic timer, so signing back in
      // after a sign-out cancelled it brings it straight back.
      _syncPeriodic();
      return result;
    } catch (_) {
      // Silent by design: nobody is watching, and the next trigger will
      // try again. A run that threw never opened the window either, so
      // that retry is not held up.
      return null;
    } finally {
      _running = false;
    }
  }

  /// A pull asked for by hand — pull-to-refresh.
  ///
  /// Same drain-then-pull, same guards, same single-flight: only the
  /// throttle is skipped, because somebody who has just dragged the list
  /// down should not be told to wait for the next automatic pass. A pull
  /// already running is joined, never doubled.
  ///
  /// Returns null when the run never reached a pull.
  Future<PullResult?> refreshNow() => runNow(bypassThrottle: true);
}