import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';
import 'package:broiler_fms/presentation/mobile/forced_logout.dart';
import 'package:broiler_fms/presentation/mobile/router.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/auto_pull_host.dart';
import 'package:broiler_fms/presentation/shared/widgets/session_poller.dart';
import 'package:broiler_fms/sync/sync_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await _loadConfig();
  await Supabase.initialize(
    url: config['SUPABASE_URL'] as String,
    publishableKey: config['SUPABASE_ANON_KEY'] as String,
    // Rate the PostgREST client's patience for this mobile build. By
    // default a request has no timeout and is retried three times with a
    // 1s/2s/4s back-off, and the pull fetches its tables one after
    // another, so a phone with no signal sat on "syncing" for about a
    // minute before saying anything. Fail each request quickly instead: a
    // 12s cap and no retry keeps the offline wait to seconds. The pull
    // still completes with every table errored, so the message the person
    // sees is unchanged ("Couldn't reach the server..."). Web keeps the
    // defaults.
    postgrestOptions: mobilePostgrestOptions,
  );

  runApp(const ProviderScope(child: BroilerFmsApp()));
}

/// Reads Supabase credentials from the bundled config asset, kept out
/// of source control via .gitignore, but still shipped inside the
/// compiled app. Safe for the anon key specifically, it is designed
/// to be exposed to the client, unlike a service role key.
Future<Map<String, dynamic>> _loadConfig() async {
  final contents = await rootBundle.loadString('env/config.json');
  return jsonDecode(contents) as Map<String, dynamic>;
}

/// The mobile app's root widget, used by Staff and Manager.
class BroilerFmsApp extends ConsumerWidget {
  const BroilerFmsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The sync engine's automatic triggers, alive for as long as this
    // root widget is: one drains when connectivity comes back, the
    // other debounces a drain after local writes. Watching (rather
    // than calling start() from main()) is what keeps them running,
    // and ProviderScope's teardown is what stops them.
    ref.watch(connectivitySyncTriggerProvider);
    ref.watch(lifecycleSyncTriggerProvider);

    final router = ref.watch(mobileRouterProvider);
    // Session watch lives at the root because mobile has no persistent
    // authenticated shell — every screen is independent. The trigger
    // itself skips ticks with no signed-in session, so this is a no-op
    // while logged out.
    // Inside SessionPoller, so the automatic pull has the same lifetime as
    // the rest of the session watch and is torn down with it.
    return SessionPoller(
      onAccessLost: () => forceLogOut(ref),
      child: AutoPullHost(
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Broiler FMS',
          theme: buildAppTheme(),
          routerConfig: router,
        ),
      ),
    );
  }
}