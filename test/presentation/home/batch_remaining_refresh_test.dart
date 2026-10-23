import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:broiler_fms/domain/account/account_domain.dart';
import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/presentation/mobile/financial/financial_refresh.dart';
import 'package:broiler_fms/presentation/mobile/home/batch_card.dart';
import 'package:broiler_fms/presentation/shared/widgets/auto_pull_host.dart';
import 'package:broiler_fms/sync/pull_service.dart';
import 'package:broiler_fms/sync/sync_providers.dart';
import 'package:broiler_fms/sync/sync_service.dart';
import 'package:broiler_fms/sync/triggers/auto_pull_trigger.dart';

/// The remaining-bird count on the home card.
///
/// The card's count reads the entry tables (mortality, harvest), but the
/// list itself streams the batches table, so a saved entry or a pulled
/// entry never reached the count: it stayed stale until the card happened
/// to rebuild for some other reason.
class _FakeBatchDomain extends Fake implements BatchDomain {
  int remaining = 100;

  @override
  Future<int> getRemainingBirdCount(String batchId) async => remaining;
}

class _FakeAccountDomain extends Fake implements AccountDomain {
  int refreshCalls = 0;

  @override
  Future<void> refreshStaffPool() async {
    refreshCalls++;
  }

  @override
  Stream<List<Account>> watchStaffPool(String businessId) =>
      Stream.value(const []);
}

/// A sync service that never runs: these tests drive the trigger's
/// callbacks directly, the way the real sync layer does when a pull
/// lands.
class _UnusedSyncService extends Fake implements SyncService {}

class _UnusedPullService extends Fake implements PullService {}

void main() {
  testWidgets('a saved entry refreshes the count on the home card', (
    tester,
  ) async {
    final batchDomain = _FakeBatchDomain();
    late WidgetRef capturedRef;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [batchDomainProvider.overrideWithValue(batchDomain)],
        child: Consumer(
          builder: (context, ref, child) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Consumer)),
    );
    final sub = container.listen(batchRemainingProvider('batch-1'), (_, _) {});
    addTearDown(sub.close);
    await tester.pump();
    expect(await container.read(batchRemainingProvider('batch-1').future), 100);

    // A mortality entry was saved: the count has to follow.
    batchDomain.remaining = 60;
    invalidateBatchFinancials(capturedRef, 'batch-1');
    await tester.pump();

    expect(await container.read(batchRemainingProvider('batch-1').future), 60);
  });

  testWidgets('a pull refreshes the count on the home card', (tester) async {
    final batchDomain = _FakeBatchDomain();
    final trigger = AutoPullTrigger(
      _UnusedSyncService(),
      _UnusedPullService(),
      hasAccount: () => true,
    );
    addTearDown(trigger.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          batchDomainProvider.overrideWithValue(batchDomain),
          autoPullTriggerProvider.overrideWithValue(trigger),
          syncStatusProvider.overrideWith(
            (ref) => Stream<SyncStatus>.value(
              const SyncStatus(isOnline: true, pendingCount: 0),
            ),
          ),
        ],
        child: const MaterialApp(home: AutoPullHost(child: Text('content'))),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AutoPullHost)),
      listen: false,
    );
    final sub = container.listen(batchRemainingProvider('batch-1'), (_, _) {});
    addTearDown(sub.close);
    await tester.pump();
    expect(await container.read(batchRemainingProvider('batch-1').future), 100);

    // A pull brought a new mortality entry down.
    batchDomain.remaining = 42;
    trigger.onChangesArrived?.call(3);
    await tester.pump();

    expect(await container.read(batchRemainingProvider('batch-1').future), 42);
  });

  testWidgets(
    'a sync refreshes the Staff pool even when nothing else changed',
    (tester) async {
      // The Staff pool is not one of the eight tables the pull fetches, so a
      // sync that brought no entity rows can still have brought a new Staff
      // account. The pool has to be refreshed all the same.
      final accountDomain = _FakeAccountDomain();
      final trigger = AutoPullTrigger(
        _UnusedSyncService(),
        _UnusedPullService(),
        hasAccount: () => true,
      );
      addTearDown(trigger.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountDomainProvider.overrideWithValue(accountDomain),
            autoPullTriggerProvider.overrideWithValue(trigger),
            syncStatusProvider.overrideWith(
              (ref) => Stream<SyncStatus>.value(
                const SyncStatus(isOnline: true, pendingCount: 0),
              ),
            ),
          ],
          child: const MaterialApp(home: AutoPullHost(child: Text('content'))),
        ),
      );
      await tester.pump();

      expect(accountDomain.refreshCalls, 0, reason: 'nothing has synced yet');

      // A sync that brought no rows at all.
      trigger.onSyncCompleted?.call(0);
      await tester.pump();

      expect(accountDomain.refreshCalls, 1);
    },
  );
}
