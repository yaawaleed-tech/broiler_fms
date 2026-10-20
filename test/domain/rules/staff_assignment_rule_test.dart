import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/domain/rules/staff_assignment_rule.dart';

/// Who may record an entry against a batch. Proves a Manager keeps the
/// entry actions only while nobody is assigned, and a Staff member may
/// always record (use case: a batch assigned to Staff is theirs alone).
void main() {
  group('canRecordEntryForBatch', () {
    test('a Manager may record on an unassigned batch', () {
      // Proves the normal state between creating and assigning stays
      // open to the Manager.
      expect(
        canRecordEntryForBatch(role: 'manager', assignedStaffId: null),
        isTrue,
      );
    });

    test('a Manager may not record once Staff is assigned', () {
      // Proves two people are never writing the same batch's data.
      expect(
        canRecordEntryForBatch(role: 'manager', assignedStaffId: 'acc-staff'),
        isFalse,
      );
    });

    test('a Staff member may record on an assigned batch', () {
      // Proves the assigned Staff member owns the batch's entries.
      expect(
        canRecordEntryForBatch(role: 'staff', assignedStaffId: 'acc-staff'),
        isTrue,
      );
    });

    test('a Staff member may record even on an unassigned batch', () {
      // Proves the rule only restricts Manager, never Staff.
      expect(
        canRecordEntryForBatch(role: 'staff', assignedStaffId: null),
        isTrue,
      );
    });
  });
}
