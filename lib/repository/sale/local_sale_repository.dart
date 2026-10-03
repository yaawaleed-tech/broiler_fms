import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import 'package:broiler_fms/data/local/database.dart' as local;
import 'package:broiler_fms/domain/models/sale.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/local/database_provider.dart';

/// Sales stored on the device, used by the mobile app (Manager). It talks
/// only to Drift and always returns [Sale] objects.
///
/// Getting these sales up to Supabase is the Sync Engine's job, not this
/// class's.
class LocalSaleRepository {
  LocalSaleRepository(this._db);

  final local.AppDatabase _db;
  static const _uuid = Uuid();

  /// Saves a new sale on the device and returns it.
  /// The id is created here so the sale works fully offline.
  ///
  /// The database rejects combinations that break the pricing rules
  /// (for example a per_kg sale with no weight), so callers should
  /// validate first and treat a thrown error as a last line of defence.
  Future<Sale> record({
    required String harvestId,
    required String recordedBy,
    required String disposition,
    required double amount,
    String? buyerName,
    String? pricingMethod,
    double? weightSold,
    double? pricePerUnit,
    String? paymentStatus,
  }) async {
    final sale = Sale(
      saleId: _uuid.v4(),
      harvestId: harvestId,
      recordedBy: recordedBy,
      disposition: disposition,
      amount: amount,
      createdAt: DateTime.now(),
      buyerName: buyerName,
      pricingMethod: pricingMethod,
      weightSold: weightSold,
      pricePerUnit: pricePerUnit,
      paymentStatus: paymentStatus,
    );
    await _db.into(_db.sales).insert(_toCompanion(sale));
    return sale;
  }

  /// All sales recorded against one harvest entry.
  Future<List<Sale>> getByHarvest(String harvestId) async {
    final query = _db.select(_db.sales)
      ..where((s) => s.harvestId.equals(harvestId));
    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  /// Drift row to the standard [Sale]. Lives here, not in the model,
  /// because the model must not import Drift (it would break the web build).
  Sale _fromRow(local.Sale row) {
    return Sale(
      saleId: row.saleId,
      harvestId: row.harvestId,
      recordedBy: row.recordedBy,
      disposition: row.disposition,
      amount: row.amount,
      createdAt: row.createdAt,
      buyerName: row.buyerName,
      pricingMethod: row.pricingMethod,
      weightSold: row.weightSold,
      pricePerUnit: row.pricePerUnit,
      paymentStatus: row.paymentStatus,
    );
  }

  /// Standard [Sale] to the values Drift needs for an insert.
  local.SalesCompanion _toCompanion(Sale s) {
    return local.SalesCompanion(
      saleId: Value(s.saleId),
      harvestId: Value(s.harvestId),
      recordedBy: Value(s.recordedBy),
      disposition: Value(s.disposition),
      amount: Value(s.amount),
      createdAt: Value(s.createdAt),
      buyerName: Value(s.buyerName),
      pricingMethod: Value(s.pricingMethod),
      weightSold: Value(s.weightSold),
      pricePerUnit: Value(s.pricePerUnit),
      paymentStatus: Value(s.paymentStatus),
    );
  }
}


/// Builds a [LocalSaleRepository] wired to the shared Drift database.
/// Mobile only.
final localSaleRepositoryProvider = Provider<LocalSaleRepository>(
      (ref) => LocalSaleRepository(ref.watch(appDatabaseProvider)),
);