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
/// Staff receive the batches assigned to them and the entries on those
/// batches, so a Staff member sees a newly assigned batch without
/// signing out and back in. A Manager receives every batch of the
/// business, including what Staff have recorded on their own devices.
///
/// The work itself lives in [performManualSync], shared with
/// pull-to-refresh so the two cannot drift apart again. This widget owns
/// only the busy state and the words: whatever it says, a drag down on the
/// batch list says the same thing, because both read
/// [manualSyncMessage] off the same [ManualSyncOutcome].
///
/// [batchId] is passed when the host is a batch screen, so a completed
/// pull invalidates the providers that are currently on screen. They are
/// `autoDispose.family` providers that recompute on rebuild only, so
/// without this a pull would silently change the data underneath an
/// open screen and the figures would stay stale.
class SyncNowButton extends ConsumerStatefulWidget {
  const SyncNowButton({super.key, this.batchId});

  /// The batch whose detail and financial providers should be
  /// invalidated after a pull, when the host screen is about one batch.
  /// Null on the home screen, which has no such providers.
  final String? batchId;

  @override
  ConsumerState<SyncNowButton> createState() => _SyncNowButtonState();
}

class _SyncNowButtonState extends ConsumerState<SyncNowButton> {
  /// Local, and deliberately the only busy signal this widget has: the
  /// sync itself is single-flighted inside the trigger, so a second tap
  /// joins rather than doubling, and this only stops the icon flickering
  /// while that is true.
  bool _busy = false;

  Future<void> _sync() async {
    if (_busy) return;
    setState(() => _busy = true);

    final outcome = await performManualSync(
      ref,
      batchId: widget.batchId,
      isMounted: () => mounted,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    saySyncMessage(context, manualSyncMessage(outcome));
  }

  @override
  Widget build(BuildContext context) {
    final button = _busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.cloud_sync, size: 22);

    return Tooltip(
      message: 'Sync now',
      child: IconButton(
        onPressed: _busy ? null : _sync,
        // Both host screens sit on a rust AppBar with a cream
        // foreground, the same colour their titles and actions use.
        color: AppColors.card,
        disabledColor: AppColors.card.withValues(alpha: 0.5),
        icon: button,
      ),
    );
  }
}
