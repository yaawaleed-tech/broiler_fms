/// One mortality entry: birds that died in a batch on a given day.
///
/// This is the standard shape of a mortality entry inside the app. Both
/// the local (Drift) and remote (Supabase) repositories return this
/// class, so nothing above them needs to know where the data came from.
///
/// This file imports nothing on purpose. It must stay safe to compile in
/// both the mobile build and the web build.
class Mortality {
  const Mortality({
    required this.mortalityId,
    required this.batchId,
    required this.recordedBy,
    required this.date,
    required this.count,
    required this.recordedAt,
    this.description,
  });

  /// Unique id, generated on the device when the entry is created.
  final String mortalityId;

  /// The batch this death count belongs to.
  final String batchId;

  /// The account (Staff) that recorded this entry.
  final String recordedBy;

  /// The day the deaths happened.
  final DateTime date;

  /// How many birds died. Always at least 1; if none died, no entry is
  /// made at all, the absence of a row is what "zero" means.
  final int count;

  /// When the entry was typed in, which can be earlier than when it synced.
  final DateTime recordedAt;

  /// Optional note on why the birds died, if known.
  final String? description;

  /// Builds a [Mortality] from a Supabase row (snake_case keys).
  factory Mortality.fromJson(Map<String, dynamic> json) {
    return Mortality(
      mortalityId: json['mortality_id'] as String,
      batchId: json['batch_id'] as String,
      recordedBy: json['recorded_by'] as String,
      date: DateTime.parse(json['date'] as String),
      count: json['count'] as int,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      description: json['description'] as String?,
    );
  }
}
