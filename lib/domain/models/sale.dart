/// The pricing record for a harvest: what happened to the birds and what
/// they earned.
///
/// This is the standard shape of a sale inside the app. Both the local
/// (Drift) and remote (Supabase) repositories return this class.
///
/// This file imports nothing on purpose. It must stay safe to compile in
/// both the mobile build and the web build.
class Sale {
  const Sale({
    required this.saleId,
    required this.harvestId,
    required this.recordedBy,
    required this.disposition,
    required this.amount,
    required this.createdAt,
    this.buyerName,
    this.pricingMethod,
    this.weightSold,
    this.pricePerUnit,
    this.paymentStatus,
  });

  /// Unique id, generated on the device when the sale is created.
  final String saleId;

  /// The harvest entry this sale prices.
  final String harvestId;

  /// The account (Manager) that recorded this sale.
  final String recordedBy;

  /// Either 'sale' or 'gift_cull'. A gift_cull carries an amount of 0 and
  /// none of the optional pricing fields below.
  final String disposition;

  /// Total money for the harvest. Greater than 0 for a sale, 0 for gift_cull.
  final double amount;

  /// When the sale record was created.
  final DateTime createdAt;

  /// Who bought the birds, or received them for a gift_cull. Optional.
  final String? buyerName;

  /// Either 'per_kg' or 'flat_total'. Only set for a sale.
  final String? pricingMethod;

  /// Kilograms sold. Only set when the pricing method is 'per_kg'.
  final double? weightSold;

  /// Price per kg (per_kg) or price per bird (flat_total, optional).
  final double? pricePerUnit;

  /// Either 'paid' or 'pending'. Only set for a sale.
  final String? paymentStatus;

  /// Builds a [Sale] from a Supabase row (snake_case keys).
  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      saleId: json['sale_id'] as String,
      harvestId: json['harvest_id'] as String,
      recordedBy: json['recorded_by'] as String,
      disposition: json['disposition'] as String,
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      buyerName: json['buyer_name'] as String?,
      pricingMethod: json['pricing_method'] as String?,
      weightSold: (json['weight_sold'] as num?)?.toDouble(),
      pricePerUnit: (json['price_per_unit'] as num?)?.toDouble(),
      paymentStatus: json['payment_status'] as String?,
    );
  }
}