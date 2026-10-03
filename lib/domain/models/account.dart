/// One account: a person's access to the system, with a fixed role.
///
/// A role is never changed after creation, promoting someone means
/// creating a second, separate account with a different role, not
/// editing this one.
///
/// This is the standard shape of an account inside the app.
/// Both the remote (Supabase) repository and a local, read-only cache
/// (for offline use on mobile) return this same shape.
///
/// This file imports nothing on purpose. It must stay safe to compile in
/// both the mobile build and the web build.
class Account {
  const Account({
    required this.accountId,
    required this.role,
    required this.name,
    required this.email,
    required this.status,
    required this.createdAt,
    this.businessId,
    this.authUserId,
  });

  final String accountId;

  /// The business is null for Super Admin, and null for a fresh Admin
  /// until they register one.
  final String? businessId;

  /// Links this account to its Supabase Auth user. Null until the
  /// person this account belongs to has actually logged in once.
  final String? authUserId;

  /// One of 'super_admin', 'admin', 'manager', 'staff'. Fixed for life.
  final String role;

  final String name;

  final String email;

  /// One of 'pending', 'active', 'inactive'.
  final String status;

  final DateTime createdAt;

  /// Builds an [Account] from a Supabase row (snake_case keys).
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      accountId: json['account_id'] as String,
      businessId: json['business_id'] as String?,
      authUserId: json['auth_user_id'] as String?,
      role: json['role'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}