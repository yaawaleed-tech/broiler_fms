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
/// owes, spread over every bird that still has to earn money.
///
/// Money already earned comes off the top first: revenue collected so
/// far (paid and pending alike, the same figure [profitLoss] uses) is
/// subtracted from total expenses, and what is left is divided by the
/// birds still to price — birds in stock plus harvested birds that
/// have no sale recorded yet. A harvest without a price still has to
/// earn its share, so its birds stay in the denominator until someone
/// prices them; a gift_cull (priced at ₦0) counts as priced and leaves
/// the denominator. So this answers "what do I still need per bird to
/// break even on the ones I have left?", not "what did the birds I
/// already sold cost me?" — a batch already in profit prices its
/// remaining birds at zero, because everything after that is margin.
///
/// Returns null, not zero, when no birds are left to price (the batch
/// is fully harvested or closed): there is no per-bird price to
/// recover at that point, and showing ₦0 would read as "free" rather
/// than "nothing left to sell". Presentation shows a placeholder
/// instead, exactly as [approximateFcr] does for its own empty case.
double? breakevenPricePerBird({
  required double totalExpenses,
  required double totalRevenue,
  required int birdsStillToPrice,
}) {
  if (birdsStillToPrice <= 0) return null;
  final outstanding = totalExpenses - totalRevenue;
  // Already covered: everything further is profit, and a negative
  // "price you must charge" would be meaningless to read.
  if (outstanding <= 0) return 0;
  return outstanding / birdsStillToPrice;
}

/// Every bird that still has to earn money: birds in stock plus
/// harvested birds that have no sale recorded yet.
int birdsStillToPrice({
  required int birdsInStock,
  required int birdsAwaitingPrice,
}) {
  return birdsInStock + birdsAwaitingPrice;
}

/// Rounds a money value UP to the next whole naira, with a tiny
/// tolerance so float noise cannot push an exact value up a naira:
/// 1100.0000000000002 gives 1100, while 1100.0017 still gives 1101.
/// The single place every "at least ₦X" figure rounds through — never
/// round to 2 decimals first, that would hide the noise instead of
/// absorbing it.
int ceilToNaira(double value) => (value - 0.000001).ceil();

/// What the financial summary should tell the Manager, in one value.
/// The screen turns this into a sentence; the numbers it needs travel
/// along so presentation never recomputes anything.
enum BreakevenGuidanceState {
  /// Nothing left to price: no guidance figure applies.
  noBirdsLeft,

  /// Revenue already covers expenses: every further bird is profit.
  costsCovered,

  /// Some harvested birds still need a price before anything can sell.
  needsPricing,

  /// Otherwise: sell what is left at (at least) the break-even.
  sellRemaining,
}

class BreakevenGuidance {
  const BreakevenGuidance({
    required this.state,
    required this.atLeastPerBird,
    required this.birdsInStock,
    required this.birdsAwaitingPrice,
  });

  final BreakevenGuidanceState state;

  /// The break-even rounded UP to the next whole naira (through
  /// [ceilToNaira]), so selling at this figure can never leave a
  /// shortfall. Zero when there is no break-even to round (nothing
  /// left, or costs already covered).
  final int atLeastPerBird;
  final int birdsInStock;
  final int birdsAwaitingPrice;
}

/// Decides which guidance the Manager sees. Checked in this order:
/// nothing left first, then costs covered, then birds awaiting a
/// price, otherwise sell what remains.
BreakevenGuidance breakevenGuidance({
  required double totalExpenses,
  required double totalRevenue,
  required int birdsInStock,
  required int birdsAwaitingPrice,
  required double? breakevenPricePerBird,
}) {
  final stillToPrice = birdsStillToPrice(
    birdsInStock: birdsInStock,
    birdsAwaitingPrice: birdsAwaitingPrice,
  );
  if (stillToPrice <= 0) {
    return BreakevenGuidance(
      state: BreakevenGuidanceState.noBirdsLeft,
      atLeastPerBird: 0,
      birdsInStock: birdsInStock,
      birdsAwaitingPrice: birdsAwaitingPrice,
    );
  }
  if (totalRevenue >= totalExpenses) {
    return BreakevenGuidance(
      state: BreakevenGuidanceState.costsCovered,
      atLeastPerBird: 0,
      birdsInStock: birdsInStock,
      birdsAwaitingPrice: birdsAwaitingPrice,
    );
  }
  final atLeast = ceilToNaira(breakevenPricePerBird ?? 0);
  if (birdsAwaitingPrice > 0) {
    return BreakevenGuidance(
      state: BreakevenGuidanceState.needsPricing,
      atLeastPerBird: atLeast,
      birdsInStock: birdsInStock,
      birdsAwaitingPrice: birdsAwaitingPrice,
    );
  }
  return BreakevenGuidance(
    state: BreakevenGuidanceState.sellRemaining,
    atLeastPerBird: atLeast,
    birdsInStock: birdsInStock,
    birdsAwaitingPrice: birdsAwaitingPrice,
  );
}

/// What selling [birdsToSell] birds at [pricePerBird] would earn.
/// Whole-naira inputs, whole-naira output.
double revenueFromTheseBirds({
  required double pricePerBird,
  required int birdsToSell,
}) {
  if (pricePerBird <= 0 || birdsToSell <= 0) return 0;
  return pricePerBird * birdsToSell;
}

/// Revenue so far plus what the simulated sale would add.
double projectedTotalRevenue({
  required double totalRevenue,
  required double revenueFromTheseBirds,
}) {
  return totalRevenue + revenueFromTheseBirds;
}

/// Projected revenue minus what the batch cost. Positive is profit,
/// negative is loss.
double projectedProfit({
  required double projectedTotalRevenue,
  required double totalExpenses,
}) {
  return projectedTotalRevenue - totalExpenses;
}

/// Projected profit as a percentage of projected revenue. Null when
/// there is no projected revenue to divide by — never NaN.
double? profitMarginPercent({
  required double projectedProfit,
  required double projectedTotalRevenue,
}) {
  if (projectedTotalRevenue <= 0) return null;
  return projectedProfit / projectedTotalRevenue * 100;
}

/// How the simulated price compares with the break-even. Null when
/// there is no break-even to compare with — never NaN.
double? priceComparedWithBreakeven({
  required double pricePerBird,
  required double? breakeven,
}) {
  if (breakeven == null) return null;
  return pricePerBird - breakeven;
}

/// The per-bird price that would leave exactly [targetProfit] after
/// covering expenses, given what has been earned so far. Clamped at
/// zero: a target already passed needs no price. Null when there are
/// no birds to spread it over.
double? requiredPriceForTargetProfit({
  required double totalExpenses,
  required double targetProfit,
  required double totalRevenue,
  required int birdsToSell,
}) {
  if (birdsToSell <= 0) return null;
  final required = (totalExpenses + targetProfit - totalRevenue) / birdsToSell;
  if (required <= 0) return 0;
  return required;
}

/// The total revenue a batch must reach to end with [targetProfit].
double totalRevenueNeeded({
  required double totalExpenses,
  required double targetProfit,
}) {
  return totalExpenses + targetProfit;
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