import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/presentation/mobile/widgets/sync_now_button.dart';

/// The wording the sync button shows when a sync had nothing to report as a
/// problem. Pure and role-free: the same sentence is right for Staff and
/// Manager, because `updated` already counts only rows that were genuinely
/// new or different.
///
/// Only the success half lives here. The problem messages — rejected rows,
/// failed rows, pull errors — are handled earlier in `_message` and are not
/// reachable from this function; `test/sync/sync_message_problems_test.dart`
/// is not needed because that precedence is unchanged and still covered by
/// the behaviour of `_message` itself.
void main() {
  group('syncOutcomeMessage', () {
    test('nothing sent and nothing received: already up to date', () {
      expect(syncOutcomeMessage(0, 0), 'Already up to date.');
    });

    test('one sent, nothing received: singular', () {
      expect(syncOutcomeMessage(1, 0), '1 entry sent');
    });

    test('several sent, nothing received: plural', () {
      expect(syncOutcomeMessage(3, 0), '3 entries sent');
    });

    test('nothing sent, one received: singular', () {
      expect(syncOutcomeMessage(0, 1), '1 change received');
    });

    test('nothing sent, several received: plural', () {
      expect(syncOutcomeMessage(0, 12), '12 changes received');
    });

    test('both: one of each stays singular', () {
      expect(syncOutcomeMessage(1, 1), '1 entry sent, 1 change received');
    });

    test('both: plurals on both sides', () {
      expect(
        syncOutcomeMessage(4, 12),
        '4 entries sent, 12 changes received',
      );
    });

    test('an unchanged pull reports nothing at all, not a row count', () {
      // The bug this replaced: a pull that changed nothing used to read
      // "Synced. 0 sent, 40 updated from server."
      expect(
        syncOutcomeMessage(0, 0),
        isNot(contains('updated')),
        reason: 'no row count is claimed when nothing changed',
      );
    });
  });
}