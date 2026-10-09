import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';
import 'package:broiler_fms/domain/auth_domain.dart';
import 'package:broiler_fms/domain/batch/batch_domain.dart';
import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/expense/expense_domain.dart';
import 'package:broiler_fms/domain/feed/feed_domain.dart';
import 'package:broiler_fms/domain/harvest/harvest_domain.dart';
import 'package:broiler_fms/domain/mortality/mortality_domain.dart';
import 'package:broiler_fms/domain/sale/sale_domain.dart';
import 'package:broiler_fms/domain/vaccination/vaccination_domain.dart';
import 'package:broiler_fms/domain/weight/weight_domain.dart';
import 'package:broiler_fms/sync/sync_providers.dart';

final authDomainProvider = Provider<AuthDomain>((ref) {
  final currentAccountDomain = ref.watch(currentAccountDomainProvider);
  final syncService = ref.watch(syncServiceProvider);
  return AuthDomain(
    supabase: ref.watch(supabaseClientProvider),
    onLoginSuccess: () async {
      // Account cache first: drain() pushes under the session that
      // resolveAndCacheMyAccount() has just finished warming. Anything
      // queued while this phone was offline gets its first push here.
      // Not awaited — login must not wait on the queue draining.
      await currentAccountDomain.resolveAndCacheMyAccount();
      // That write just changed the right answer to "who's signed in",
      // so drop the stale one before reading anything built on it —
      // batchDomainProvider included.
      ref.invalidate(currentAccountProvider);
      await ref.read(currentAccountProvider.future);
      unawaited(syncService.drain());
      // Everything below comes down in the same beat: the sync queue
      // only ever pushes these tables up, so a row another device
      // recorded first becomes visible here, at next login — the batch
      // a Manager just assigned to this Staff account included. RLS
      // scopes each pull per role, nothing enqueues on the way in, and
      // each pull is isolated: never blocks login, a failed one keeps
      // that cache as it was and the next login tries again.
      Future<void> pullSafely(Future<void> Function() pull) async {
        try {
          await pull();
        } catch (e) {
          // Deliberately ignored; see above.
        }
      }

      await pullSafely(() => ref.read(batchDomainProvider).refreshBatches());
      await pullSafely(() => ref.read(expenseDomainProvider).refreshExpenses());
      await pullSafely(
        () => ref.read(mortalityDomainProvider).refreshMortalityEntries(),
      );
      await pullSafely(() => ref.read(feedDomainProvider).refreshFeedEntries());
      await pullSafely(
        () => ref.read(weightDomainProvider).refreshWeightSamples(),
      );
      await pullSafely(
        () => ref.read(vaccinationDomainProvider).refreshVaccinationEntries(),
      );
      await pullSafely(
        () => ref.read(harvestDomainProvider).refreshHarvestEntries(),
      );
      await pullSafely(() => ref.read(saleDomainProvider).refreshSales());
    },
  );
});