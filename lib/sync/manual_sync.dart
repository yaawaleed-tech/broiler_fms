import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;

import 'pull_service.dart';
import 'sync_result.dart';

/// Why a manual sync never started.
enum ManualSyncSkip {
  /// No Supabase session at all.
  signedOut,

  /// A session exists but the account behind it could not be read: an
  /// error, a null account, or the wait for it ran out.
  ///
  /// Never to be reported as a network problem. The session was restored
  /// fine; it is the account record that is not there yet.
  accountNotReady,
}

/// What one attempt at a manual sync actually did.
///
/// A sealed type rather than a nullable result, because the whole reason
/// the Sync now button and pull-to-refresh used to disagree is that one of
/// them collapsed five different "did not run" reasons into a single
/// `null` and then guessed that the reason was the network. Every way this
/// can end is a case here, and the message mapper has to handle all of
/// them.
///
/// Deliberately free of any role logic, like everything else in `lib/sync`.
sealed class ManualSyncOutcome {
  const ManualSyncOutcome();
}

/// The drain and the pull both completed. Whether every table landed, and
/// whether any rows were rejected, is read off [push] and [pull] rather
/// than being pre-digested here — those two types already carry it.
class ManualSyncCompleted extends ManualSyncOutcome {
  const ManualSyncCompleted({required this.push, required this.pull});

  final SyncResult push;
  final PullResult pull;
}

/// Nothing ran. [reason] says which guard stopped it, so the message can
/// say something true instead of blaming the network.
class ManualSyncSkipped extends ManualSyncOutcome {
  const ManualSyncSkipped(this.reason);

  final ManualSyncSkip reason;
}

/// The request itself did not get through: a socket, an HTTP client, or a
/// timeout.
///
/// The only outcome that may claim the network is the problem. This is a
/// statement about what the request did, not about what connectivity_plus
/// said the radio was doing.
class ManualSyncNetworkFailure extends ManualSyncOutcome {
  const ManualSyncNetworkFailure();
}

/// Something failed that was not the network — a server rejection that
/// escaped as an exception, a local database error, anything at all.
class ManualSyncFailed extends ManualSyncOutcome {
  const ManualSyncFailed(this.error);

  final Object error;
}

/// Whether [error] is a failure of the connection itself.
///
/// The list is deliberately the same four types [AuthDomain] translates,
/// so a dead network reads the same everywhere in the app and nobody has
/// to learn two vocabularies for it. Deliberately narrow the other way
/// too: an `AuthException` or a `PostgrestException` means the server was
/// reached and had an opinion, and those keep their own words.
bool isNetworkFailure(Object error) {
  return error is SocketException ||
      error is HttpException ||
      error is ClientException ||
      error is TimeoutException;
}
