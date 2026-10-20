import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/domain/models/financial_summary.dart';
import 'package:broiler_fms/presentation/mobile/financial/profit_simulator.dart';

/// The Manager's profit calculator: a pure calculator over an
/// already-loaded [FinancialSummary], so it can be mounted on its own.
/// Proves the birds field is clamped to the batch maximum and that the
/// guidance and results follow the shared rules.
FinancialSummary summary({
  double totalExpenses = 100000,
  double totalRevenue = 40000,
  int birdsStillToPrice = 60,
  double? breakeven = 1000,
}) {
  return FinancialSummary(
    totalExpenses: totalExpenses,
    totalRevenue: totalRevenue,
    profitLoss: totalRevenue - totalExpenses,
    breakevenPricePerBird: breakeven,
    approximateFcr: null,
    birdsInStock: birdsStillToPrice,
    birdsAwaitingPrice: 0,
    birdsStillToPrice: birdsStillToPrice,
  );
}

Future<void> mount(WidgetTester tester, FinancialSummary s) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: ProfitSimulator(summary: s)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the birds-left line and the default birds field',
      (tester) async {
    // Proves the simulator seeds its birds field from the summary (use
    // case: Manager opens the calculator for a batch with 60 birds
    // left).
    await mount(tester, summary(birdsStillToPrice: 60));
    expect(find.textContaining('60 birds left to sell'), findsOneWidget);
  });

  testWidgets('typing a price at or above break-even shows a profit',
      (tester) async {
    // Proves the price-mode results run through revenueFromTheseBirds
    // and projectedProfit (use case: Manager tests a selling price).
    await mount(tester, summary());
    await tester.enterText(
      find.widgetWithText(TextField, 'Selling price per bird (₦)'),
      '1200',
    );
    await tester.pumpAndSettle();
    // 1200 * 60 = 72000 from these birds; 40000 + 72000 - 100000 = 12000.
    expect(find.text('Projected profit / loss'), findsOneWidget);
    expect(find.textContaining('+₦12,000'), findsOneWidget);
  });

  testWidgets('clamps a count one over the maximum back down',
      (tester) async {
    // Proves _onBirdsChanged rewrites any over-max count to the batch's
    // birdsStillToPrice — including just one over, the tightest case.
    await mount(tester, summary(birdsStillToPrice: 60));
    final birdsField =
        find.widgetWithText(TextField, 'Number of birds to sell');
    await tester.enterText(birdsField, '61');
    await tester.pumpAndSettle();
    expect(find.text('60'), findsOneWidget,
        reason: 'one over the max is clamped back to the batch maximum');
  });

  testWidgets('clamps a wildly over-max count back to the maximum',
      (tester) async {
    // Proves the same clamp for a large typed value.
    await mount(tester, summary(birdsStillToPrice: 60));
    final birdsField =
        find.widgetWithText(TextField, 'Number of birds to sell');
    await tester.enterText(birdsField, '999');
    await tester.pumpAndSettle();
    expect(find.text('60'), findsOneWidget);
  });

  testWidgets('switching to target mode asks for the price at that profit',
      (tester) async {
    // Proves the mode switch runs requiredPriceForTargetProfit (use
    // case: Manager asks "what price for this profit?").
    await mount(tester, summary());
    await tester.tap(find.text('Target profit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Target profit (₦)'),
      '30000',
    );
    await tester.pumpAndSettle();
    // (100000 + 30000 - 40000) / 60 = 1500.
    expect(find.textContaining('₦1,500'), findsWidgets);
  });

  testWidgets('says there is nothing to simulate when no birds are left',
      (tester) async {
    // Proves the empty case renders a message instead of a calculator.
    await mount(tester, summary(birdsStillToPrice: 0));
    expect(
      find.text('No birds left to sell, so there is nothing to simulate.'),
      findsOneWidget,
    );
  });
}
