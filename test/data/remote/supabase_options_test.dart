import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';

/// How the mobile build talks to Supabase.
///
/// An offline phone used to sit on a spinning sync button for about a
/// minute: every request had no timeout of its own, and every request was
/// retried three times with a 1s, 2s then 4s back-off, across eight
/// tables pulled one after another.
///
/// The web build is left alone on purpose: it has no offline story and
/// no phone-sized network to be kind to.
void main() {
  test('the mobile client caps how long a request may take', () {
    // The brief asked for roughly ten to fifteen seconds: long enough for
    // a slow connection to get through, short enough that a person does
    // not think the app has hung.
    expect(
      mobileRequestTimeout,
      greaterThanOrEqualTo(const Duration(seconds: 10)),
    );
    expect(
      mobileRequestTimeout,
      lessThanOrEqualTo(const Duration(seconds: 15)),
    );
  });

  test('the mobile client does not retry a failed request', () {
    // The back-off, not the request itself, was what made the wait a
    // minute: three retries per table, eight tables, one after another.
    expect(mobilePostgrestOptions.retryEnabled, isFalse);
    expect(mobilePostgrestOptions.retryCount, 0);
  });

  test('the mobile client applies the timeout to every request', () {
    expect(mobilePostgrestOptions.requestTimeout, mobileRequestTimeout);
  });
}
