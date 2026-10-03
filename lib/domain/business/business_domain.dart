import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/domain/models/business.dart';
import 'package:broiler_fms/repository/business/remote_business_repository.dart';

/// Web-side business actions, used by Admin. No local (Drift) side at
/// all, by design, Manager and Staff never touch business data.
class BusinessDomain {
  BusinessDomain(this._businessRepo);

  final RemoteBusinessRepository _businessRepo;

  /// Registers the calling Admin's business, through the atomic
  /// register_business() Postgres function.
  Future<String> registerBusiness({
    required String name,
    String? address,
    String? phone,
    String? businessType,
    String? description,
  }) {
    return _businessRepo.register(
      name: name,
      address: address,
      phone: phone,
      businessType: businessType,
      description: description,
    );
  }

  /// The calling Admin's own business.
  Future<Business?> getOwnBusiness() {
    return _businessRepo.getOwnBusiness();
  }

  /// Updates the business's editable fields.
  Future<void> updateProfile({
    required String businessId,
    String? name,
    String? address,
    String? phone,
    String? businessType,
    String? description,
  }) {
    return _businessRepo.updateProfile(
      businessId: businessId,
      name: name,
      address: address,
      phone: phone,
      businessType: businessType,
      description: description,
    );
  }
}

/// Builds a [BusinessDomain] wired to the shared Supabase client. Web
/// only, used by Admin.
final businessDomainProvider = Provider<BusinessDomain>(
      (ref) => BusinessDomain(ref.watch(remoteBusinessRepositoryProvider)),
);