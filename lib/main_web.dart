import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/web/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = await _loadConfig();
  await Supabase.initialize(
    url: config['SUPABASE_URL'] as String,
    publishableKey: config['SUPABASE_ANON_KEY'] as String,
  );

  runApp(const ProviderScope(child: BroilerFmsWebApp()));
}

/// Reads Supabase credentials from the same bundled config asset
/// mobile's main.dart already uses. One shared config file, two
/// separate entry points, matching the project's two-build-target
/// architecture decided at the very start.
Future<Map<String, dynamic>> _loadConfig() async {
  final contents = await rootBundle.loadString('env/config.json');
  return jsonDecode(contents) as Map<String, dynamic>;
}

/// The web app's root widget, used by Admin and Super Admin.
class BroilerFmsWebApp extends ConsumerWidget {
  const BroilerFmsWebApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(webRouterProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Broiler FMS — Web',
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}