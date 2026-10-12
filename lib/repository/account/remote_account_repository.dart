import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:broiler_fms/domain/models/account.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/remote/supabase_provider.dart';

/// Accounts, read and written through Supabase.
///
/// Used by the web app (Super Admin managing Admins, Admin managing
/// Staff and Manager), and also called directly from mobile by Manager
/// for the staff-picker screen. Assigning Staff to a batch was judged
/// not to need offline support, so this one mobile screen talks to
/// Supabase over the network rather than through a local copy.
///
/// No role is ever changed after creation, so there is no "update role"
/// method here, only create and status changes.
class RemoteAccountRepository {
  RemoteAccountRepository(this._client);

  final SupabaseClient _client;

  /// Super Admin creates an Admin account. business_id is deliberately
  /// left null, the Admin registers their own business on first login.
  Future<Account> createAdmin({
    required String name,
    required String email,
  }) async {
    final row = await _client
        .from('account')
        .insert({'role': 'admin', 'name': name, 'email': email})
        .select()
        .single();
    return Account.fromJson(row);
  }

  /// Admin creates a Manager or Staff account for their own business.
  /// role must be 'manager' or 'staff', anything else is rejected by
  /// Postgres's own check constraint on the account table.
  Future<Account> createStaffOrManager({
    required String businessId,
    required String role,
    required String name,
    required String email,
  }) async {
    final row = await _client.from('account').insert({
      'business_id': businessId,
      'role': role,
      'name': name,
      'email': email,
    }).select().single();
    return Account.fromJson(row);
  }

  /// Sets an account's status to 'active' or 'inactive'. Works for
  /// Super Admin deactivating an Admin, and for Admin deactivating a
  /// Manager or Staff, RLS decides which one the caller is allowed to
  /// do.
  Future<void> updateStatus(String accountId, String status) {
    return _client
        .from('account')
        .update({'status': status})
        .eq('account_id', accountId);
  }

  /// All Admin accounts. Super Admin's own account management screen.
  Future<List<Account>> getAdmins() async {
    final rows = await _client
        .from('account')
        .select('*, business(name)')
        .eq('role', 'admin');
    return rows.map(Account.fromJson).toList();
  }

  /// All Manager and Staff accounts in one business. Admin's own
  /// account management screen.
  Future<List<Account>> getAccountsForBusiness(String businessId) async {
    final rows = await _client
        .from('account')
        .select()
        .eq('business_id', businessId)
        .inFilter('role', ['manager', 'staff']);
    return rows.map(Account.fromJson).toList();
  }

  /// Active Staff accounts in one business, for Manager's staff picker
  /// when assigning someone to a batch.
  Future<List<Account>> getStaffPool(String businessId) async {
    final rows = await _client
        .from('account')
        .select()
        .eq('business_id', businessId)
        .eq('role', 'staff')
        .eq('status', 'active');
    return rows.map(Account.fromJson).toList();
  }

  /// True if this business already has a Manager that is either
  /// active or still pending their first login. A pending invite
  /// still blocks a second one, since the slot is already spoken for
  /// until that invite is either accepted or the account is
  /// deactivated.
  ///
  /// [excludingAccountId] skips one row, so reactivating a
  /// deactivated Manager doesn't trip on itself, only on a *different*
  /// Manager that is already active or pending.
  Future<bool> hasActiveManager(
    String businessId, {
    String? excludingAccountId,
  }) async {
    var query = _client
        .from('account')
        .select('account_id')
        .eq('business_id', businessId)
        .eq('role', 'manager')
        .inFilter('status', ['active', 'pending']);
    if (excludingAccountId != null) {
      query = query.neq('account_id', excludingAccountId);
    }
    final rows = await query;
    return rows.isNotEmpty;
  }


/// True if an account with this email already exists in the
  /// Supabase [account] table. If [excludingAccountId] is provided,
  /// that specific account is skipped — useful for edit flows so the
  /// account's own current email is not flagged as a duplicate.
  Future<bool> emailExists({
    required String email,
    String? excludingAccountId,
  }) async {
    var query = _client
        .from('account')
        .select('account_id')
        .eq('email', email);
    if (excludingAccountId != null) {
      query = query.neq('account_id', excludingAccountId);
    }
    final rows = await query;
    return rows.isNotEmpty;
  }

  /// The account matching the currently signed-in session. Called once
  /// at login, and again whenever the cache is refreshed, so its
  /// result can be written into the local cache for offline use.
  Future<Account?> getMyAccount(String authUserId) async {
    final row = await _client
        .from('account')
        .select()
        .eq('auth_user_id', authUserId)
        .maybeSingle();
    return row == null ? null : Account.fromJson(row);
  }
} /// Builds a [RemoteAccountRepository] wired to the shared Supabase
/// client. Used by anything that needs to read or write accounts over
/// the network: the web app directly, and mobile's one-time account

/// Builds a [RemoteAccountRepository] wired to the shared Supabase client. Used by anything that needs to read or write accounts over the network: the web app directly, and mobile's one-time account pull at login.
final remoteAccountRepositoryProvider = Provider<RemoteAccountRepository>((ref) => RemoteAccountRepository(ref.watch(supabaseClientProvider)));
