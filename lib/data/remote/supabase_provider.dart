import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The shared Supabase client. Used by both mobile and web, since both
/// platforms talk to Supabase, mobile for Account and for sync later,
/// web for everything.
final supabaseClientProvider =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);

/// The per-request cap behind [mobilePostgrestOptions], named so a test
/// can read the number without reaching into a library type.
const mobileRequestTimeout = Duration(seconds: 12);

/// How the mobile build talks to the PostgREST API.
///
/// A named constant rather than an inline literal, so a test can state
/// what the mobile app is allowed to wait for.
///
/// Two defaults are worth overriding, and both cost the same person about
/// a minute of staring at a spinning sync button with no signal:
///
/// * A request has no timeout by default, so a request that never
///   connects waits for the operating system's own TCP timeout.
/// * A request is retried three times by default, with a 1s, 2s then 4s
///   back-off, and the pull fetches its tables one after another, so
///   eight tables cost eight rounds of that.
///
/// Capping each request at [mobileRequestTimeout] and turning the retry
/// off makes an offline phone fail in seconds instead of about a minute.
/// The pull still completes with every table reported as an error, so
/// the message the person reads is unchanged: "Couldn't reach the server.
/// We'll sync when you're back online."
const mobilePostgrestOptions = PostgrestClientOptions(
  requestTimeout: mobileRequestTimeout,
  retryEnabled: false,
  retryCount: 0,
);