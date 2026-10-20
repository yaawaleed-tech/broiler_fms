import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/domain/rules/batch_closure_rule.dart';

/// A batch can only be closed once every bird is accounted for. Proves
/// canCloseBatch refuses a close with birds left over, and
/// unaccountedBirdCount reports how many are missing for the UI.
void main() {
  group('canCloseBatch', () {
    test('every bird dead or harvested allows a close', () {
      // Proves 40 mortality + 60 harvested on a 100-bird batch closes
      // (use case: Manager closes a finished batch).
      expect(
        canCloseBatch(
          startingBirdCount: 100,
          currentMortalityTotal: 40,
          currentHarvestTotal: 60,
        ),
        isTrue,
      );
    });

    test('birds still left over refuse a close', () {
      // Proves 30 + 60 leaves 10 birds, so the close is refused.
      expect(
        canCloseBatch(
          startingBirdCount: 100,
          currentMortalityTotal: 30,
          currentHarvestTotal: 60,
        ),
        isFalse,
      );
    });

    test('totals below the starting count refuse a close', () {
      // Proves an untouched batch (nothing recorded) cannot be closed.
      expect(
        canCloseBatch(
          startingBirdCount: 100,
          currentMortalityTotal: 0,
          currentHarvestTotal: 0,
        ),
        isFalse,
      );
    });
  });

  group('unaccountedBirdCount', () {
    test('reports the birds not yet dead or harvested', () {
      // Proves the UI figure is starting - mortality - harvested.
      expect(
        unaccountedBirdCount(
          startingBirdCount: 100,
          currentMortalityTotal: 30,
          currentHarvestTotal: 60,
        ),
        10,
      );
    });

    test('reports zero when the batch is fully accounted for', () {
      // Proves a closable batch shows nothing left to account for.
      expect(
        unaccountedBirdCount(
          startingBirdCount: 100,
          currentMortalityTotal: 40,
          currentHarvestTotal: 60,
        ),
        0,
      );
    });
  });
}
