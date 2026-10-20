import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/domain/rules/staff_limit_rule.dart';

/// A business may have at most maxStaffPerBusiness active or pending
/// Staff accounts. Proves the boundary is exact, including the
/// half-open edge at the limit itself.
void main() {
  test('the business limit is 18 Staff accounts', () {
    // Proves the constant matches the limit enforced in the Admin web
    // app; changing it silently would break the two apps apart.
    expect(maxStaffPerBusiness, 18);
  });

  group('canAddMoreStaff', () {
    test('allows a new Staff from an empty roster', () {
      // Proves the first hire goes through.
      expect(canAddMoreStaff(0), isTrue);
    });

    test('allows a new Staff one below the limit', () {
      // Proves 17 existing Staff still accepts one more.
      expect(canAddMoreStaff(maxStaffPerBusiness - 1), isTrue);
    });

    test('refuses once the limit is reached', () {
      // Proves the boundary: at exactly 18 no further Staff is added.
      expect(canAddMoreStaff(maxStaffPerBusiness), isFalse);
    });

    test('refuses above the limit', () {
      // Proves a count past the limit stays refused.
      expect(canAddMoreStaff(maxStaffPerBusiness + 1), isFalse);
    });
  });
}
