import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/domain/models/business.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';
/// The business, read and written through Supabase, used by the web app
/// (Admin). There is no local (Drift) side for Business at all, Admin's
/// business_id is null until this repository registers one.
class RemoteBusinessRepository {
  RemoteBusinessRepository(this._client);

  final SupabaseClient _client;

  /// Registers the business for the calling Admin's account. Calls the
  /// register_business() Postgres function, which creates the business
  /// row and links it to the caller's own account in one atomic step,
  /// something a plain insert cannot do (see schema.sql, section 4).
  Future<String> register({
    required String name,
    String? address,
    String? phone,
    String? businessType,
    String? description,
  }) {
    return _client.rpc('register_business', params: {
      'p_name': name,
      'p_address': address,
      'p_phone': phone,
      'p_business_type': businessType,
      'p_description': description,
    });
  }

  /// The calling Admin's own business. RLS already limits this to the
  /// caller's own business, so no filter is needed here.
  Future<Business?> getOwnBusiness() async {
    final row =
        await _client.from('business').select().maybeSingle();
    return row == null ? null : Business.fromJson(row);
  }

  /// Updates the business's editable fields. Only the fields passed in
  /// are changed, anything left null here stays as it was.
  Future<void> updateProfile({
    required String businessId,
    String? name,
    String? address,
    String? phone,
    String? businessType,
    String? description,
  }) {
    final changes = <String, dynamic>{};
    if (name != null) changes['name'] = name;
    if (address != null) changes['address'] = address;
    if (phone != null) changes['phone'] = phone;
    if (businessType != null) changes['business_type'] = businessType;
    if (description != null) changes['description'] = description;

    return _client
        .from('business')
        .update(changes)
        .eq('business_id', businessId);
  }
}


/// Builds a [RemoteBusinessRepository] wired to the shared Supabase
/// client. Web only, used by Admin.
final remoteBusinessRepositoryProvider = Provider<RemoteBusinessRepository>(
      (ref) => RemoteBusinessRepository(ref.watch(supabaseClientProvider)),
);