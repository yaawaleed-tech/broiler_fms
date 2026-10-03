import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/models/sale.dart';
import 'package:broiler_fms/repository/sale/remote_sale_repository.dart';

/// Web-side sale reads, used by Admin. Read-only on purpose, Admin
/// never records a sale, only Manager does, through [SaleDomain] on
/// mobile.
class RemoteSaleDomain {
  RemoteSaleDomain(this._saleRepo);

  final RemoteSaleRepository _saleRepo;

  /// All sales recorded against one harvest entry.
  Future<List<Sale>> getByHarvest(String harvestId) {
    return _saleRepo.getByHarvest(harvestId);
  }
}

/// Builds a [RemoteSaleDomain] wired to the shared Supabase client.
/// Web only, since Admin is the only role that uses this class.
final remoteSaleDomainProvider = Provider<RemoteSaleDomain>(
      (ref) => RemoteSaleDomain(ref.watch(remoteSaleRepositoryProvider)),
);