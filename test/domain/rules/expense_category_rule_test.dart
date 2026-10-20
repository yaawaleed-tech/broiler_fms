import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/domain/rules/expense_category_rule.dart';

/// Checks an expense's category before the device writes it. Proves the
/// exact message the user sees, mirroring the CHECK constraint on the
/// expense table in schema.sql.
void main() {
  group('expenseCategoryError', () {
    test('accepts the four valid categories', () {
      // Proves chicks, feed, vet_medication and other all pass
      // (use case: Staff records any normal expense).
      for (final category in ['chicks', 'feed', 'vet_medication', 'other']) {
        expect(expenseCategoryError(category), isNull, reason: category);
      }
    });

    test('refuses an unknown category with the exact message', () {
      // Proves a category the database would reject is caught first.
      expect(
        expenseCategoryError('medicine'),
        'Choose a valid expense category.',
      );
    });

    test('refuses an empty category', () {
      // Proves an unset category is caught rather than written.
      expect(
        expenseCategoryError(''),
        'Choose a valid expense category.',
      );
    });

    test('is case-sensitive', () {
      // Proves the rule matches the lowercase constants exactly.
      expect(
        expenseCategoryError('Feed'),
        'Choose a valid expense category.',
      );
    });
  });
}
