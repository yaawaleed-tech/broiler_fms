import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/account/account_domain.dart';
import 'package:broiler_fms/presentation/mobile/batch/batch_detail_screen.dart';
import 'package:broiler_fms/presentation/mobile/financial/financial_summary_screen.dart';
import 'package:broiler_fms/presentation/mobile/home/batch_card.dart';
import 'package:broiler_fms/sync/sync_providers.dart';
import 'package:broiler_fms/sync/triggers/auto_pull_trigger.dart';

/// The presentation half of an automatic pull: when the sync layer brings
/// something new down, this makes the open screens show it.
///
/// The split exists so `lib/sync` never has to import `lib/presentation`.
/// `AutoPullTrigger` lives down there and knows nothing about screens; it
/// just reports how many rows arrived, through a plain callback. This
/// widget is the other end of that callback, and is the only piece that
/// needs to know which providers a screen depends on.
///
/// Nothing is invalidated when nothing changed: a pull that brought no new
/// rows leaves every screen alone, so an idle app does not keep rebuilding
/// the same figures in the background.
///
/// The batch list needs no help — it reads through a Drift `watch()` and
/// updates itself. The two providers refreshed here are `autoDispose.family`
/// providers that only recompute when invalidated or rebuilt, so an open
/// batch screen would otherwise keep showing stale figures under a fresh
/// list. Invalidating the whole family rather than one id covers every
/// batch that might be open, and invalidating a family nobody is watching
/// is a no-op, so this is safe however many are mounted.
///
/// The Staff pool is different: it is not one of the eight tables the pull
/// fetches, and it can change without any of them moving, so it is
/// refreshed after every sync rather than only after one that brought
/// rows. That keeps a Manager's assign-staff picker current.
///
/// [child] is left untouched — this exists only to observe the trigger, the
/// same way `SessionPoller` does.
class AutoPullHost extends ConsumerStatefulWidget {
  const AutoPullHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AutoPullHost> createState() => _AutoPullHostState();
}

class _AutoPullHostState extends ConsumerState<AutoPullHost> {
  /// Held directly rather than read back from the provider in dispose:
  /// by then the ProviderScope may already be gone, and a ref.read there
  /// would throw instead of clearing the callback.
  AutoPullTrigger? _trigger;

  @override
  void initState() {
    super.initState();
    _trigger = ref.read(autoPullTriggerProvider);
    // onAppStart rather than letting the provider start it: the provider
    // body already called start(), which registers the resume observer and
    // the connectivity listener. This is the third moment, app start.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _trigger?.onAppStart();
    });
  }

  @override
  void dispose() {
    // Drop the callbacks first, so a run finishing after this widget goes
    // away cannot reach a disposed State. The trigger is held directly
    // because the ProviderScope may already have been torn down.
    _trigger?.onChangesArrived = null;
    _trigger?.onSyncCompleted = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watched so the trigger is built (and started) for the whole session,
    // and so a rebuild re-reads the callback below.
    final trigger = ref.watch(autoPullTriggerProvider);
    _trigger = trigger;
    trigger.onChangesArrived = _refreshOpenScreens;
    trigger.onSyncCompleted = _syncCompleted;
    return widget.child;
  }

  /// Called after every pull, changed or not.
  ///
  /// The Staff pool is refreshed here rather than under
  /// [_refreshOpenScreens], because a pull that brought no entity rows can
  /// still have brought a new Staff account: the pool is not one of the
  /// eight tables the pull fetches, so nothing else would notice.
  void _syncCompleted(int updated) {
    unawaited(_refreshStaffPool());
  }

  /// Rebuilds whatever is on screen, because a pull just changed the data
  /// underneath it.
  void _refreshOpenScreens(int updated) {
    if (updated <= 0) return;
    // The status pill reads the queue's live count, which a push may have
    // just emptied.
    ref.invalidate(syncStatusProvider);
    // Whole families: every open batch, not just the one we happen to know
    // about.
    ref.invalidate(batchDetailProvider);
    ref.invalidate(financialSummaryProvider);
    // The home card's remaining-bird count reads the entry tables, which
    // the batches table the list streams does not touch, so a pull must
    // drop it explicitly or the count stays stale on the home list.
    ref.invalidate(batchRemainingProvider);
  }

  /// Refreshes the cached Staff pool from the server, best-effort.
  ///
  /// Offline, signed out, or a screen that has gone away: the cached pool
  /// stays exactly as it was, which is the point — the list still works
  /// from the last copy. A Manager's assign-staff picker reads this
  /// cache, and the pool is not one of the tables a pull fetches, so
  /// without this the picker would keep showing whatever was cached at
  /// login.
  Future<void> _refreshStaffPool() async {
    try {
      await ref.read(accountDomainProvider).refreshStaffPool();
    } catch (_) {
      // Nothing to do: the cached pool is still good enough to show.
    }
  }
}