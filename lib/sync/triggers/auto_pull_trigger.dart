import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import '../manual_sync.dart';
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
/// Failures on the automatic path are swallowed. Nobody is looking at a
/// phone when that happens, so there is nothing to show a message to; the
/// next trigger tries again. [syncNow] is the exception: it is the one
/// entry point somebody *is* waiting on, so it reports every outcome
/// instead of swallowing them.
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

  /// The one run in flight, if any.
  ///
  /// Shared by everything that can start work — the automatic triggers
  /// and [syncNow] alike — so at most one drain and one pull is ever
  /// going, whichever of them asked first. Held as the future itself so
  /// that a person who drags down while a run is already going joins that
  /// run and receives its result, rather than being turned away with
  /// nothing.
  ///
  /// Taken synchronously, before the account wait inside [_doSync], so two
  /// triggers arriving together while the account is still resolving
  /// produce one pull and not two.
  Future<ManualSyncOutcome>? _inFlight;

  /// Publicly readable so the periodic tick can skip rather than queue.
  bool get isRunning => _inFlight != null;

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
    if (isRunning) return;
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
  /// This is the *automatic* path — app start, app resume, the reconnect
  /// listener and the periodic timer — and it stays silent by design. It
  /// returns what the pull brought, or null when the run never got as far
  /// as pulling.
  ///
  /// Nothing should ever build a message out of that null. Five different
  /// things produce it: no session at all, a run already in flight, an
  /// account that could not be read, a session that ended while waiting,
  /// and a drain that threw. Only the last of those is anything like a
  /// network problem, and the caller cannot tell them apart. A person
  /// asking by hand goes through [syncNow], which says what actually
  /// happened.
  ///
  /// The guards, in order:
  ///   1. a session must exist at all — the cheap check, so a signed-out
  ///      phone costs nothing and never waits;
  ///   2. nothing else may be in flight;
  ///   3. a network, when [requireConnection] says this moment needs one;
  ///   4. [throttle], unless [bypassThrottle] is set.
  ///
  /// The account wait, the second session check, and the drain-then-pull
  /// itself live in [_doSync], past the single-flight claim in [_begin].
  ///
  /// [bypassThrottle] is for the periodic pull, which is on its own cadence
  /// and should not be held out by an earlier pass.
  ///
  /// [requireConnection] is for the two moments that can fire without a
  /// network (app start, app resume). The reconnect listener leaves it off,
  /// because it only runs once the network is already back. Deliberately
  /// never used by a manual sync: see [syncNow].
  Future<PullResult?> runNow({
    bool requireConnection = false,
    bool bypassThrottle = false,
  }) async {
    if (!_hasAccount()) return null;

    // A run already going is joined, not reported. An automatic caller has
    // nothing to say either way, so it waits for that run and returns
    // nothing of its own.
    final existing = _inFlight;
    if (existing != null) {
      await existing;
      return null;
    }

    // The connection gate. Failing it returns before the throttle is
    // even looked at, so an offline start or resume leaves the window
    // exactly as it found it and the next trigger is not penalised for
    // asking while there was no network.
    if (requireConnection && !await _isConnectedNowSafe()) return null;

    final last = _lastRunAt;
    if (!bypassThrottle &&
        last != null &&
        _now().difference(last) < throttle) {
      return null;
    }

    final outcome = await _begin();
    if (outcome is! ManualSyncCompleted) return null;

    final pull = outcome.pull;
    // The window opens only for a run that actually landed. A pull where
    // every table failed must not lock the app out for a minute: the next
    // trigger is precisely the retry it needs.
    if (pull.errors.length < pull.tablesPulled) _lastRunAt = _now();
    return pull;
  }

  /// One manual sync — the Sync now button and pull-to-refresh both come
  /// through here, and nothing else does.
  ///
  /// Unlike [runNow] this always attempts. No connectivity check decides
  /// whether to try: connectivity_plus reports radio status, not whether a
  /// request will actually get through, and its own API docs say so —
  /// "Do not use the result of this function to decide whether you can
  /// reliably make a network request." Gating on it refused syncs that
  /// would have worked and told people they were offline when they were
  /// not. What the request did is the honest signal, and [ManualSyncOutcome]
  /// says which kind of thing it was.
  ///
  /// The throttle is skipped for the same reason. A person who has just
  /// dragged a list down or tapped a button is not going to be told to
  /// wait a minute.
  ///
  /// Joins a run already in flight rather than starting a second one, and
  /// reports *that* run's result — so a drag down and a tap during one
  /// pass produce one pull and one message, not two of either.
  Future<ManualSyncOutcome> syncNow() async {
    if (!_hasAccount()) {
      return const ManualSyncSkipped(ManualSyncSkip.signedOut);
    }
    final existing = _inFlight;
    if (existing != null) return existing;
    return _begin();
  }

  /// Claims the single-flight slot and runs the work behind it.
  ///
  /// The slot is taken synchronously — before the account wait inside
  /// [_doSync] gets a chance to yield — so a second caller arriving while
  /// that wait is still open joins instead of doubling. Two triggers that
  /// land together therefore produce one pull, not two.
  Future<ManualSyncOutcome> _begin() {
    final run = _doSync();
    _inFlight = run;
    return run.whenComplete(() {
      if (identical(_inFlight, run)) _inFlight = null;
    });
  }

  /// The drain-then-pull itself, once every guard has let it through.
  ///
  /// Never throws. Every failure becomes an outcome, because the one
  /// caller with somebody to tell — [syncNow] — has to know which kind it
  /// was in order to say something true about it.
  Future<ManualSyncOutcome> _doSync() async {
    try {
      // Wait for the account behind the session. Anything that goes wrong
      // — an error, a null account, a wait that runs long — means this run
      // is skipped, and is emphatically not the network's doing.
      if (!await _accountReady()) {
        return const ManualSyncSkipped(ManualSyncSkip.accountNotReady);
      }

      // The session can have been ended while the account was resolving.
      if (!_hasAccount()) {
        return const ManualSyncSkipped(ManualSyncSkip.signedOut);
      }

      // Push first and awaited: a pull must never land on a row a push is
      // still trying to send.
      final push = await _syncService.drain();
      final pull = await _pullService.pullAll();
      if (pull.updated > 0) onChangesArrived?.call(pull.updated);
      // Any trigger at all re-arms the periodic timer, so signing back in
      // after a sign-out cancelled it brings it straight back.
      _syncPeriodic();
      return ManualSyncCompleted(push: push, pull: pull);
    } catch (e) {
      // Silent for the automatic callers — nobody is watching, and the
      // next trigger will try again. A run that threw never opened the
      // throttle window either, so that retry is not held up.
      return isNetworkFailure(e)
          ? const ManualSyncNetworkFailure()
          : ManualSyncFailed(e);
    }
  }

  /// [_isConnectedNow], but a failure to even ask is read as "no network"
  /// rather than escaping.
  ///
  /// This gate sits outside [_doSync]'s catch, and every automatic caller
  /// reaches it through an `unawaited`, so a throw here would surface as
  /// an unhandled error rather than as a skipped run.
  Future<bool> _isConnectedNowSafe() async {
    try {
      return await _isConnectedNow();
    } catch (_) {
      return false;
    }
  }
}