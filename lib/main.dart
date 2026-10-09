import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/presentation/mobile/router.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/sync/sync_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await _loadConfig();
  await Supabase.initialize(
    url: config['SUPABASE_URL'] as String,
    publishableKey: config['SUPABASE_ANON_KEY'] as String,
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
    return MaterialApp.router(
      title: 'Broiler FMS',
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}