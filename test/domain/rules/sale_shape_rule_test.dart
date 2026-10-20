import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/domain/rules/sale_shape_rule.dart';

/// Checks a sale's fields match the sale_shape rule from schema.sql
/// before the device writes it. Proves each branch returns the exact
/// message the user sees, and that amountMatchesWeightAndPrice allows a
/// one-naira rounding tolerance.
void main() {
  group('saleShapeError gift_cull', () {
    test('an amount of zero with nothing else is valid', () {
      // Proves a giveaway is accepted (use case: Manager culls a bird).
      expect(
        saleShapeError(disposition: 'gift_cull', amount: 0),
        isNull,
      );
    });

    test('a non-zero amount is refused', () {
      // Proves a gift_cull cannot secretly carry a price.
      expect(
        saleShapeError(disposition: 'gift_cull', amount: 500),
        'A gift or cull must have no price, weight, or payment status, '
        'and an amount of 0.',
      );
    });

    test('any extra pricing field is refused', () {
      // Proves even a zero-amount gift_cull is refused when it carries
      // a pricing method, weight, per-unit price or payment status.
      expect(
        saleShapeError(
          disposition: 'gift_cull',
          amount: 0,
          pricingMethod: 'per_kg',
        ),
        'A gift or cull must have no price, weight, or payment status, '
        'and an amount of 0.',
      );
      expect(
        saleShapeError(
          disposition: 'gift_cull',
          amount: 0,
          paymentStatus: 'paid',
        ),
        'A gift or cull must have no price, weight, or payment status, '
        'and an amount of 0.',
      );
    });
  });

  group('saleShapeError sale', () {
    test('a zero or negative amount is refused', () {
      // Proves a sale must actually earn something.
      expect(
        saleShapeError(disposition: 'sale', amount: 0, paymentStatus: 'paid'),
        'The amount must be greater than zero.',
      );
    });

    test('a missing payment status is refused', () {
      // Proves every sale says paid or pending.
      expect(
        saleShapeError(disposition: 'sale', amount: 5000),
        'Choose whether the sale is paid or pending.',
      );
    });

    test('an unknown payment status is refused', () {
      // Proves only paid and pending pass.
      expect(
        saleShapeError(
          disposition: 'sale',
          amount: 5000,
          paymentStatus: 'partial',
        ),
        'Choose whether the sale is paid or pending.',
      );
    });

    test('a per_kg sale without a weight is refused', () {
      // Proves a per-kg sale must carry the weight sold.
      expect(
        saleShapeError(
          disposition: 'sale',
          amount: 5000,
          paymentStatus: 'paid',
          pricingMethod: 'per_kg',
          pricePerUnit: 100,
        ),
        'Enter the weight sold.',
      );
    });

    test('a per_kg sale without a price per kg is refused', () {
      // Proves a per-kg sale must carry the price.
      expect(
        saleShapeError(
          disposition: 'sale',
          amount: 5000,
          paymentStatus: 'paid',
          pricingMethod: 'per_kg',
          weightSold: 50,
        ),
        'Enter the price per kg.',
      );
    });

    test('a complete per_kg sale is valid', () {
      // Proves weight and price together satisfy the per_kg branch.
      expect(
        saleShapeError(
          disposition: 'sale',
          amount: 5000,
          paymentStatus: 'paid',
          pricingMethod: 'per_kg',
          weightSold: 50,
          pricePerUnit: 100,
        ),
        isNull,
      );
    });

    test('a flat_total sale with a weight is refused', () {
      // Proves a flat-total amount has no weight attached.
      expect(
        saleShapeError(
          disposition: 'sale',
          amount: 5000,
          paymentStatus: 'paid',
          pricingMethod: 'flat_total',
          weightSold: 50,
        ),
        'A flat-total sale should not have a weight.',
      );
    });

    test('a flat_total sale with a zero price per bird is refused', () {
      // Proves a per-bird price, when given, must be positive.
      expect(
        saleShapeError(
          disposition: 'sale',
          amount: 5000,
          paymentStatus: 'paid',
          pricingMethod: 'flat_total',
          pricePerUnit: 0,
        ),
        'Price per bird must be greater than zero.',
      );
    });

    test('a flat_total sale without fields is valid', () {
      // Proves the simplest flat sale passes.
      expect(
        saleShapeError(
          disposition: 'sale',
          amount: 5000,
          paymentStatus: 'pending',
          pricingMethod: 'flat_total',
        ),
        isNull,
      );
    });

    test('a missing pricing method is refused last', () {
      // Proves a sale that is otherwise well-formed still needs a
      // pricing method.
      expect(
        saleShapeError(
          disposition: 'sale',
          amount: 5000,
          paymentStatus: 'paid',
        ),
        'Choose a pricing method.',
      );
    });
  });

  group('amountMatchesWeightAndPrice', () {
    test('an exact product matches', () {
      // Proves 50 kg * 100 = 5000 passes.
      expect(
        amountMatchesWeightAndPrice(
          weightSold: 50,
          pricePerUnit: 100,
          amount: 5000,
        ),
        isTrue,
      );
    });

    test('a one-naira difference still matches', () {
      // Proves the one-naira rounding tolerance absorbs rounding.
      expect(
        amountMatchesWeightAndPrice(
          weightSold: 50,
          pricePerUnit: 100.02,
          amount: 5000,
        ),
        isTrue,
      );
    });

    test('a two-naira difference does not match', () {
      // Proves a real mismatch is caught.
      expect(
        amountMatchesWeightAndPrice(
          weightSold: 50,
          pricePerUnit: 100,
          amount: 5003,
        ),
        isFalse,
      );
    });
  });
}
