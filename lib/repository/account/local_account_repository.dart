import 'package:drift/drift.dart';

import 'package:broiler_fms/data/local/database.dart' as local;
import 'package:broiler_fms/domain/models/account.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:broiler_fms/data/local/database_provider.dart';

/// Accounts cached on the device, for offline use by the mobile app.
///
/// This is a read-only cache, not a local source of truth. Mobile never
/// creates or edits an Account, Postgres's RLS already forbids it for
/// Manager and Staff. The only way data enters this table is
/// [upsertAll], overwriting whatever was here with what Supabase last
/// said. There is nothing to reconcile and no write conflict to solve,
/// which is why this does not need the general sync queue the other
/// entities use.
class LocalAccountRepository {
  LocalAccountRepository(this._db);

  final local.AppDatabase _db;

  /// Overwrites the cache with accounts just pulled from Supabase.
  Future<void> upsertAll(List<Account> accounts) {
    return _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.accounts,
        accounts.map(_toCompanion).toList(),
      );
    });
  }

  /// The cached account for this device's own logged-in session, or
  /// null if nobody has logged in on this device yet.
  Future<Account?> getMyAccount(String authUserId) async {
    final query = _db.select(_db.accounts)
      ..where((a) => a.authUserId.equals(authUserId));
    final row = await query.getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Cached active Staff accounts in one business, for Manager's staff
  /// picker when assigning someone to a batch, readable offline.
  Future<List<Account>> getStaffPool(String businessId) async {
    final query = _db.select(_db.accounts)
      ..where((a) =>
      a.businessId.equals(businessId) &
      a.role.equals('staff') &
      a.status.equals('active'));
    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  /// Same as [getStaffPool], but emits a new list when the cache changes.
  Stream<List<Account>> watchStaffPool(String businessId) {
    final query = _db.select(_db.accounts)
      ..where((a) =>
      a.businessId.equals(businessId) &
      a.role.equals('staff') &
      a.status.equals('active'));
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  /// Drift row to the standard [Account]. Lives here, not in the model,
  /// because the model must not import Drift (it would break the web
  /// build).
  Account _fromRow(local.Account row) {
    return Account(
      accountId: row.accountId,
      businessId: row.businessId,
      authUserId: row.authUserId,
      role: row.role,
      name: row.name,
      email: row.email,
      status: row.status,
      createdAt: row.createdAt,
    );
  }

  /// Standard [Account] to the values Drift needs for an upsert.
  local.AccountsCompanion _toCompanion(Account a) {
    return local.AccountsCompanion(
      accountId: Value(a.accountId),
      businessId: Value(a.businessId),
      authUserId: Value(a.authUserId),
      role: Value(a.role),
      name: Value(a.name),
      email: Value(a.email),
      status: Value(a.status),
      createdAt: Value(a.createdAt),
    );
  }
}



/// Builds a [LocalAccountRepository] wired to the shared Drift
/// database. Mobile only, never imported from anything the web build
/// can reach, same rule as [appDatabaseProvider] itself.
final localAccountRepositoryProvider = Provider<LocalAccountRepository>(
      (ref) => LocalAccountRepository(ref.watch(appDatabaseProvider)),
);