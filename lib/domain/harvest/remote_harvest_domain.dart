import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/models/harvest.dart';
import 'package:broiler_fms/repository/harvest/remote_harvest_repository.dart';

/// Web-side harvest reads, used by Admin. Read-only on purpose, Admin
/// never writes a harvest, only Staff does, through [HarvestDomain] on
/// mobile.
class RemoteHarvestDomain {
  RemoteHarvestDomain(this._harvestRepo);

  final RemoteHarvestRepository _harvestRepo;

  /// All harvest entries for one batch.
  Future<List<Harvest>> getByBatch(String batchId) {
    return _harvestRepo.getByBatch(batchId);
  }
}

/// Builds a [RemoteHarvestDomain] wired to the shared Supabase client.
/// Web only, since Admin is the only role that uses this class.
final remoteHarvestDomainProvider = Provider<RemoteHarvestDomain>(
      (ref) => RemoteHarvestDomain(ref.watch(remoteHarvestRepositoryProvider)),
);