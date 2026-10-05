import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/repository/account/remote_account_repository.dart';

/// Web's own answer to "who is signed in," kept completely separate
/// from CurrentAccountDomain. That class requires LocalAccountRepository,
/// which imports database.dart, which imports dart:ffi through Drift's
/// native sqlite3 bindings, unavailable on web. Importing that file
/// from anywhere web's router can reach breaks the web build outright,
/// regardless of whether the local methods are ever actually called,
/// since this is a static import the compiler must resolve.
///
/// Web has no local cache to read, no offline need, and always has
/// connectivity when the browser is running the app at all, so it
/// simply asks Supabase directly, every time.
final webCurrentAccountProvider = FutureProvider<Account?>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final authUserId = supabase.auth.currentUser?.id;
  if (authUserId == null) return null;
  final remoteAccountRepo = ref.watch(remoteAccountRepositoryProvider);
  return remoteAccountRepo.getMyAccount(authUserId);
});