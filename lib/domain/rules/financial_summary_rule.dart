/// Computes the financial picture for one batch: profit or loss,
/// breakeven price, and an approximate feed conversion ratio (FCR).
///
/// A pure function file, same reasoning as every other file in
/// rules/: these decide nothing by fetching data themselves. The
/// caller (BatchDomain on mobile, RemoteBatchDomain on web) gathers
/// the raw totals from its own repositories first, then calls these.
/// This keeps the arithmetic identical on both platforms, even though
/// each platform reads its totals from different storage.
///
/// Revenue minus expenses for a batch so far. Positive is profit,
/// negative is loss.
double profitLoss({
  required double totalRevenue,
  required double totalExpenses,
}) {
  return totalRevenue - totalExpenses;
}

/// The price per bird that would exactly cover total expenses, based
/// on birds actually harvested. Birds that died or remain
/// un-harvested generate no revenue, so they are not divided into.
///
/// Returns 0 if nothing has been harvested yet, since there is no
/// meaningful price to compute against zero birds.
double breakevenPricePerBird({
  required double totalExpenses,
  required int totalHarvestedBirds,
}) {
  if (totalHarvestedBirds == 0) return 0;
  return totalExpenses / totalHarvestedBirds;
}

/// Approximate feed conversion ratio: feed consumed divided by an
/// estimate of total weight gained.
///
/// This is an estimate, not an exact figure, because not every
/// harvested bird has a recorded weight (a flat_total sale or a
/// gift_cull records no weight at all). The most recent weight
/// sample's average bird weight stands in for every harvested bird,
/// applied consistently regardless of how the harvest was sold.
///
/// Returns null, not zero, when there is no weight sample yet to
/// estimate from. Presentation should show a placeholder (e.g. "—")
/// rather than a misleading 0 in that case.
double? approximateFcr({
  required double totalFeedKg,
  required double latestAverageSampleWeight,
  required int totalHarvestedBirds,
}) {
  final estimatedTotalWeight = latestAverageSampleWeight * totalHarvestedBirds;
  if (estimatedTotalWeight <= 0) return null;
  return totalFeedKg / estimatedTotalWeight;
}