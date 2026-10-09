import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/domain/models/sale.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';

/// Sales read straight from Supabase, used by the web app (Admin),
/// and by mobile's SaleDomain.refreshSales() at login. It always
/// returns [Sale] objects.
///
/// Read-only by design: Admin never records sales, and there is no
/// local database on the web.
class RemoteSaleRepository {
  RemoteSaleRepository(this._client);

  final SupabaseClient _client;

  /// All sales the signed-in account is allowed to see, oldest first.
  /// RLS scopes this — a Staff session gets zero rows back, financial
  /// data is Manager-only by design.
  Future<List<Sale>> getAll() async {
    final rows = await _client.from('sale').select().order('created_at');
    return rows.map(Sale.fromJson).toList();
  }

  /// All sales recorded against one harvest entry.
  Future<List<Sale>> getByHarvest(String harvestId) async {
    final rows = await _client
        .from('sale')
        .select()
        .eq('harvest_id', harvestId);
    return rows.map(Sale.fromJson).toList();
  }
}


/// Builds a [RemoteSaleRepository] wired to the shared Supabase client,
/// for web Admin's read-only sale views and for mobile's login-time
/// cache refresh.
final remoteSaleRepositoryProvider = Provider<RemoteSaleRepository>(
      (ref) => RemoteSaleRepository(ref.watch(supabaseClientProvider)),
);