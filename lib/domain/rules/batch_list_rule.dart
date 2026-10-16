import 'package:broiler_fms/domain/models/batch.dart';

/// The mobile batch list split in two: open batches for the main list,
/// closed batches for the collapsible section. Both lists arrive
/// already ordered, newest first.
class BatchListGroups {
  const BatchListGroups({required this.open, required this.closed});

  final List<Batch> open;
  final List<Batch> closed;
}

/// Splits [batches] into open and closed, each ordered newest first.
///
/// A reopened batch counts as open again: only [Batch.isClosed] decides
/// the group. "Newest" is the batch's start date descending — the same
/// field the card's "Day N" counts from — then the created timestamp
/// descending, then the id descending, so the order is stable even when
/// two batches share a start date.
///
/// A pure function on purpose, same reasoning as every other rule in
/// this folder: it decides, it never fetches anything itself. The
/// mobile batch list screen calls this on the rows its stream already
/// delivered; repository queries are deliberately untouched, so Admin
/// web ordering does not change.
BatchListGroups groupBatchesForList(List<Batch> batches) {
  final open = <Batch>[];
  final closed = <Batch>[];
  for (final batch in batches) {
    if (batch.isClosed) {
      closed.add(batch);
    } else {
      open.add(batch);
    }
  }
  open.sort(_newestFirst);
  closed.sort(_newestFirst);
  return BatchListGroups(open: open, closed: closed);
}

/// Newest start date first, then newest created timestamp, then id —
/// every tie-breaker descending so the order is fully deterministic.
int _newestFirst(Batch a, Batch b) {
  final byStart = b.startDate.compareTo(a.startDate);
  if (byStart != 0) return byStart;
  final byCreated = b.createdAt.compareTo(a.createdAt);
  if (byCreated != 0) return byCreated;
  return b.batchId.compareTo(a.batchId);
}
