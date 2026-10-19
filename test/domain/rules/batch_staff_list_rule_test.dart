import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/domain/rules/batch_list_rule.dart';

/// Pure-Dart tests for the Staff split: which batches stay in the open
/// list and which fall into the read-only "Past batches" section.
///
/// The Manager split has its own file and is untouched by this one —
/// groupBatchesForList keeps its exact signature and behaviour.
void main() {
  Batch batch({
    required String id,
    required DateTime startDate,
    bool isClosed = false,
    String? assignedStaffId = 'acc-staff',
    DateTime? createdAt,
  }) {
    return Batch(
      batchId: id,
      businessId: 'biz-1',
      batchName: 'Batch $id',
      startingBirdCount: 100,
      startDate: startDate,
      isClosed: isClosed,
      createdAt: createdAt ?? startDate,
      assignedStaffId: assignedStaffId,
    );
  }

  DateTime oct(int day) => DateTime(2025, 10, day);

  List<String> ids(List<Batch> batches) =>
      batches.map((b) => b.batchId).toList();

  group('groupBatchesForStaffList', () {
    test('an assigned open batch stays open', () {
      final a = batch(id: 'a', startDate: oct(1));
      final groups = groupBatchesForStaffList([a]);
      expect(ids(groups.open), ['a']);
      expect(groups.past, isEmpty);
    });

    test('a closed batch goes to past even while still assigned', () {
      final closed = batch(id: 'closed', startDate: oct(1), isClosed: true);
      final groups = groupBatchesForStaffList([closed]);
      expect(groups.open, isEmpty);
      expect(ids(groups.past), ['closed']);
    });

    test('a released batch (assignedStaffId null) goes to past', () {
      final released = batch(
        id: 'gone',
        startDate: oct(1),
        assignedStaffId: null,
      );
      final groups = groupBatchesForStaffList([released]);
      expect(groups.open, isEmpty);
      expect(ids(groups.past), ['gone']);
    });

    test('closed wins over released for a batch that is both', () {
      // Still lands in past either way, but the card must be able to tell
      // the two apart, and "isClosed" is what it checks.
      final both = batch(
        id: 'both',
        startDate: oct(1),
        isClosed: true,
        assignedStaffId: null,
      );
      expect(both.isClosed, isTrue,
          reason: 'the chip reads isClosed first, so closed wins');
      final groups = groupBatchesForStaffList([both]);
      expect(ids(groups.past), ['both']);
    });

    test('a released and closed batch is distinguishable from released only',
        () {
      final closedOnly = batch(id: 'c', startDate: oct(1), isClosed: true);
      final releasedOnly = batch(
        id: 'r',
        startDate: oct(2),
        assignedStaffId: null,
      );
      final groups = groupBatchesForStaffList([closedOnly, releasedOnly]);
      expect(
        groups.past.where((b) => b.isClosed).map((b) => b.batchId),
        ['c'],
      );
      expect(
        groups.past.where((b) => !b.isClosed).map((b) => b.batchId),
        ['r'],
      );
    });

    test('both groups are ordered newest first', () {
      final openOld = batch(id: 'open-old', startDate: oct(1));
      final openNew = batch(id: 'open-new', startDate: oct(9));
      final pastOld = batch(
        id: 'past-old',
        startDate: oct(2),
        isClosed: true,
      );
      final pastNew = batch(
        id: 'past-new',
        startDate: oct(10),
        assignedStaffId: null,
      );

      final groups = groupBatchesForStaffList([
        openOld,
        pastOld,
        openNew,
        pastNew,
      ]);

      expect(ids(groups.open), ['open-new', 'open-old']);
      expect(ids(groups.past), ['past-new', 'past-old']);
    });

    test('same start date falls back to created, newest first', () {
      final older = batch(
        id: 'older',
        startDate: oct(5),
        isClosed: true,
        createdAt: DateTime(2025, 10, 5, 8),
      );
      final newer = batch(
        id: 'newer',
        startDate: oct(5),
        assignedStaffId: null,
        createdAt: DateTime(2025, 10, 5, 20),
      );
      final groups = groupBatchesForStaffList([older, newer]);
      expect(ids(groups.past), ['newer', 'older']);
    });

    test('empty list gives two empty lists', () {
      final groups = groupBatchesForStaffList(const []);
      expect(groups.open, isEmpty);
      expect(groups.past, isEmpty);
    });

    test('the input list is not mutated', () {
      final input = [
        batch(id: 'a', startDate: oct(1)),
        batch(id: 'b', startDate: oct(2), isClosed: true),
      ];
      groupBatchesForStaffList(input);
      expect(ids(input), ['a', 'b'],
          reason: 'sorting must happen on the copy, not the caller list');
    });
  });

  group('null means reassigned for Staff only', () {
    test('groupBatchesForList still puts a released batch in open', () {
      // The Manager reading, unchanged: null assignment there means
      // "not assigned yet", which is a normal open batch.
      final released = batch(
        id: 'r',
        startDate: oct(1),
        assignedStaffId: null,
      );
      final groups = groupBatchesForList([released]);
      expect(ids(groups.open), ['r']);
      expect(groups.closed, isEmpty);
    });

    test('the two rules disagree on exactly that row', () {
      final released = batch(
        id: 'r',
        startDate: oct(1),
        assignedStaffId: null,
      );
      expect(groupBatchesForStaffList([released]).past, hasLength(1));
      expect(groupBatchesForList([released]).open, hasLength(1));
    });

    test('a closed batch groups the same way under both rules', () {
      final closed = batch(id: 'c', startDate: oct(1), isClosed: true);
      expect(groupBatchesForStaffList([closed]).past, hasLength(1));
      expect(groupBatchesForList([closed]).closed, hasLength(1));
    });
  });
}