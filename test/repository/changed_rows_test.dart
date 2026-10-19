import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/repository/shared/changed_rows.dart';

/// The two helpers every local repository's change detection is built on.
/// The per-repository behaviour is covered in
/// test/repository/changed_rows_upsert_test.dart; this file pins the
/// shared rules, including the storage quirk that makes them necessary.
void main() {
  group('sameStoredInstant', () {
    test('the same instant compares equal', () {
      final a = DateTime(2026, 3, 4, 5, 6, 7);
      expect(sameStoredInstant(a, DateTime(2026, 3, 4, 5, 6, 7)), isTrue);
    });

    test('sub-second precision never reads as a difference', () {
      // Drift truncates dateTime() to whole seconds on the way in, so a
      // value carrying microseconds comes back without them. Comparing with
      // == would call this a change on every pull, forever.
      final stored = DateTime(2026, 3, 4, 5, 6, 7);
      final incoming = DateTime(2026, 3, 4, 5, 6, 7, 891);
      expect(incoming == stored, isFalse, reason: 'raw == would false-positive');
      expect(sameStoredInstant(incoming, stored), isTrue);
    });

    test('the same instant in different timezones compares equal', () {
      final utc = DateTime.utc(2026, 3, 4, 5, 6, 7);
      final local = utc.toLocal();
      expect(utc.isUtc == local.isUtc, isFalse);
      expect(sameStoredInstant(utc, local), isTrue);
    });

    test('a different second is a difference', () {
      expect(
        sameStoredInstant(
          DateTime(2026, 3, 4, 5, 6, 7),
          DateTime(2026, 3, 4, 5, 6, 8),
        ),
        isFalse,
      );
    });

    test('null only matches null', () {
      expect(sameStoredInstant(null, null), isTrue);
      expect(sameStoredInstant(null, DateTime(2026, 1, 1)), isFalse);
      expect(sameStoredInstant(DateTime(2026, 1, 1), null), isFalse);
    });
  });

  group('changedRows', () {
    final incoming = ['a', 'b', 'c'];

    test('a row with no local counterpart counts as changed', () {
      final changed = changedRows(incoming, const {}, (s) => s, (a, b) => true);
      expect(changed, ['a', 'b', 'c']);
    });

    test('an identical row is dropped', () {
      final existing = {'a': 'a', 'b': 'b', 'c': 'c'};
      final changed =
          changedRows(incoming, existing, (s) => s, (a, b) => a != b);
      expect(changed, isEmpty);
    });

    test('a row the comparison flags is kept', () {
      final existing = {'a': 'a', 'b': 'b', 'c': 'DIFFERENT'};
      final changed =
          changedRows(incoming, existing, (s) => s, (a, b) => a != b);
      expect(changed, ['c']);
    });

    test('only the genuinely different rows are returned', () {
      // 'b' is new, 'a' is unchanged, 'c' differs.
      final existing = {'a': 'a', 'c': 'OLD'};
      final changed =
          changedRows(incoming, existing, (s) => s, (a, b) => a != b);
      expect(changed, ['b', 'c'], reason: 'input order is preserved');
    });

    test('an empty incoming list changes nothing', () {
      final changed =
          changedRows(const <String>[], {'a': 'a'}, (s) => s, (a, b) => true);
      expect(changed, isEmpty);
    });
  });
}