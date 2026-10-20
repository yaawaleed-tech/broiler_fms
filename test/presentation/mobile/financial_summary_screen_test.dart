import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/domain/models/financial_summary.dart';
import 'package:broiler_fms/presentation/mobile/financial/financial_summary_screen.dart';

/// The Manager's read-only financial picture, mounted with the loaded
/// summary injected so no database is needed. Proves the "Where you
/// stand" guidance sentence each breakeven state produces, and that an
/// absent break-even or FCR shows a placeholder rather than a number.
FinancialSummary summary({
  double totalExpenses = 100000,
  double totalRevenue = 40000,
  double? breakeven = 1000,
  double? fcr = 2.5,
  int birdsInStock = 60,
  int birdsAwaitingPrice = 0,
  int birdsStillToPrice = 60,
}) {
  return FinancialSummary(
    totalExpenses: totalExpenses,
    totalRevenue: totalRevenue,
    profitLoss: totalRevenue - totalExpenses,
    breakevenPricePerBird: breakeven,
    approximateFcr: fcr,
    birdsInStock: birdsInStock,
    birdsAwaitingPrice: birdsAwaitingPrice,
    birdsStillToPrice: birdsStillToPrice,
  );
}

Future<void> mount(WidgetTester tester, FinancialSummary s) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        financialSummaryProvider('batch-1').overrideWith((ref) async => s),
      ],
      child: const MaterialApp(
        home: FinancialSummaryScreen(batchId: 'batch-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sellRemaining tells the Manager the price for the rest',
      (tester) async {
    // Proves the sellRemaining guidance sentence and the ₦-grouped
    // figure (use case: costs not yet covered, birds still in stock).
    await mount(tester, summary());
    expect(
      find.text(
        'Sell your remaining 60 birds for at least ₦1,000 each to cover '
        'all costs.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('needsPricing mentions harvested birds and stock together',
      (tester) async {
    // Proves the needsPricing branch when both harvested and in-stock
    // birds have to earn their share.
    await mount(
      tester,
      summary(birdsInStock: 40, birdsAwaitingPrice: 20, birdsStillToPrice: 60),
    );
    expect(
      find.textContaining('Price the 20 harvested birds, then sell the 40'),
      findsOneWidget,
    );
  });

  testWidgets('needsPricing with no stock asks only to price the harvest',
      (tester) async {
    // Proves the other needsPricing sentence, when nothing is in stock.
    await mount(
      tester,
      summary(birdsInStock: 0, birdsAwaitingPrice: 20, birdsStillToPrice: 20),
    );
    expect(
      find.textContaining('Price the 20 harvested birds. They need to bring'),
      findsOneWidget,
    );
  });

  testWidgets('costsCovered says every further bird is profit',
      (tester) async {
    // Proves revenue at or above expenses produces the covered message.
    await mount(
      tester,
      summary(totalExpenses: 100000, totalRevenue: 120000, breakeven: 0),
    );
    expect(
      find.text('Costs covered. Every bird from here is profit.'),
      findsOneWidget,
    );
  });

  testWidgets('noBirdsLeft says there is nothing more to break even on',
      (tester) async {
    // Proves a batch with nothing left to price shows the noBirdsLeft
    // message.
    await mount(
      tester,
      summary(
        birdsInStock: 0,
        birdsAwaitingPrice: 0,
        birdsStillToPrice: 0,
        breakeven: null,
      ),
    );
    expect(
      find.text('No birds left to sell. Nothing more to break even on.'),
      findsOneWidget,
    );
  });

  testWidgets('a missing break-even and FCR show placeholders',
      (tester) async {
    // Proves the em-dash placeholders rather than a misleading number.
    await mount(tester, summary(breakeven: null, fcr: null));
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('the cost-recovery bar hides itself with no expenses',
      (tester) async {
    // Proves "No expenses recorded yet" replaces the bar when nothing
    // has been spent.
    await mount(tester, summary(totalExpenses: 0, totalRevenue: 0));
    expect(find.text('No expenses recorded yet'), findsOneWidget);
  });

  testWidgets('the FCR is shown with two decimals when present',
      (tester) async {
    // Proves the approximate FCR renders through AppFormat.twoDecimals.
    await mount(tester, summary(fcr: 2.5));
    expect(find.text('2.50'), findsOneWidget);
  });
}
