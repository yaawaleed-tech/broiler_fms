import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The shared Supabase client. Used by both mobile and web, since both
/// platforms talk to Supabase, mobile for Account and for sync later,
/// web for everything.
final supabaseClientProvider =
Provider<SupabaseClient>((ref) => Supabase.instance.client);