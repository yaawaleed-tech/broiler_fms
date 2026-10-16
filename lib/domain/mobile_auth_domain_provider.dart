import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';
import 'package:broiler_fms/domain/auth_domain.dart';
import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/sync/pull_service.dart';
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
      //
      // The pull itself lives in PullService now, so the mobile "Sync
      // now" button runs exactly the same code path rather than a
      // second copy of it drifting out of step.
      await ref.read(pullServiceProvider).pullAll();
    },
    allowedRoles: const ['manager', 'staff'],
    wrongAppMessage:
        'This account is for the web app. Please log in on the web.',
  );
});