import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/current_account_domain.dart';
import 'package:broiler_fms/domain/domain_exception.dart';
import 'package:broiler_fms/domain/models/account.dart';
import 'package:broiler_fms/domain/models/sale.dart';
import 'package:broiler_fms/domain/rules/sale_shape_rule.dart';
import 'package:broiler_fms/repository/harvest/local_harvest_repository.dart';
import 'package:broiler_fms/repository/sale/local_sale_repository.dart';

/// Mobile-side sale actions, used by Manager.
///
/// Presentation calls this class and never a repository directly.
/// recordedBy is never passed in, it is always this device's own
/// resolved current account.
class SaleDomain {
  SaleDomain({
    required LocalSaleRepository saleRepo,
    required LocalHarvestRepository harvestRepo,
    required Account currentAccount,
  })  : _saleRepo = saleRepo,
        _harvestRepo = harvestRepo,
        _currentAccount = currentAccount;

  final LocalSaleRepository _saleRepo;
  final LocalHarvestRepository _harvestRepo;
  final Account _currentAccount;

  /// Prices a harvest, after checking the harvest exists, does not
  /// already have a sale, and the fields given match the sale_shape
  /// rule.
  Future<Sale> recordSale({
    required String harvestId,
    required String disposition,
    required double amount,
    String? buyerName,
    String? pricingMethod,
    double? weightSold,
    double? pricePerUnit,
    String? paymentStatus,
  }) async {
    await _checkHarvestExists(harvestId);
    await _checkNotAlreadyPriced(harvestId);

    final shapeError = saleShapeError(
      disposition: disposition,
      amount: amount,
      pricingMethod: pricingMethod,
      weightSold: weightSold,
      pricePerUnit: pricePerUnit,
      paymentStatus: paymentStatus,
    );
    if (shapeError != null) {
      throw DomainException(shapeError);
    }

    if (pricingMethod == 'per_kg') {
      final matches = amountMatchesWeightAndPrice(
        weightSold: weightSold!,
        pricePerUnit: pricePerUnit!,
        amount: amount,
      );
      if (!matches) {
        throw const DomainException(
          'The amount does not match the weight and price entered.',
        );
      }
    }

    return _saleRepo.record(
      harvestId: harvestId,
      recordedBy: _currentAccount.accountId,
      disposition: disposition,
      amount: amount,
      buyerName: buyerName,
      pricingMethod: pricingMethod,
      weightSold: weightSold,
      pricePerUnit: pricePerUnit,
      paymentStatus: paymentStatus,
    );
  }

  /// All sales recorded against one harvest entry.
  Future<List<Sale>> getByHarvest(String harvestId) {
    return _saleRepo.getByHarvest(harvestId);
  }

  /// Throws if the harvest being priced does not exist locally.
  Future<void> _checkHarvestExists(String harvestId) async {
    final harvest = await _harvestRepo.getById(harvestId);
    if (harvest == null) {
      throw const DomainException('This harvest could not be found.');
    }
  }

  /// Throws if this harvest already has a sale recorded against it.
  Future<void> _checkNotAlreadyPriced(String harvestId) async {
    final existing = await _saleRepo.getByHarvest(harvestId);
    if (existing.isNotEmpty) {
      throw const DomainException('This harvest has already been priced.');
    }
  }
}

/// Builds a [SaleDomain] for the currently signed-in account. Throws if
/// nobody is resolved as signed in yet.
final saleDomainProvider = Provider<SaleDomain>((ref) {
  final currentAccount = ref.watch(currentAccountProvider).value;
  if (currentAccount == null) {
    throw const DomainException('No account is currently signed in.');
  }
  return SaleDomain(
    saleRepo: ref.watch(localSaleRepositoryProvider),
    harvestRepo: ref.watch(localHarvestRepositoryProvider),
    currentAccount: currentAccount,
  );
});