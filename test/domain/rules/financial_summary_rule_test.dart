import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/domain/rules/bird_count_rule.dart';
import 'package:broiler_fms/domain/rules/financial_summary_rule.dart';

/// Pure-Dart tests for the break-even denominator, the guidance states
/// and the profit-simulator arithmetic. No Flutter widgets, no
/// database: these rules decide, they never fetch anything.
void main() {
  group('breakevenPricePerBird: five-step scenario', () {
    const expenses = 100000.0;

    double breakeven({
      required double revenue,
      required int inStock,
      required int awaiting,
    }) =>
        breakevenPricePerBird(
          totalExpenses: expenses,
          totalRevenue: revenue,
          birdsStillToPrice: birdsStillToPrice(
            birdsInStock: inStock,
            birdsAwaitingPrice: awaiting,
          ),
        )!;

    test('start: 1000', () {
      expect(breakeven(revenue: 0, inStock: 100, awaiting: 0), 1000);
    });

    test('10 die: 1111.11', () {
      expect(
        breakeven(revenue: 0, inStock: 90, awaiting: 0),
        closeTo(1111.11, 0.01),
      );
    });

    test('sell 10 at 1600: 1050', () {
      expect(breakeven(revenue: 16000, inStock: 80, awaiting: 0), 1050);
    });

    test('sell 20 at 900: 1100', () {
      expect(breakeven(revenue: 34000, inStock: 60, awaiting: 0), 1100);
    });

    test('sell 10 at 5000: 320', () {
      expect(breakeven(revenue: 84000, inStock: 50, awaiting: 0), 320);
    });
  });

  group('unpriced harvests stay in the denominator', () {
    test('10 harvested and unpriced: 1000, not 1111.11', () {
      final still = birdsStillToPrice(
        birdsInStock: 90,
        birdsAwaitingPrice: 10,
      );
      expect(still, 100);
      expect(
        breakevenPricePerBird(
          totalExpenses: 100000,
          totalRevenue: 0,
          birdsStillToPrice: still,
        ),
        1000,
      );
    });

    test('after pricing them at 16000: 84000 / 90 = 933.33', () {
      expect(
        breakevenPricePerBird(
          totalExpenses: 100000,
          totalRevenue: 16000,
          birdsStillToPrice: 90,
        ),
        closeTo(933.33, 0.01),
      );
    });
  });

  test('giveaway priced at 0: 100000 / 90 = 1111.11', () {
    // 10 harvested as gift_cull: priced, so they leave the count while
    // revenue stays 0 and the break-even rises.
    expect(
      breakevenPricePerBird(
        totalExpenses: 100000,
        totalRevenue: 0,
        birdsStillToPrice: 90,
      ),
      closeTo(1111.11, 0.01),
    );
  });

  group('edge cases', () {
    test('revenue above expenses clamps to 0', () {
      expect(
        breakevenPricePerBird(
          totalExpenses: 100000,
          totalRevenue: 120000,
          birdsStillToPrice: 60,
        ),
        0,
      );
    });

    test('revenue exactly equal to expenses clamps to 0', () {
      expect(
        breakevenPricePerBird(
          totalExpenses: 100000,
          totalRevenue: 100000,
          birdsStillToPrice: 60,
        ),
        0,
      );
    });

    test('zero birds still to price returns null', () {
      expect(
        breakevenPricePerBird(
          totalExpenses: 100000,
          totalRevenue: 34000,
          birdsStillToPrice: 0,
        ),
        isNull,
      );
    });

    test('no expenses returns 0', () {
      expect(
        breakevenPricePerBird(
          totalExpenses: 0,
          totalRevenue: 0,
          birdsStillToPrice: 100,
        ),
        0,
      );
    });
  });

  group('breakevenGuidance', () {
    BreakevenGuidance guidance({
      required double expenses,
      required double revenue,
      required int inStock,
      required int awaiting,
      required double? breakeven,
    }) =>
        breakevenGuidance(
          totalExpenses: expenses,
          totalRevenue: revenue,
          birdsInStock: inStock,
          birdsAwaitingPrice: awaiting,
          breakevenPricePerBird: breakeven,
        );

    test('noBirdsLeft when nothing remains', () {
      final result = guidance(
        expenses: 100000,
        revenue: 34000,
        inStock: 0,
        awaiting: 0,
        breakeven: null,
      );
      expect(result.state, BreakevenGuidanceState.noBirdsLeft);
      expect(result.atLeastPerBird, 0);
    });

    test('costsCovered at 120000 revenue with 60 birds', () {
      final result = guidance(
        expenses: 100000,
        revenue: 120000,
        inStock: 60,
        awaiting: 0,
        breakeven: 0,
      );
      expect(result.state, BreakevenGuidanceState.costsCovered);
      expect(result.atLeastPerBird, 0);
    });

    test('sellRemaining at the step-3 state: at least 1100', () {
      final result = guidance(
        expenses: 100000,
        revenue: 34000,
        inStock: 60,
        awaiting: 0,
        breakeven: 1100,
      );
      expect(result.state, BreakevenGuidanceState.sellRemaining);
      expect(result.atLeastPerBird, 1100);
      expect(result.birdsInStock, 60);
    });

    test('needsPricing rounds 1111.11 up to 1112', () {
      final result = guidance(
        expenses: 100000,
        revenue: 0,
        inStock: 80,
        awaiting: 10,
        breakeven: 100000 / 90,
      );
      expect(result.state, BreakevenGuidanceState.needsPricing);
      expect(result.atLeastPerBird, 1112);
      expect(result.birdsInStock, 80);
      expect(result.birdsAwaitingPrice, 10);
    });

    test('a whole break-even of 1050 stays 1050 after ceil', () {
      final result = guidance(
        expenses: 100000,
        revenue: 16000,
        inStock: 80,
        awaiting: 0,
        breakeven: 1050,
      );
      expect(result.state, BreakevenGuidanceState.sellRemaining);
      expect(result.atLeastPerBird, 1050);
    });
  });

  group('simulator at the step-3 state', () {
    const expenses = 100000.0;
    const revenue = 34000.0;
    const breakeven = 1100.0;

    test('price 1100 for 60 birds lands exactly at zero', () {
      final fromThese = revenueFromTheseBirds(
        pricePerBird: 1100,
        birdsToSell: 60,
      );
      expect(fromThese, 66000);
      final total = projectedTotalRevenue(
        totalRevenue: revenue,
        revenueFromTheseBirds: fromThese,
      );
      expect(total, 100000);
      expect(
        projectedProfit(
          projectedTotalRevenue: total,
          totalExpenses: expenses,
        ),
        0,
      );
    });

    test('price 1500: 90000 / 124000 / 24000 / 19.4% / +400.00', () {
      final fromThese = revenueFromTheseBirds(
        pricePerBird: 1500,
        birdsToSell: 60,
      );
      expect(fromThese, 90000);
      final total = projectedTotalRevenue(
        totalRevenue: revenue,
        revenueFromTheseBirds: fromThese,
      );
      expect(total, 124000);
      const profit = 24000.0;
      expect(
        projectedProfit(
          projectedTotalRevenue: total,
          totalExpenses: expenses,
        ),
        profit,
      );
      final margin = profitMarginPercent(
        projectedProfit: profit,
        projectedTotalRevenue: total,
      )!;
      expect(margin, closeTo(19.35, 0.01));
      expect(margin.toStringAsFixed(1), '19.4');
      expect(
        priceComparedWithBreakeven(
          pricePerBird: 1500,
          breakeven: breakeven,
        ),
        closeTo(400, 0.001),
      );
    });

    test('target profit 30000 over 60 birds needs 1600 each', () {
      expect(
        requiredPriceForTargetProfit(
          totalExpenses: expenses,
          targetProfit: 30000,
          totalRevenue: revenue,
          birdsToSell: 60,
        ),
        1600,
      );
      expect(
        totalRevenueNeeded(
          totalExpenses: expenses,
          targetProfit: 30000,
        ),
        130000,
      );
    });

    test('same target over 30 birds needs 3200 each', () {
      expect(
        requiredPriceForTargetProfit(
          totalExpenses: expenses,
          targetProfit: 30000,
          totalRevenue: revenue,
          birdsToSell: 30,
        ),
        3200,
      );
    });

    test('target already passed returns 0', () {
      // Revenue 120000 against expenses 100000 already holds 20000 of
      // profit, so a 20000 target needs no further price.
      expect(
        requiredPriceForTargetProfit(
          totalExpenses: expenses,
          targetProfit: 20000,
          totalRevenue: 120000,
          birdsToSell: 60,
        ),
        0,
      );
    });

    test('zero birds to sell gives nulls, never exceptions', () {
      expect(
        requiredPriceForTargetProfit(
          totalExpenses: expenses,
          targetProfit: 30000,
          totalRevenue: revenue,
          birdsToSell: 0,
        ),
        isNull,
      );
      expect(
        revenueFromTheseBirds(pricePerBird: 1500, birdsToSell: 0),
        0,
      );
      expect(
        profitMarginPercent(
          projectedProfit: 0,
          projectedTotalRevenue: 0,
        ),
        isNull,
      );
      expect(
        priceComparedWithBreakeven(pricePerBird: 1500, breakeven: null),
        isNull,
      );
    });
  });

  test('remainingBirdCount: starting minus mortality minus harvested', () {
    expect(
      remainingBirdCount(
        startingBirdCount: 100,
        currentMortalityTotal: 10,
        currentHarvestTotal: 30,
      ),
      60,
    );
  });

  group('ceilToNaira: float noise never pushes an exact value up', () {
    test('1100.0000000000002 gives 1100', () {
      expect(ceilToNaira(1100.0000000000002), 1100);
    });

    test('1100.0017 still gives 1101', () {
      expect(ceilToNaira(1100.0017), 1101);
    });

    test('1111.11 gives 1112', () {
      expect(ceilToNaira(1111.11), 1112);
    });

    test('1050 stays 1050', () {
      expect(ceilToNaira(1050), 1050);
    });

    test('exactly 0 stays 0', () {
      expect(ceilToNaira(0), 0);
    });

    test('guidance absorbs noise: 1100.0000000000002 stays 1100', () {
      final result = breakevenGuidance(
        totalExpenses: 100000,
        totalRevenue: 34000,
        birdsInStock: 60,
        birdsAwaitingPrice: 0,
        breakevenPricePerBird: 1100.0000000000002,
      );
      expect(result.state, BreakevenGuidanceState.sellRemaining);
      expect(result.atLeastPerBird, 1100);
    });

    test('guidance rounds a real fraction up: 1111.11 gives 1112', () {
      final result = breakevenGuidance(
        totalExpenses: 100000,
        totalRevenue: 0,
        birdsInStock: 80,
        birdsAwaitingPrice: 10,
        breakevenPricePerBird: 1111.11,
      );
      expect(result.state, BreakevenGuidanceState.needsPricing);
      expect(result.atLeastPerBird, 1112);
    });

    test('target-profit price 1600.0000000000002 gives 1600', () {
      final required = requiredPriceForTargetProfit(
        totalExpenses: 100000,
        targetProfit: 30000,
        totalRevenue: 34000,
        birdsToSell: 60,
      )!;
      expect(required, 1600);
      expect(ceilToNaira(required), 1600);
      expect(ceilToNaira(1600.0000000000002), 1600);
    });

    test('target-profit price of exactly 0 stays 0', () {
      final required = requiredPriceForTargetProfit(
        totalExpenses: 100000,
        targetProfit: 20000,
        totalRevenue: 120000,
        birdsToSell: 60,
      )!;
      expect(required, 0);
      expect(ceilToNaira(required), 0);
    });
  });
}
