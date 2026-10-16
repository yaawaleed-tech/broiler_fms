import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/domain/models/batch.dart';
import 'package:broiler_fms/domain/rules/batch_list_rule.dart';

/// Pure-Dart tests for the batch list grouping and ordering. No
/// widgets, no database: the rule only sorts the rows it is given.
void main() {
  Batch batch({
    required String id,
    required DateTime startDate,
    required bool isClosed,
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
    );
  }

  DateTime oct(int day) => DateTime(2025, 10, day);

  group('groupBatchesForList', () {
    test('open newest first, closed newest first', () {
      final a = batch(id: 'a', startDate: oct(1), isClosed: false);
      final b = batch(id: 'b', startDate: oct(5), isClosed: false);
      final c = batch(id: 'c', startDate: oct(10), isClosed: true);
      final d = batch(id: 'd', startDate: oct(3), isClosed: false);
      final e = batch(id: 'e', startDate: oct(2), isClosed: true);
      final f = batch(id: 'f', startDate: oct(16), isClosed: false);

      final groups = groupBatchesForList([a, b, c, d, e, f]);

      expect(groups.open.map((b) => b.batchId).toList(), ['f', 'b', 'd', 'a']);
      expect(groups.closed.map((b) => b.batchId).toList(), ['c', 'e']);
    });

    test('same start date falls back to created timestamp, newest first', () {
      final older = batch(
        id: 'older',
        startDate: oct(5),
        isClosed: false,
        createdAt: DateTime(2025, 10, 5, 8),
      );
      final newer = batch(
        id: 'newer',
        startDate: oct(5),
        isClosed: false,
        createdAt: DateTime(2025, 10, 5, 18),
      );

      final groups = groupBatchesForList([older, newer]);

      expect(
        groups.open.map((b) => b.batchId).toList(),
        ['newer', 'older'],
      );
    });

    test('a reopened batch counts as open again', () {
      final reopened = batch(id: 'r', startDate: oct(4), isClosed: false);
      final groups = groupBatchesForList([reopened]);

      expect(groups.open.map((b) => b.batchId).toList(), ['r']);
      expect(groups.closed, isEmpty);
    });

    test('closing moves a batch to the closed list', () {
      final before = batch(id: 'x', startDate: oct(4), isClosed: false);
      expect(
        groupBatchesForList([before]).open.map((b) => b.batchId).toList(),
        ['x'],
      );

      final after = batch(id: 'x', startDate: oct(4), isClosed: true);
      final groups = groupBatchesForList([after]);
      expect(groups.open, isEmpty);
      expect(groups.closed.map((b) => b.batchId).toList(), ['x']);
    });

    test('empty list gives two empty lists', () {
      final groups = groupBatchesForList(const []);
      expect(groups.open, isEmpty);
      expect(groups.closed, isEmpty);
    });

    test('single item lands in its own group', () {
      final only = batch(id: 'only', startDate: oct(7), isClosed: false);
      final groups = groupBatchesForList([only]);
      expect(groups.open.map((b) => b.batchId).toList(), ['only']);
      expect(groups.closed, isEmpty);
    });
  });
}
