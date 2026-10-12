/// A batch's computed financial picture: never stored anywhere,
/// always derived fresh from expense, sale, feed, and harvest totals.
///
/// Both BatchDomain (mobile) and RemoteBatchDomain (web) build one of
/// these, each gathering its own totals from its own repositories,
/// then handing them to the same shared formulas in
/// rules/financial_summary_rule.dart.
class FinancialSummary {
  const FinancialSummary({
    required this.totalExpenses,
    required this.totalRevenue,
    required this.profitLoss,
    required this.breakevenPricePerBird,
    required this.approximateFcr,
  });

  final double totalExpenses;
  final double totalRevenue;
  final double profitLoss;
  /// Null when no birds are left to price, so there is no meaningful
  /// per-bird figure to show.
  final double? breakevenPricePerBird;

  /// Null when there is no weight sample yet to estimate from.
  final double? approximateFcr;
}