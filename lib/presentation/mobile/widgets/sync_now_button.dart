import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/presentation/shared/sync_action.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';

export 'package:broiler_fms/presentation/shared/sync_action.dart'
    show syncOutcomeMessage;

/// The mobile app's manual "Sync now" action, the same for every role:
/// it pushes the waiting entries, then pulls the data the signed-in
/// account is allowed to see. Row Level Security decides what each
/// role receives, so the button needs no role logic of its own.
///
/// The work itself lives in [performManualSync], shared with
/// pull-to-refresh so the two cannot drift apart again. This widget owns
/// only the busy state and the words: whatever it says, a drag down on the
/// batch list says the same thing, because both read
/// [manualSyncMessage] off the same [ManualSyncOutcome].
///
/// While a sync runs the icon does not go away. It turns, in the same
/// cream it wears at rest, inside the same 48×48 tap target, so nothing
/// jumps and nothing vanishes. It used to be swapped for a
/// `CircularProgressIndicator` that picked up the theme's primary — which
/// *is* the rust of the AppBar behind it — so the person saw the button
/// disappear into the bar instead of see it work.
///
/// [batchId] is passed when the host is a batch screen, so a completed
/// pull invalidates the providers that are currently on screen.
class SyncNowButton extends ConsumerStatefulWidget {
  const SyncNowButton({super.key, this.batchId});

  /// The batch whose detail and financial providers should be
  /// invalidated after a pull, when the host screen is about one batch.
  /// Null on the home screen, which has no such providers.
  final String? batchId;

  @override
  ConsumerState<SyncNowButton> createState() => _SyncNowButtonState();
}

class _SyncNowButtonState extends ConsumerState<SyncNowButton>
    with SingleTickerProviderStateMixin {
  /// One full turn. Named so the cadence can be tuned in one place, and
  /// kept inside the 800–1000 ms band where a rotation reads as "working"
  /// rather than as a strobe.
  static const Duration _revolution = Duration(milliseconds: 800);

  /// The shortest stretch the icon is allowed to keep turning after a
  /// tap, however quickly the sync itself finishes.
  ///
  /// Without this a sync that lands on the first frame turns for a few
  /// milliseconds and the person never sees that anything happened. The
  /// stop rule keeps turning until *both* this floor and a whole number
  /// of turns have gone by, so the icon never freezes mid-rotation.
  ///
  /// At the default it coincides with [_revolution] — one turn is the
  /// floor — but they are separate constants so either can be raised
  /// without silently changing the other.
  static const Duration _minimumSpin = Duration(milliseconds: 800);

  /// The busy halo behind the icon. Quiet enough to sit under the cream
  /// glyph, loud enough to tell "working" from "at rest" without the
  /// icon having to move at all — which is what makes the reduced-motion
  /// state readable.
  static const double _haloSize = 34;

  /// The glyph's own box, identical in every state.
  static const double _targetSize = 48;

  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: _revolution,
  );

  /// Turns the controller has completed during the current busy stretch,
  /// counted from the controller's own ticks rather than from the wall
  /// clock, so the minimum can be measured under a test's fake time.
  int _completedTurns = 0;
  double _lastSpinValue = 0;

  /// True from the moment a sync starts until [performManualSync] returns.
  /// This — and only this — is what ignores a second tap.
  bool _busy = false;

  /// True from the moment a sync starts until the icon has come to rest
  /// again. Wider than [_busy] on purpose: the sync may be over while the
  /// icon is still finishing its turn, and the chrome should not blink off
  /// in that gap.
  bool _spinning = false;

  /// Bumped every time a sync starts, so a stop routine left over from an
  /// earlier sync cannot halt a later one. See [_endSpin].
  int _spinGeneration = 0;

  @override
  void initState() {
    super.initState();
    // Forced here rather than in a field initializer or a constructor:
    // creating the controller needs a mounted element for its ticker, and
    // createState() runs before the element exists.
    _spin.addListener(_noteSpin);
  }

  void _noteSpin() {
    final value = _spin.value;
    // The controller wraps from 1 back to 0 on every completed turn.
    if (value < _lastSpinValue) _completedTurns++;
    _lastSpinValue = value;
  }

  /// How long the icon has been turning for, measured off the controller.
  Duration get _busyElapsed =>
      _revolution * _completedTurns + _revolution * _spin.value;

  Future<void> _sync() async {
    if (_busy) return;
    final generation = ++_spinGeneration;
    setState(() {
      _busy = true;
      _spinning = true;
      _completedTurns = 0;
      _lastSpinValue = 0;
    });
    // Only if it is not already turning: a sync that starts while the
    // previous one is still finishing its turn continues that rotation
    // rather than snapping back to zero and starting again.
    if (!_spin.isAnimating) _spin.repeat();

    final outcome = await performManualSync(
      ref,
      batchId: widget.batchId,
      isMounted: () => mounted,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    saySyncMessage(context, manualSyncMessage(outcome));

    await _endSpin(generation);
    if (!mounted || _spinning == false) return;
    setState(() => _spinning = false);
  }

  /// Brings the icon to rest: not before [_minimumSpin] has gone by, and
  /// not mid-turn either.
  ///
  /// [generation] is the value of [_spinGeneration] when this sync began.
  /// If another sync has started meanwhile this returns without touching
  /// the controller, so a rapid busy → off → busy neither stacks
  /// animations nor halts the one now running.
  Future<void> _endSpin(int generation) async {
    final remaining = _minimumSpin - _busyElapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted || generation != _spinGeneration) return;

    // Finish the turn rather than freeze wherever the icon happens to be
    // pointing. animateTo stops the repeat for us and covers only the
    // fraction of the turn still to go.
    if (_spin.value > 0 && _spin.value < 1) {
      await _spin.animateTo(1);
    }
    if (!mounted || generation != _spinGeneration) return;

    _spin.stop();
    // Set after the stop: assigning the value notifies the listener, and
    // the counters must be clean for the next sync by the time it reads
    // them.
    _spin.value = 0;
    _completedTurns = 0;
    _lastSpinValue = 0;
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final rotating = _spinning && !disableAnimations;

    // The idle colour, used in every state. An explicit colour rather than
    // whatever IconButton derives for us: while the button is disabled
    // that derivation is the faded disabled tint, which is half of why the
    // old spinner vanished. The other half was the theme's primary, which
    // is the very rust of the bar behind it.
    const glyph = Icon(Icons.cloud_sync, size: 22, color: AppColors.card);

    final Widget face;
    if (rotating) {
      face = RotationTransition(turns: _spin, child: glyph);
    } else if (disableAnimations && _spinning) {
      // Reduced motion: no rotation, so the icon plainly steps back and a
      // static marker carries the state instead.
      face = const Opacity(opacity: 0.45, child: glyph);
    } else {
      face = glyph;
    }

    // Always the same 48×48, busy or not. IconButton's own padding sits
    // outside this, so nothing about the halo's width can reach the
    // AppBar row — a 34-wide stack under the default 8-point padding
    // would measure 50 and the row would jump by two pixels the moment a
    // sync started.
    final Widget content = SizedBox(
      width: _targetSize,
      height: _targetSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (_spinning) ...[
            const SizedBox(
              width: _haloSize,
              height: _haloSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _busyHalo,
                ),
              ),
            ),
            if (disableAnimations)
              const Positioned(
                right: 0,
                top: 0,
                child: SizedBox(
                  width: 8,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.card,
                    ),
                  ),
                ),
              ),
          ],
          face,
        ],
      ),
    );

    return Tooltip(
      message: 'Sync now',
      child: Semantics(
        // Announced rather than merely drawn, so a screen reader is told
        // the same thing the eye is.
        label: _busy ? 'Syncing' : null,
        child: IconButton(
          onPressed: _busy ? null : _sync,
          // Both host screens sit on a rust AppBar with a cream
          // foreground, the same colour their titles and actions use.
          color: AppColors.card,
          // Never the faded tint. The glyph carries an explicit colour so
          // this is belt-and-braces, but it keeps anything theme-derived
          // honest too.
          disabledColor: AppColors.card,
          iconSize: 22,
          // Zero here because the fixed box above is the whole tap
          // target; leaving IconButton's padding in would add 8 points
          // on every side and make the real target 64.
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(
            width: _targetSize,
            height: _targetSize,
          ),
          icon: content,
        ),
      ),
    );
  }
}

/// Cream at a low alpha, for the halo behind a working icon.
const _busyHalo = Color.fromARGB(0x29, 0xFB, 0xF8, 0xF1);
