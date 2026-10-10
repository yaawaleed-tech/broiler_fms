import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/logout_domain.dart';
import 'package:broiler_fms/domain/session_poll_trigger.dart';
import 'package:broiler_fms/presentation/mobile/router.dart';
import 'package:broiler_fms/presentation/shared/theme/app_theme.dart';
import 'package:broiler_fms/presentation/shared/widgets/session_poller.dart';
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

/// Forced logout from the session poller: runs forcedLogOut (bounded
/// drain, then wipe-or-keep), drops the cached account, and goes to
/// login with an explanation. Never blocked by unsynced data, unlike
/// the voluntary logout — the lockout always happens, only the fate
/// of local rows differs.
Future<void> _forceLogOut(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(logoutDomainProvider).forcedLogOut();
  } catch (_) {
    // Forced means forced: the lockout proceeds regardless.
  }
  ref.invalidate(currentAccountProvider);
  if (context.mounted) {
    context.go('/login', extra: forcedLogoutMessage);
  }
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
    return SessionPoller(
      onAccessLost: () => _forceLogOut(context, ref),
      child: MaterialApp.router(
        title: 'Broiler FMS',
        theme: buildAppTheme(),
        routerConfig: router,
      ),
    );
  }
}