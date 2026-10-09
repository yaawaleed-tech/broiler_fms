/// What happened to one queue row during its push.
///
/// Pushers return this rather than throwing: a server-side rejection
/// is a normal outcome, not a crash, and the service — not the pusher —
/// decides what each outcome does to the queue.
abstract class SyncPushResult {
  const SyncPushResult();
}

/// The record reached Supabase, and the queue row can be removed.
class SyncPushSuccess extends SyncPushResult {
  const SyncPushSuccess();
}

/// The record is gone from local storage — the device was wiped while
/// it was still queued. There is nothing to push, and the queue row
/// must go too or it would sit there blocking every later pass.
class SyncPushDropped extends SyncPushResult {
  const SyncPushDropped();
}

/// The push did not get through, but a later pass might succeed: no
/// network, an RLS denial, a server-side error.
class SyncPushFailure extends SyncPushResult {
  const SyncPushFailure(this.error);

  final String error;
}

/// The server refused this row for good — the bird-count trigger
/// rejected a mortality/harvest row past the batch's limit. Retrying
/// can never fix that row, so the queue marks it rejected instead of
/// failing it again forever.
class SyncPushRejected extends SyncPushResult {
  const SyncPushRejected(this.error);

  final String error;
}

/// What one pass of the sync engine actually did.
///
/// Counts rather than per-row detail: the engine's callers (a status
/// line, a log entry) need to know how much work happened and what
/// went wrong, not the shape of every row. Individual failures are
/// also written to the queue itself, by the service.
class SyncResult {
  const SyncResult({
    this.pushed = 0,
    this.dropped = 0,
    this.failed = 0,
    this.rejected = 0,
    this.errors = const [],
  });

  /// Queue rows that reached Supabase.
  final int pushed;

  /// Queue rows discarded because their local record no longer exists,
  /// usually because the device was wiped while they were queued.
  final int dropped;

  /// Queue rows that failed and are still waiting for the next pass.
  final int failed;

  /// Queue rows the server rejected for good, flagged and left in the
  /// queue so logout can still warn about them.
  final int rejected;

  /// One line per failure, formatted as `table/recordId: error`.
  final List<String> errors;

  /// Nothing was waiting in the queue.
  bool get isEmpty => pushed + dropped + failed + rejected == 0;

  /// The queue drained without losing anything.
  bool get allSucceeded => failed == 0 && rejected == 0;

  @override
  String toString() => 'SyncResult(pushed: $pushed, dropped: $dropped, '
      'failed: $failed, rejected: $rejected, errors: $errors)';
}
