/// One business, the farm this whole system is set up for.
///
/// This is the standard shape of a business inside the app. Only the
/// remote (Supabase) repository ever returns this, mobile never touches
/// Business at all.
///
/// This file imports nothing on purpose. It must stay safe to compile in
/// both the mobile build and the web build.
class Business {
  const Business({
    required this.businessId,
    required this.name,
    required this.createdAt,
    this.address,
    this.phone,
    this.businessType,
    this.description,
  });

  final String businessId;

  final String name;

  final DateTime createdAt;

  final String? address;

  final String? phone;

  final String? businessType;

  final String? description;

  /// Builds a [Business] from a Supabase row (snake_case keys).
  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      businessType: json['business_type'] as String?,
      description: json['description'] as String?,
    );
  }
}