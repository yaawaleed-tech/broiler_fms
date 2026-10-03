/// One expense: money spent on a batch, chicks, feed, medication, or other.
///
/// This is the standard shape of an expense inside the app. Both the
/// local (Drift) and remote (Supabase) repositories return this class,
/// so nothing above them needs to know where the data came from.
///
/// Unlike the other entry types, this one is logged by Manager, not
/// Staff, and Staff has no visibility into it at all, by design.
///
/// This file imports nothing on purpose. It must stay safe to compile in
/// both the mobile build and the web build.
class Expense {
  const Expense({
    required this.expenseId,
    required this.batchId,
    required this.recordedBy,
    required this.category,
    required this.date,
    required this.amount,
    required this.recordedAt,
    this.quantity,
    this.unitPrice,
    this.feedType,
    this.medicationName,
    this.description,
  });

  /// Unique id, generated on the device when the expense is created.
  final String expenseId;

  /// The batch this expense belongs to.
  final String batchId;

  /// The account (Manager) that recorded this expense.
  final String recordedBy;

  /// One of 'chicks', 'feed', 'vet_medication', 'other'.
  final String category;

  /// The day the expense was incurred.
  final DateTime date;

  /// Total money spent. Always greater than zero.
  final double amount;

  /// When the entry was typed in, which can be earlier than when it synced.
  final DateTime recordedAt;

  /// How much was bought, if relevant (e.g. kg of feed). Optional.
  final double? quantity;

  /// Price for one unit of [quantity], if relevant. Optional.
  final double? unitPrice;

  /// Type of feed, only relevant when [category] is 'feed'. Optional.
  final String? feedType;

  /// Medication name, only relevant when [category] is 'vet_medication'.
  final String? medicationName;

  /// Free-text note. Optional.
  final String? description;

  /// Builds an [Expense] from a Supabase row (snake_case keys).
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      expenseId: json['expense_id'] as String,
      batchId: json['batch_id'] as String,
      recordedBy: json['recorded_by'] as String,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      quantity: (json['quantity'] as num?)?.toDouble(),
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      feedType: json['feed_type'] as String?,
      medicationName: json['medication_name'] as String?,
      description: json['description'] as String?,
    );
  }
}
