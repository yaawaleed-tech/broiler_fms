import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/domain/rules/financial_summary_rule.dart';

/// End-to-end checks on the pieces of the financial picture that the
/// existing financial_summary_rule_test.dart does not already exercise:
/// profitLoss, approximateFcr, revenueFromTheseBirds, projectedProfit,
/// profitMarginPercent, priceComparedWithBreakeven,
/// requiredPriceForTargetProfit, and totalRevenueNeeded.
void main() {
  group('profitLoss', () {
    test('revenue above expenses is a positive profit', () {
      // Proves profitLoss returns revenue minus expenses (use case:
      // Manager sees the batch in profit).
      expect(profitLoss(totalRevenue: 50000, totalExpenses: 30000), 20000);
    });

    test('expenses above revenue is a negative loss', () {
      // Proves the same subtraction yields a negative number when the
      // batch is losing money (use case: Manager sees a loss).
      expect(profitLoss(totalRevenue: 30000, totalExpenses: 50000), -20000);
    });

    test('revenue exactly equal to expenses breaks even at zero', () {
      // Proves the boundary case is neither profit nor loss.
      expect(profitLoss(totalRevenue: 45000, totalExpenses: 45000), 0);
    });
  });

  group('approximateFcr', () {
    test('divides feed by average weight times birds', () {
      // Proves the FCR estimate is feedKg / (avgWeight * harvestedBirds).
      expect(
        approximateFcr(
          totalFeedKg: 500,
          latestAverageSampleWeight: 2.0,
          totalHarvestedBirds: 100,
        ),
        2.5,
      );
    });

    test('returns null when there is no weight sample to estimate from', () {
      // Proves a zero average weight yields null, never a divide-by-zero.
      expect(
        approximateFcr(
          totalFeedKg: 500,
          latestAverageSampleWeight: 0,
          totalHarvestedBirds: 100,
        ),
        isNull,
      );
    });

    test('returns null when no birds were harvested', () {
      // Proves an empty harvest has no FCR to report, rather than 0.
      expect(
        approximateFcr(
          totalFeedKg: 500,
          latestAverageSampleWeight: 2.0,
          totalHarvestedBirds: 0,
        ),
        isNull,
      );
    });
  });

  group('revenueFromTheseBirds', () {
    test('multiplies price by birds', () {
      // Proves the simulator's per-sale revenue is price * birds.
      expect(
        revenueFromTheseBirds(pricePerBird: 1600, birdsToSell: 20),
        32000,
      );
    });

    test('a zero price earns nothing', () {
      // Proves a gift/below-cost price contributes no revenue.
      expect(revenueFromTheseBirds(pricePerBird: 0, birdsToSell: 20), 0);
    });

    test('a negative price or zero birds earns nothing', () {
      // Proves the guards catch both non-positive inputs.
      expect(revenueFromTheseBirds(pricePerBird: -5, birdsToSell: 20), 0);
      expect(revenueFromTheseBirds(pricePerBird: 100, birdsToSell: 0), 0);
    });
  });

  group('projectedProfit', () {
    test('projected revenue minus expenses gives the projected profit', () {
      // Proves the simulator adds the new sale then subtracts cost.
      expect(
        projectedProfit(projectedTotalRevenue: 120000, totalExpenses: 100000),
        20000,
      );
    });
  });

  group('profitMarginPercent', () {
    test('computes profit as a percentage of projected revenue', () {
      // Proves the margin is profit / revenue * 100.
      expect(
        profitMarginPercent(
          projectedProfit: 24000,
          projectedTotalRevenue: 124000,
        ),
        closeTo(19.3548, 0.001),
      );
    });

    test('returns null when there is no revenue to divide by', () {
      // Proves a zero-revenue projection shows a placeholder, not NaN.
      expect(
        profitMarginPercent(projectedProfit: 0, projectedTotalRevenue: 0),
        isNull,
      );
    });
  });

  group('priceComparedWithBreakeven', () {
    test('subtracts the break-even from the simulated price', () {
      // Proves a price above break-even is a positive difference.
      expect(
        priceComparedWithBreakeven(pricePerBird: 1500, breakeven: 1100),
        400,
      );
    });

    test('returns null when there is no break-even to compare with', () {
      // Proves a missing break-even yields a placeholder, not NaN.
      expect(
        priceComparedWithBreakeven(pricePerBird: 1500, breakeven: null),
        isNull,
      );
    });
  });

  group('requiredPriceForTargetProfit', () {
    test('spreads the shortfall to the target over the birds to sell', () {
      // Proves the price is (expenses + target - revenue) / birds.
      expect(
        requiredPriceForTargetProfit(
          totalExpenses: 100000,
          targetProfit: 30000,
          totalRevenue: 40000,
          birdsToSell: 60,
        ),
        1500,
      );
    });

    test('returns zero when the target is already covered', () {
      // Proves a target already passed needs no further price.
      expect(
        requiredPriceForTargetProfit(
          totalExpenses: 100000,
          targetProfit: 30000,
          totalRevenue: 200000,
          birdsToSell: 60,
        ),
        0,
      );
    });

    test('returns null when there are no birds to sell', () {
      // Proves a zero bird count has no meaningful per-bird price.
      expect(
        requiredPriceForTargetProfit(
          totalExpenses: 100000,
          targetProfit: 30000,
          totalRevenue: 40000,
          birdsToSell: 0,
        ),
        isNull,
      );
    });
  });

  group('totalRevenueNeeded', () {
    test('adds the target profit on top of expenses', () {
      // Proves the total revenue a batch must reach to hit its target.
      expect(
        totalRevenueNeeded(totalExpenses: 100000, targetProfit: 30000),
        130000,
      );
    });
  });
}
