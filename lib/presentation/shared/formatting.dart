import 'package:intl/intl.dart';

/// Shared number formatting, so the same number reads the same way on a
/// stat card, a list row, and a review row instead of each screen
/// inventing its own.
///
/// Everything here only changes how a number is *displayed*. The values
/// themselves come from the domain layer untouched — grouping is a
/// presentation concern and must never feed back into a calculation.
class AppFormat {
  AppFormat._();

  /// Whole numbers, grouped: 1,234. For bird counts, where a fraction
  /// of a bird is meaningless.
  static final _count = NumberFormat('#,###');

  /// Quantities that can legitimately be fractional (kg of feed, kg of
  /// birds weighed), grouped with up to two decimals and no trailing
  /// zeros: 1,234 / 12.5 / 5.25.
  ///
  /// Deliberately not the integer format: rounding 12.5 kg to "13 kg"
  /// would misreport what was actually recorded.
  static final _quantity = NumberFormat('#,###.##');

  /// Whole naira, grouped, no decimals: 450,000.
  static final _money = NumberFormat('#,###');

  /// Two decimals, grouped: 2,315.79. For rates and ratios.
  static final _twoDecimals = NumberFormat('#,###.00');

  /// A whole number with thousands separators, e.g. "1,234".
  static String count(num value) => _count.format(value);

  /// A measurement with thousands separators that keeps its decimals,
  /// e.g. "1,234", "12.5", "5.25". For kilogram quantities.
  static String quantity(num value) => _quantity.format(value);

  /// Money with a naira sign and thousands separators, e.g. "₦450,000".
  /// Pass `decimals: 2` for a rate that needs kobo, e.g. "₦2,315.79".
  static String money(num value, {int decimals = 0}) {
    final format = decimals == 0 ? _money : _twoDecimals;
    return '₦${format.format(value)}';
  }

  /// Two decimals with thousands separators, e.g. "2,315.79". For
  /// ratios and rates that carry no currency symbol, like FCR.
  static String twoDecimals(num value) => _twoDecimals.format(value);
}
