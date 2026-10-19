import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/presentation/mobile/batch/batch_detail_screen.dart';
import 'package:broiler_fms/presentation/mobile/financial/financial_summary_screen.dart';
import 'package:broiler_fms/sync/manual_sync.dart';
import 'package:broiler_fms/sync/pull_service.dart';
import 'package:broiler_fms/sync/sync_providers.dart';
import 'package:broiler_fms/sync/sync_result.dart';

/// Runs one manual sync and leaves the open screens showing whatever came
/// back. The Sync now button and pull-to-refresh both come through here,
/// and nothing else does.
///
/// The split exists so the two cannot drift apart again. They used to do
/// the same work in two different places, and pull-to-refresh turned every
/// "did not run" into a no-internet snackbar while the button said nothing
/// at all — including when a periodic pull was already in flight, which is
/// most of the time the message appeared.
///
/// No connectivity check stands between the caller and the attempt.
/// `connectivity_plus` reports radio status rather than whether a request
/// will get through, and its own API docs say not to decide on it; gating
/// a sync on it refused syncs that would have worked. What the request did
/// is the signal, and [manualSyncMessage] turns it into words.
///
/// [isMounted] is required rather than assumed: this awaits, and a widget
/// that has gone away by the time the sync lands must not have its `ref`
/// touched. Callers pass `() => mounted` (a `ConsumerState`) or
/// `() => ref.context.mounted`.
Future<ManualSyncOutcome> performManualSync(
  WidgetRef ref, {
  String? batchId,
  required bool Function() isMounted,
}) async {
  final outcome = await ref.read(autoPullTriggerProvider).syncNow();

  // A skip did no work, so there is nothing on screen to update. Every
  // other outcome may have pushed rows the queue has since dropped, or
  // pulled rows the cache has since stored.
  if (outcome is! ManualSyncSkipped && isMounted()) {
    // The "_Online · N pending" pill reads the queue's live count, which
    // the drain above may just have emptied.
    ref.invalidate(syncStatusProvider);
    // The two autoDispose.family providers that only recompute when
    // invalidated. Invalidating a family nobody is watching is a no-op,
    // so this is safe from any screen.
    if (batchId == null) {
      ref.invalidate(batchDetailProvider);
      ref.invalidate(financialSummaryProvider);
    } else {
      ref.invalidate(batchDetailProvider(batchId));
      ref.invalidate(financialSummaryProvider(batchId));
    }
  }
  return outcome;
}

/// The one place a manual sync turns into words.
///
/// Returns null when there is nothing worth saying: a person with no
/// session has no sync to report, and the Sync now button has always come
/// back quiet in that case.
///
/// "No internet connection." is reached from exactly one branch —
/// [ManualSyncNetworkFailure], which only a socket, HTTP client or timeout
/// can produce. A skipped run, a run that joined one already going, an
/// account that is not ready yet, and a table that the server refused all
/// say something true instead. That separation is the whole point: the old
/// code collapsed all of them into one `null` and blamed the network.
String? manualSyncMessage(ManualSyncOutcome outcome) {
  switch (outcome) {
    case ManualSyncSkipped(:final reason):
      return switch (reason) {
        ManualSyncSkip.signedOut => null,
        ManualSyncSkip.accountNotReady =>
          "Your account isn't ready yet. Try again in a moment.",
      };
    case ManualSyncNetworkFailure():
      return noInternetMessage;
    case ManualSyncFailed(:final error):
      return 'Sync failed: $error';
    case ManualSyncCompleted(:final push, :final pull):
      return completedSyncMessage(push, pull);
  }
}

/// The wording used for a genuine network failure, wherever the app meets
/// one — the login flow, and now a sync whose own request did not get
/// through.
const noInternetMessage =
    'No internet connection. Check your network and try again.';

/// What to say about a sync that ran to the end. Problems are reported
/// ahead of successes, and every one of them is derived from what actually
/// happened rather than from a guess made beforehand.
///
/// A failed or rejected row is the only thing in this outcome the person
/// can do something about, so it leads; a cheerful "3 sent, 40 updated"
/// would bury it.
String completedSyncMessage(SyncResult push, PullResult pull) {
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

  // Every table failing means nothing reached the server at all. That is
  // a statement about the result, not about the radio, so it does not
  // claim the device is offline.
  if (pull.errors.isNotEmpty) {
    final everyTable = pull.errors.length >= pull.tablesPulled;
    problems.add(
      everyTable
          ? "Couldn't reach the server. We'll sync when you're back online."
          : '${pull.errors.length} of ${pull.tablesPulled} data tables '
              "couldn't be refreshed from the server.",
    );
  }
  if (problems.isNotEmpty) return problems.join(' ');

  return syncOutcomeMessage(push.pushed, pull.updated);
}

/// The one-line report of a sync that had no problems to report: what went
/// up, and what came down that was actually new.
///
/// Deliberately free of any role logic: the same words are right for every
/// role, because [updated] already counts only rows that were genuinely
/// new or different — a row already cached unchanged is neither rewritten
/// nor counted.
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

/// Says [message] through the scaffold messenger, replacing whatever is
/// already showing. A null message means "nothing worth saying" and is
/// ignored, so every caller can pass [manualSyncMessage]'s result straight
/// through without a branch.
void saySyncMessage(BuildContext context, String? message) {
  if (message == null) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
