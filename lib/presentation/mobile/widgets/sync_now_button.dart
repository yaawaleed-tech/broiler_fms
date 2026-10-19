import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/presentation/mobile/batch/batch_detail_screen.dart';
import 'package:broiler_fms/presentation/mobile/financial/financial_summary_screen.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/sync/pull_service.dart';
import 'package:broiler_fms/sync/sync_providers.dart';
import 'package:broiler_fms/sync/sync_result.dart';

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
/// The drain is awaited rather than fired and forgotten like the
/// automatic triggers: this action is user-initiated, so it reports its
/// own outcome and must not have a pull land while its own push is
/// still in flight.
///
/// Pass [batchId] when the host is a batch screen, so a completed pull
/// invalidates the providers that are currently on screen. They are
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
  /// Covers both phases, the push and the pull. SyncService.isDraining
  /// only tells us about the push and is not something a widget can
  /// rebuild on, so local state is the honest signal for the whole
  /// operation.
  bool _busy = false;

  Future<void> _sync() async {
    if (_busy) return;
    final account = ref.read(currentAccountProvider).value;
    if (account == null) return;

    // Deliberately no connectivity_plus check before this point. That
    // plugin reports radio/interface status, not whether a request will
    // actually get through, and its own API docs say so: "Do not use
    // the result of this function to decide whether you can reliably
    // make a network request, it only gives you the radio status."
    // Gating on it refused syncs that would have worked, and told people
    // they were offline when they were not. The outcome of the work
    // below is the honest signal, and it is what the message reports.

    setState(() => _busy = true);
    SyncResult pushResult;
    PullResult? pullResult;
    try {
      // Awaited, unlike the automatic triggers: the pull below must not
      // start until this push has finished, or a row still waiting to go
      // up could be overwritten by the server's older copy of itself.
      // drain() joins a pass already in flight rather than starting a
      // second one, so a tap during the debounced auto-drain is safe.
      pushResult = await ref.read(syncServiceProvider).drain();
      pullResult = await ref.read(pullServiceProvider).pullAll();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _say('Sync failed: $e');
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    // After the drain and the pull, re-read the sync queue's
    // current state so the "_Online · N pending" pill updates immediately
    // rather than waiting for the next connectivity change event.
    ref.invalidate(syncStatusProvider);
    if (!mounted) return;
    _invalidateOpenBatchProviders();
    _say(_message(pushResult, pullResult));
  }

  /// Drops the cached reads for the batch on screen so they recompute
  /// against the freshly pulled data.
  ///
  /// Invalidating a provider nobody is watching is a no-op, so this is
  /// safe to call from a screen that is not currently showing either of
  /// these.
  void _invalidateOpenBatchProviders() {
    final batchId = widget.batchId;
    if (batchId == null) return;
    ref.invalidate(batchDetailProvider(batchId));
    ref.invalidate(financialSummaryProvider(batchId));
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Problems are reported ahead of successes, and every one of them is
  /// derived from what actually happened rather than from a guess made
  /// beforehand. A failed or rejected row is the only thing in this
  /// outcome the person can do something about, so it leads; a cheerful
  /// "3 sent, 40 updated" would bury it.
  String _message(SyncResult push, PullResult? pull) {
    final problems = <String>[];

    if (push.rejected > 0) {
      problems.add(
        '${push.rejected} ${push.rejected == 1 ? 'entry was' : 'entries were'} '
        'rejected by the server and will never upload. Open the batch to '
        'check its counts.',
      );
    }
    if (push.failed > 0) {
      problems.add(
        '${push.failed} ${push.failed == 1 ? "entry couldn't" : "entries couldn't"} '
        'be sent — check your connection.',
      );
    }

    // A pull that failed on every table means nothing reached the server
    // at all, which is the one case genuinely worth calling offline —
    // and it is now a statement about the result, not about the radio.
    final pullErrors = pull?.errors ?? const <String>[];
    if (pullErrors.isNotEmpty) {
      final everyTable = pull != null && pull.errors.length >= pull.tablesPulled;
      problems.add(
        everyTable
            ? "Couldn't reach the server. We'll sync when you're back online."
            : '${pullErrors.length} of ${pull!.tablesPulled} data tables '
                "couldn't be refreshed from the server.",
      );
    }
    if (problems.isNotEmpty) return problems.join(' ');

    return syncOutcomeMessage(push.pushed, pull?.updated ?? 0);
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

/// The one-line report of a sync that had no problems to report: what went
/// up, and what came down that was actually new.
///
/// Split out from [_SyncNowButtonState._message] so it can be tested on
/// its own, and deliberately free of any role logic: the same words are
/// right for every role, because [updated] already counts only real
/// changes.
///
/// * [pushed] — queue rows that reached Supabase.
/// * [updated] — rows the pull found new or different, zero when nothing
///   had changed on the server.
String syncOutcomeMessage(int pushed, int updated) {
  if (pushed == 0 && updated == 0) return 'Already up to date.';

  final sent = '$pushed ${pushed == 1 ? 'entry' : 'entries'} sent';
  final received =
      '$updated ${updated == 1 ? 'change' : 'changes'} received';

  if (pushed == 0) return received;
  if (updated == 0) return sent;
  return '$sent, $received';
}
