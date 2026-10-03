/// Mortality plus harvested birds can never exceed a batch's starting
/// count. This is the Domain-layer half of that rule.
///
/// A pure function on purpose: it decides, it never fetches anything
/// itself. The caller pulls the batch's starting count and the current
/// mortality and harvest totals first (from Batch, Mortality, and
/// Harvest repositories), then calls this before writing a new entry.
///
/// This mirrors the check_batch_bird_count trigger in schema.sql. That
/// trigger is the backstop for what a single device can't see, a second
/// device, also offline, writing to the same batch. This function is
/// what gives instant feedback right on the device, the moment Staff
/// types a number in, rather than waiting for a sync that might be
/// days away.
///
/// True if adding [additionalCount] more (mortality or harvested,
/// whichever is being recorded) still fits within the batch's starting
/// count.
bool canRecordBirdCount({
  required int startingBirdCount,
  required int currentMortalityTotal,
  required int currentHarvestTotal,
  required int additionalCount,
}) {
  final newTotal =
      currentMortalityTotal + currentHarvestTotal + additionalCount;
  return newTotal <= startingBirdCount;
}

/// How many birds are still unaccounted for in a batch. A convenience
/// for the UI, e.g. disabling "Record Mortality" and "Record Harvest"
/// once this reaches zero, not a substitute for the real check above.
int remainingBirdCount({
  required int startingBirdCount,
  required int currentMortalityTotal,
  required int currentHarvestTotal,
}) {
  return startingBirdCount - currentMortalityTotal - currentHarvestTotal;
}