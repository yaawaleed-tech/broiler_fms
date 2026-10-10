import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/session_poll_trigger.dart';

/// Keeps [child] under session watch: starts the shared poll trigger
/// with [onAccessLost] while mounted, stops it on unmount.
///
/// Exists because a bare provider timer can drive neither logout
/// (needs a WidgetRef) nor navigation (neither router has a
/// refreshListenable, so invalidating an account provider alone never
/// moves the user) — this widget supplies ref, context, and mounted
/// from its own State, which is why every authenticated root wraps
/// its content in one of these instead of watching the trigger
/// directly.
class SessionPoller extends ConsumerStatefulWidget {
  const SessionPoller({
    super.key,
    required this.child,
    required this.onAccessLost,
  });

  final Widget child;
  final Future<void> Function() onAccessLost;

  @override
  ConsumerState<SessionPoller> createState() => _SessionPollerState();
}

class _SessionPollerState extends ConsumerState<SessionPoller> {
  late final SessionPollTrigger _trigger;

  @override
  void initState() {
    super.initState();
    _trigger = ref.read(sessionPollTriggerProvider);
    _trigger.onAccessLost = widget.onAccessLost;
    _trigger.start();
  }

  @override
  void dispose() {
    _trigger.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionPollTriggerProvider);
    return widget.child;
  }
}
