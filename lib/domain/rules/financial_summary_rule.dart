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

/// The price per bird that would exactly cover what the batch still
/// owes, spread over the birds that are still available to sell.
///
/// Money already earned comes off the top first: revenue collected so
/// far (paid and pending alike, the same figure [profitLoss] uses) is
/// subtracted from total expenses, and what is left is divided by the
/// birds not yet harvested. So this answers "what do I still need per
/// bird to break even on the ones I have left?", not "what did the
/// birds I already sold cost me?" — a batch already in profit prices
/// its remaining birds at zero, because everything after that is
/// margin.
///
/// Returns null, not zero, when no birds are left to price (the batch
/// is fully harvested or closed): there is no per-bird price to
/// recover at that point, and showing ₦0 would read as "free" rather
/// than "nothing left to sell". Presentation shows a placeholder
/// instead, exactly as [approximateFcr] does for its own empty case.
double? breakevenPricePerBird({
  required double totalExpenses,
  required double totalRevenue,
  required int birdsNotYetHarvested,
}) {
  if (birdsNotYetHarvested <= 0) return null;
  final outstanding = totalExpenses - totalRevenue;
  // Already covered: everything further is profit, and a negative
  // "price you must charge" would be meaningless to read.
  if (outstanding <= 0) return 0;
  return outstanding / birdsNotYetHarvested;
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