/// One batch of broilers, from registration to closing.
///
/// This is the standard shape of a batch inside the app. Both the local
/// (Drift) and remote (Supabase) repositories return this class, so nothing
/// above them needs to know where the data came from.
///
/// This file imports nothing on purpose. It must stay safe to compile in
/// both the mobile build and the web build.
class Batch {
  const Batch({
    required this.batchId,
    required this.businessId,
    required this.batchName,
    required this.startingBirdCount,
    required this.startDate,
    required this.isClosed,
    required this.createdAt,
    this.assignedStaffId,
    this.closedBy,
    this.breed,
    this.description,
    this.closedAt,
  });

  /// Unique id, generated on the device when the batch is created.
  final String batchId;

  /// The business this batch belongs to.
  final String businessId;

  final String batchName;

  /// How many birds the batch started with. Never changes after creation.
  final int startingBirdCount;

  final DateTime startDate;

  /// True once Manager has closed this batch. Locked for new entries then.
  final bool isClosed;

  final DateTime createdAt;

  /// The Staff account responsible for this batch. Null until Manager
  /// assigns someone.
  final String? assignedStaffId;

  /// The account that closed this batch. Null until it's actually closed.
  final String? closedBy;

  final String? breed;

  final String? description;

  /// When the batch was closed. Null until it's actually closed.
  final DateTime? closedAt;

  /// Builds a [Batch] from a Supabase row (snake_case keys).
  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      batchId: json['batch_id'] as String,
      businessId: json['business_id'] as String,
      batchName: json['batch_name'] as String,
      startingBirdCount: json['starting_bird_count'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      isClosed: json['is_closed'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      assignedStaffId: json['assigned_staff_id'] as String?,
      closedBy: json['closed_by'] as String?,
      breed: json['breed'] as String?,
      description: json['description'] as String?,
      closedAt: json['closed_at'] == null
          ? null
          : DateTime.parse(json['closed_at'] as String),
    );
  }
}