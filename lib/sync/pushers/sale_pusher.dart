import 'package:broiler_fms/data/local/database.dart' show SyncQueueData;
import 'package:broiler_fms/domain/models/sale.dart';
import 'package:broiler_fms/repository/sale/local_sale_repository.dart';
import 'package:broiler_fms/sync/pushers/entity_pusher.dart';
import 'package:broiler_fms/sync/sync_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pushes queued sales to Supabase's `sale` table.
///
/// Sales come last: they cannot exist before the harvest they belong
/// to has landed.
class SalePusher extends EntityPusher {
  SalePusher(this._local);

  final LocalSaleRepository _local;

  @override
  String get entityTable => 'sales';

  @override
  Future<SyncPushResult> push(SyncQueueData row, SupabaseClient client) async {
    final sale = await _local.getById(row.recordId);
    if (sale == null) return const SyncPushDropped();

    try {
      await client.from('sale').upsert(_payload(sale));

      // Sales have no syncedAt column, so the queue row is the only
      // local trace of this push.
      return const SyncPushSuccess();
    } on PostgrestException catch (e) {
      return SyncPushFailure(e.message);
    } catch (e) {
      return SyncPushFailure(e.toString());
    }
  }

  Map<String, dynamic> _payload(Sale s) {
    return {
      'sale_id': s.saleId,
      'harvest_id': s.harvestId,
      'recorded_by': s.recordedBy,
      'disposition': s.disposition,
      'amount': s.amount,
      'created_at': s.createdAt.toIso8601String(),
      'buyer_name': s.buyerName,
      'pricing_method': s.pricingMethod,
      'weight_sold': s.weightSold,
      'price_per_unit': s.pricePerUnit,
      'payment_status': s.paymentStatus,
    };
  }
}


/// Builds a [SalePusher] for the sync engine. Mobile only.
final salePusherProvider = Provider<SalePusher>(
      (ref) => SalePusher(ref.watch(localSaleRepositoryProvider)),
);
