import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/models/vaccination.dart';
import 'package:broiler_fms/repository/vaccination/remote_vaccination_repository.dart';

/// Web-side vaccination reads, used by Admin. Read-only on purpose,
/// Admin never records a vaccination, only Staff does, through
/// [VaccinationDomain] on mobile.
class RemoteVaccinationDomain {
  RemoteVaccinationDomain(this._vaccinationRepo);

  final RemoteVaccinationRepository _vaccinationRepo;

  /// All vaccination entries for one batch.
  Future<List<Vaccination>> getByBatch(String batchId) {
    return _vaccinationRepo.getByBatch(batchId);
  }
}

/// Builds a [RemoteVaccinationDomain] wired to the shared Supabase
/// client. Web only, since Admin is the only role that uses this
/// class.
final remoteVaccinationDomainProvider = Provider<RemoteVaccinationDomain>(
      (ref) =>
      RemoteVaccinationDomain(ref.watch(remoteVaccinationRepositoryProvider)),
);