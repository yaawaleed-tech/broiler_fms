import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';
import 'package:broiler_fms/domain/auth_domain.dart';
import 'package:broiler_fms/domain/current_account_domain.dart';

final authDomainProvider = Provider<AuthDomain>((ref) {
  final currentAccountDomain = ref.watch(currentAccountDomainProvider);
  return AuthDomain(
    supabase: ref.watch(supabaseClientProvider),
    onLoginSuccess: currentAccountDomain.resolveAndCacheMyAccount,
  );
});