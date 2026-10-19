/// Change detection for the pull direction, shared by the eight local
/// repositories whose `upsertAll` runs after every pull.
///
/// Before this, each `upsertAll` handed *every* fetched row to
/// `insertAllOnConflictUpdate` and returned that row count, so a pull of
/// unchanged data still reported — and rewrote — all of it. The sync
/// button then said "Synced. 0 sent, 40 updated from server." for a pull
/// that had changed nothing. These two small functions let each
/// repository work out which rows are genuinely new or different, and
/// count only those.
///
/// This file holds no logic about any particular table. Each repository
/// supplies its own field-by-field comparison, so adding a column to a
/// model cannot silently stop it being compared: the compiler asks.
library;

/// True when two instants are the same *as the database stores them*.
///
/// Drift writes `dateTime()` columns as whole seconds, so a value with
/// sub-second precision loses it on the way in and comes back truncated.
/// Comparing with `==` would therefore report a difference for every row
/// whose timestamp had microseconds, on every pull, forever.
///
/// Comparison is on the epoch-second value rather than on the `DateTime`
/// object, which also absorbs the timezone difference: `fromJson` parses
/// the server's UTC timestamp into a UTC `DateTime`, while a row read back
/// out of Drift is in local time. Same instant, different representation,
/// and this says they match.
///
/// Null is handled explicitly so a nullable column only counts as
/// unchanged when *both* sides are null.
bool sameStoredInstant(DateTime? a, DateTime? b) {
  if (a == null || b == null) return a == b;
  return a.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond ==
      b.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;
}

/// The subset of [incoming] that is not already cached in the same shape:
/// rows with no local counterpart, plus rows whose stored fields differ
/// from the incoming ones.
///
/// [existingById] is the whole local table keyed by primary key, loaded by
/// the caller in one query. [idOf] reads the primary key off a model, and
/// [differs] compares one incoming model against the stored model of the
/// same id — both already converted to their standard model shape by the
/// repository's own `_fromRow`, so this only ever sees model types.
///
/// [differs] must cover every field the repository persists, and must skip
/// fields it does not store. That last part matters for batches: the
/// assigned-staff and closed-by *names* arrive joined from the server but
/// are not columns in the local table, so comparing them would mark every
/// pulled batch as changed on every pull.
List<T> changedRows<T>(
  List<T> incoming,
  Map<String, T> existingById,
  String Function(T row) idOf,
  bool Function(T incoming, T existing) differs,
) {
  final changed = <T>[];
  for (final row in incoming) {
    final existing = existingById[idOf(row)];
    if (existing == null || differs(row, existing)) changed.add(row);
  }
  return changed;
}