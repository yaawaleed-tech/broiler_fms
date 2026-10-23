import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/presentation/mobile/batch/batch_detail_screen.dart';
import 'package:broiler_fms/presentation/mobile/financial/financial_summary_screen.dart';
import 'package:broiler_fms/presentation/mobile/home/batch_card.dart';

/// Drops the cached reads for one batch so open screens recompute
/// against the data that was just written.
///
/// Every entry screen calls this after a successful write, next to the
/// existing `ref.invalidate(batchDetailProvider(...))` pattern: the
/// batch detail screen and the financial summary screen are both
/// `autoDispose.family` providers that only recompute on rebuild or
/// invalidation, so without this a saved entry would leave the figures
/// behind it stale. Invalidating a provider nobody is watching is a
/// no-op, so calling this from a screen the user never opens is safe.
///
/// The home card's remaining-bird count is dropped too: it is a separate
/// provider reading the entry tables, and those do not touch the batches
/// table the list streams, so without this the count on the home list
/// stayed stale until the card happened to rebuild.
void invalidateBatchFinancials(WidgetRef ref, String batchId) {
  ref.invalidate(batchDetailProvider(batchId));
  ref.invalidate(financialSummaryProvider(batchId));
  ref.invalidate(batchRemainingProvider(batchId));
}
