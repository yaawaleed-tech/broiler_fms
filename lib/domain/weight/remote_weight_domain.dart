import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/models/weight_sample.dart';
import 'package:broiler_fms/repository/weight/remote_weight_repository.dart';

/// Web-side weight sample reads, used by Admin. Read-only on purpose,
/// Admin never records a weight sample, only Staff does, through
/// [WeightDomain] on mobile.
class RemoteWeightDomain {
  RemoteWeightDomain(this._weightRepo);

  final RemoteWeightRepository _weightRepo;

  /// All weight samples for one batch.
  Future<List<WeightSample>> getByBatch(String batchId) {
    return _weightRepo.getByBatch(batchId);
  }
}

/// Builds a [RemoteWeightDomain] wired to the shared Supabase client.
/// Web only, since Admin is the only role that uses this class.
final remoteWeightDomainProvider = Provider<RemoteWeightDomain>(
      (ref) => RemoteWeightDomain(ref.watch(remoteWeightRepositoryProvider)),
);