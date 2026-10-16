import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';
import 'package:broiler_fms/domain/auth_domain.dart';

/// Web has no local cache to warm after login — webCurrentAccountProvider
/// always asks Supabase directly. The no-op callback exists only so
/// AuthDomain stays platform-agnostic and this file never imports
/// anything that could reach dart:ffi.
final authDomainProvider = Provider<AuthDomain>((ref) {
  return AuthDomain(
    supabase: ref.watch(supabaseClientProvider),
    onLoginSuccess: () async {},
    allowedRoles: const ['super_admin', 'admin'],
    wrongAppMessage:
        'This account is for the mobile app. Please log in on the phone app.',
  );
});