import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/models/vaccination.dart';
import 'package:broiler_fms/repository/batch/local_batch_repository.dart';
import 'package:broiler_fms/repository/vaccination/local_vaccination_repository.dart';
import 'package:broiler_fms/repository/vaccination/remote_vaccination_repository.dart';

/// Mobile-side vaccination actions, used by Staff.
///
/// No bird-count rule applies here, a vaccination does not change how
/// many birds are in a batch. Only the open-batch check applies.
class VaccinationDomain {
  VaccinationDomain({
    required LocalVaccinationRepository vaccinationRepo,
    required RemoteVaccinationRepository remoteVaccinationRepo,
    required LocalBatchRepository batchRepo,
    required Account currentAccount,
  })  : _vaccinationRepo = vaccinationRepo,
        _remoteVaccinationRepo = remoteVaccinationRepo,
        _batchRepo = batchRepo,
        _currentAccount = currentAccount;

  final LocalVaccinationRepository _vaccinationRepo;
  final RemoteVaccinationRepository _remoteVaccinationRepo;
  final LocalBatchRepository _batchRepo;
  final Account _currentAccount;

  /// Records a vaccination entry, after checking the batch is open.
  Future<Vaccination> recordVaccination({
    required String batchId,
    required DateTime date,
    required String vaccineName,
  }) async {
    await _checkBatchOpen(batchId);
    return _vaccinationRepo.record(
      batchId: batchId,
      recordedBy: _currentAccount.accountId,
      date: date,
      vaccineName: vaccineName,
    );
  }

  /// All vaccination entries for one batch.
  Future<List<Vaccination>> getByBatch(String batchId) {
    return _vaccinationRepo.getByBatch(batchId);
  }

  /// Same as [getByBatch], but emits a new list whenever the data
  /// changes.
  Stream<List<Vaccination>> watchByBatch(String batchId) {
    return _vaccinationRepo.watchByBatch(batchId);
  }

  /// Pulls the latest vaccination entries from Supabase and
  /// overwrites the local cache — same contract as
  /// BatchDomain.refreshBatches(): needs connectivity, RLS scopes
  /// the rows to this account's own business (Staff: only assigned
  /// batches), and nothing enqueues because this data already lives
  /// on the server.
  Future<void> refreshVaccinationEntries() async {
    final vaccinations = await _remoteVaccinationRepo.getAll();
    await _vaccinationRepo.upsertAll(vaccinations);
  }

  /// Throws if the batch is missing or already closed.
  Future<void> _checkBatchOpen(String batchId) async {
    final batch = await _batchRepo.getById(batchId);
    if (batch == null) {
      throw const DomainException('This batch could not be found.');
    }
    if (batch.isClosed) {
      throw const DomainException(
        'This batch is closed, so no more vaccinations can be recorded.',
      );
    }
  }
}

/// Builds a [VaccinationDomain] for the currently signed-in account.
/// Throws if nobody is resolved as signed in yet.
final vaccinationDomainProvider = Provider<VaccinationDomain>((ref) {
  final currentAccount = ref.watch(currentAccountProvider).value;
  if (currentAccount == null) {
    throw const DomainException('No account is currently signed in.');
  }
  return VaccinationDomain(
    vaccinationRepo: ref.watch(localVaccinationRepositoryProvider),
    remoteVaccinationRepo: ref.watch(remoteVaccinationRepositoryProvider),
    batchRepo: ref.watch(localBatchRepositoryProvider),
    currentAccount: currentAccount,
  );
});