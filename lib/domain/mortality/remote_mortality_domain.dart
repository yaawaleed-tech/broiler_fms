import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/models/mortality.dart';
import 'package:broiler_fms/repository/mortality/remote_mortality_repository.dart';

/// Web-side mortality reads, used by Admin. Read-only on purpose, Admin
/// never records a mortality entry, only Staff does, through
/// [MortalityDomain] on mobile.
class RemoteMortalityDomain {
  RemoteMortalityDomain(this._mortalityRepo);

  final RemoteMortalityRepository _mortalityRepo;

  /// All mortality entries for one batch.
  Future<List<Mortality>> getByBatch(String batchId) {
    return _mortalityRepo.getByBatch(batchId);
  }
}

/// Builds a [RemoteMortalityDomain] wired to the shared Supabase
/// client. Web only, since Admin is the only role that uses this
/// class.
final remoteMortalityDomainProvider = Provider<RemoteMortalityDomain>(
      (ref) => RemoteMortalityDomain(ref.watch(remoteMortalityRepositoryProvider)),
);