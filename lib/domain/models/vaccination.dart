/// One vaccination entry: a vaccine given to a batch on a given day.
///
/// This is the standard shape of a vaccination entry inside the app.
/// Both the local (Drift) and remote (Supabase) repositories return this
/// class, so nothing above them needs to know where the data came from.
///
/// This file imports nothing on purpose. It must stay safe to compile in
/// both the mobile build and the web build.
class Vaccination {
  const Vaccination({
    required this.vaccinationId,
    required this.batchId,
    required this.recordedBy,
    required this.date,
    required this.vaccineName,
    required this.recordedAt,
  });

  /// Unique id, generated on the device when the entry is created.
  final String vaccinationId;

  /// The batch this vaccine was given to.
  final String batchId;

  /// The account (Staff) that recorded this entry.
  final String recordedBy;

  /// The day the vaccine was given.
  final DateTime date;

  /// Name of the vaccine given.
  final String vaccineName;

  /// When the entry was typed in, which can be earlier than when it synced.
  final DateTime recordedAt;

  /// Builds a [Vaccination] from a Supabase row (snake_case keys).
  factory Vaccination.fromJson(Map<String, dynamic> json) {
    return Vaccination(
      vaccinationId: json['vaccination_id'] as String,
      batchId: json['batch_id'] as String,
      recordedBy: json['recorded_by'] as String,
      date: DateTime.parse(json['date'] as String),
      vaccineName: json['vaccine_name'] as String,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }
}
