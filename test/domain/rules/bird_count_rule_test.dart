import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/domain/rules/bird_count_rule.dart';

/// The Domain-layer half of "mortality plus harvest can never exceed the
/// starting count". Proves canRecordBirdCount decides whether one more
/// entry still fits, and remainingBirdCount reports what is left, ahead
/// of the database trigger that is only a backstop.
void main() {
  group('canRecordBirdCount', () {
    test('a count that fits under the starting count is allowed', () {
      // Proves a small mortality entry is accepted (use case: Staff
      // records 10 deaths in a 100-bird batch).
      expect(
        canRecordBirdCount(
          startingBirdCount: 100,
          currentMortalityTotal: 0,
          currentHarvestTotal: 0,
          additionalCount: 10,
        ),
        isTrue,
      );
    });

    test('a count that lands exactly on the starting count is allowed', () {
      // Proves the boundary is inclusive: 10 + 20 + 70 == 100 fits.
      expect(
        canRecordBirdCount(
          startingBirdCount: 100,
          currentMortalityTotal: 10,
          currentHarvestTotal: 20,
          additionalCount: 70,
        ),
        isTrue,
      );
    });

    test('a count that overshoots the starting count is refused', () {
      // Proves one bird too many is rejected, the same rule the
      // schema trigger enforces server-side.
      expect(
        canRecordBirdCount(
          startingBirdCount: 100,
          currentMortalityTotal: 10,
          currentHarvestTotal: 20,
          additionalCount: 71,
        ),
        isFalse,
      );
    });

    test('mortality and harvested totals are summed together', () {
      // Proves the rule counts both ways birds leave a batch, not just
      // the one being recorded.
      expect(
        canRecordBirdCount(
          startingBirdCount: 100,
          currentMortalityTotal: 60,
          currentHarvestTotal: 30,
          additionalCount: 20,
        ),
        isFalse,
      );
    });
  });

  group('remainingBirdCount', () {
    test('subtracts mortality and harvested from the starting count', () {
      // Proves the remaining figure is starting - mortality - harvested.
      expect(
        remainingBirdCount(
          startingBirdCount: 100,
          currentMortalityTotal: 10,
          currentHarvestTotal: 20,
        ),
        70,
      );
    });

    test('a fully accounted-for batch reports zero remaining', () {
      // Proves nothing is left once every bird is dead or harvested.
      expect(
        remainingBirdCount(
          startingBirdCount: 100,
          currentMortalityTotal: 40,
          currentHarvestTotal: 60,
        ),
        0,
      );
    });
  });
}
