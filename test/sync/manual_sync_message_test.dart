import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;

import 'package:broiler_fms/presentation/shared/sync_action.dart';
import 'package:broiler_fms/sync/manual_sync.dart';
import 'package:broiler_fms/sync/pull_service.dart';
import 'package:broiler_fms/sync/sync_result.dart';

/// Every outcome of a manual sync, and the one sentence it earns.
///
/// The bug these lock down: the old pull-to-refresh collapsed five
/// different "did not run" reasons into a single `null` and then blamed
/// the network for all of them, so somebody standing next to a phone that
/// said "Online" was told there was no internet connection. Each case
/// below that used to reach the no-internet wording is named.
void main() {
  const noInternet =
      'No internet connection. Check your network and try again.';

  PullResult pull({
    Map<String, int> perTable = const {},
    List<String> errors = const [],
  }) =>
      PullResult(perTable: perTable, errors: errors);

  group('a skip is never a network problem', () {
    test('no session says nothing at all', () {
      // The button has always come back quiet here, and a list dragged by
      // somebody with no session does not need a lecture either.
      expect(
        manualSyncMessage(
          const ManualSyncSkipped(ManualSyncSkip.signedOut),
        ),
        isNull,
      );
    });

    test('an unreadable account is not the network', () {
      // The 12-second account-ready wait lands here. The session restored
      // perfectly; it is the account record that is not there yet.
      final message = manualSyncMessage(
        const ManualSyncSkipped(ManualSyncSkip.accountNotReady),
      );
      expect(message, isNot(equals(noInternet)));
      expect(message, "Your account isn't ready yet. Try again in a moment.");
    });
  });

  group('only a failed request may claim the network', () {
    test('a network failure gets the no-internet wording', () {
      expect(
        manualSyncMessage(const ManualSyncNetworkFailure()),
        noInternet,
      );
    });

    test('an unexpected failure keeps its own words', () {
      expect(
        manualSyncMessage(ManualSyncFailed(Exception('disk full'))),
        'Sync failed: Exception: disk full',
      );
    });
  });

  group('the four transport failures are all recognised', () {
    for (final entry in {
      'a socket that never opened': SocketException('Connection refused'),
      'an http client that gave up': ClientException('Connection closed'),
      'a request that timed out':
          TimeoutException('timed out', const Duration(seconds: 15)),
      'an http protocol failure': HttpException('Connection reset'),
    }.entries) {
      test(entry.key, () {
        expect(isNetworkFailure(entry.value), isTrue);
        // And the same four are what auth_domain translates, so a dead
        // network reads the same in both halves of the app.
      });
    }

    test('anything the server said is not a network failure', () {
      expect(isNetworkFailure(Exception('permission denied')), isFalse);
      expect(isNetworkFailure(StateError('bad state')), isFalse);
    });
  });

  group('a completed sync, with no problems', () {
    test('nothing sent and nothing received reads as up to date', () {
      expect(
        manualSyncMessage(
          ManualSyncCompleted(
            push: const SyncResult(),
            pull: pull(perTable: const {'batches': 0}),
          ),
        ),
        'Already up to date.',
      );
    });

    test('both directions are reported', () {
      expect(
        manualSyncMessage(
          ManualSyncCompleted(
            push: const SyncResult(pushed: 2),
            pull: pull(perTable: const {'batches': 3}),
          ),
        ),
        '2 entries sent, 3 changes received',
      );
    });

    test('a single row is worded as one', () {
      expect(
        manualSyncMessage(
          ManualSyncCompleted(
            push: const SyncResult(pushed: 1),
            pull: pull(perTable: const {'batches': 1}),
          ),
        ),
        '1 entry sent, 1 change received',
      );
    });
  });

  group('a completed sync, with problems', () {
    test('a rejected row leads, because nothing else can fix it', () {
      final message = manualSyncMessage(
        ManualSyncCompleted(
          push: const SyncResult(pushed: 4, rejected: 1),
          pull: pull(perTable: const {'batches': 3}),
        ),
      );
      expect(message, startsWith('1 entry was rejected by the server'));
      expect(message, isNot(contains('sent,')),
          reason: 'the counts are dropped once a problem leads');
    });

    test('a failed push is worded as a connection problem, not offline', () {
      final message = manualSyncMessage(
        ManualSyncCompleted(
          push: const SyncResult(failed: 2),
          pull: pull(perTable: const {'batches': 0}),
        ),
      );
      expect(
        message,
        "2 entries couldn't be sent — check your connection.",
      );
      expect(message, isNot(equals(noInternet)));
    });

    test('some tables failing names the ratio, not the network', () {
      final message = manualSyncMessage(
        ManualSyncCompleted(
          push: const SyncResult(),
          pull: pull(
            perTable: const {'batches': 1},
            errors: const ['sales: permission denied'],
          ),
        ),
      );
      expect(message, '1 of 2 data tables couldn\'t be refreshed '
          'from the server.');
      expect(message, isNot(equals(noInternet)),
          reason: 'a table the server refused is not evidence about '
              'the radio');
    });

    test('every table failing still does not claim the device is offline',
        () {
      // The old pull-to-refresh said "No internet connection" here. It is
      // a statement about the result, and the Sync now button already had
      // better wording for it.
      final message = manualSyncMessage(
        ManualSyncCompleted(
          push: const SyncResult(),
          pull: pull(errors: const ['batches: x', 'sales: y']),
        ),
      );
      expect(message, "Couldn't reach the server. We'll sync when you're "
          "back online.");
      expect(message, isNot(equals(noInternet)));
    });

    test('several problems are joined, problems first', () {
      final message = manualSyncMessage(
        ManualSyncCompleted(
          push: const SyncResult(rejected: 1, failed: 1),
          pull: pull(errors: const ['batches: x', 'sales: y']),
        ),
      );
      expect(message, contains('1 entry was rejected'));
      expect(message, contains("1 entry couldn't be sent"));
      expect(message, contains("Couldn't reach the server"));
    });
  });
}
