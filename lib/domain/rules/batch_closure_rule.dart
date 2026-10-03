/// A batch can only be closed once every bird is accounted for: all of
/// them are either harvested or recorded as mortality, none left over.
///
/// A pure function on purpose, same reasoning as bird_count_rule.dart:
/// it decides, it never fetches anything itself. The caller pulls the
/// batch's starting count and the current mortality and harvest totals
/// first, then calls this before allowing a close.
bool canCloseBatch({
  required int startingBirdCount,
  required int currentMortalityTotal,
  required int currentHarvestTotal,
}) {
  return currentMortalityTotal + currentHarvestTotal == startingBirdCount;
}

/// How many birds are still unaccounted for. Useful for the UI, e.g.
/// showing "12 birds not yet accounted for" next to a disabled Close
/// button, not a substitute for the real check above.
int unaccountedBirdCount({
  required int startingBirdCount,
  required int currentMortalityTotal,
  required int currentHarvestTotal,
}) {
  return startingBirdCount - currentMortalityTotal - currentHarvestTotal;
}