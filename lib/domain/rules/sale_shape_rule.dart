/// Checks a sale's fields match the sale_shape rule from schema.sql,
/// before the device ever writes it. Returns null when everything is
/// valid, otherwise the exact message to show the user.
///
/// A pure function on purpose, same reasoning as every other rule in
/// this folder: it decides, it never fetches anything itself.
String? saleShapeError({
  required String disposition,
  required double amount,
  String? pricingMethod,
  double? weightSold,
  double? pricePerUnit,
  String? paymentStatus,
}) {
  if (disposition == 'gift_cull') {
    final hasExtra = pricingMethod != null ||
        weightSold != null ||
        pricePerUnit != null ||
        paymentStatus != null;
    if (hasExtra || amount != 0) {
      return 'A gift or cull must have no price, weight, or payment status, and an amount of 0.';
    }
    return null;
  }

  // disposition == 'sale' from here on.
  if (amount <= 0) {
    return 'The amount must be greater than zero.';
  }

  if (pricingMethod == 'per_kg') {
    if (weightSold == null || weightSold <= 0) {
      return 'Enter the weight sold.';
    }
    if (pricePerUnit == null || pricePerUnit <= 0) {
      return 'Enter the price per kg.';
    }
    return null;
  }

  if (pricingMethod == 'flat_total') {
    if (weightSold != null) {
      return 'A flat-total sale should not have a weight.';
    }
    if (pricePerUnit != null && pricePerUnit <= 0) {
      return 'Price per bird must be greater than zero.';
    }
    return null;
  }

  return 'Choose a pricing method.';
}

/// For a per_kg sale only: checks the amount actually matches weight
/// times price, within a one-Naira rounding tolerance, mirroring the
/// separate check in schema.sql.
bool amountMatchesWeightAndPrice({
  required double weightSold,
  required double pricePerUnit,
  required double amount,
}) {
  final expected = (weightSold * pricePerUnit).round();
  return (expected - amount).abs() <= 1;
}