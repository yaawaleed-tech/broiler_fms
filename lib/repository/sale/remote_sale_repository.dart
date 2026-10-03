import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/domain/models/sale.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';

/// Sales read straight from Supabase, used by the web app (Admin).
/// It always returns [Sale] objects.
///
/// Read-only by design: Admin never records sales, and there is no
/// local database on the web.
class RemoteSaleRepository {
  RemoteSaleRepository(this._client);

  final SupabaseClient _client;

  /// All sales recorded against one harvest entry.
  Future<List<Sale>> getByHarvest(String harvestId) async {
    final rows = await _client
        .from('sale')
        .select()
        .eq('harvest_id', harvestId);
    return rows.map(Sale.fromJson).toList();
  }
}


/// Builds a [RemoteSaleRepository] wired to the shared Supabase client.
/// Used by Admin's read-only sale views on web.
final remoteSaleRepositoryProvider = Provider<RemoteSaleRepository>(
      (ref) => RemoteSaleRepository(ref.watch(supabaseClientProvider)),
);