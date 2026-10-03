/// One harvest entry: birds taken out of a batch on a given day.
///
/// This is the standard shape of a harvest inside the app. Both the local
/// (Drift) and remote (Supabase) repositories return this class, so nothing
/// above them needs to know where the data came from.
///
/// This file imports nothing on purpose. It must stay safe to compile in
/// both the mobile build and the web build.
class Harvest {
  const Harvest({
    required this.harvestId,
    required this.batchId,
    required this.recordedBy,
    required this.date,
    required this.birdCount,
    required this.recordedAt,
  });

  /// Unique id, generated on the device when the entry is created.
  final String harvestId;

  /// The batch the birds were taken from.
  final String batchId;

  /// The account (Staff) that recorded this entry.
  final String recordedBy;

  /// The day the harvest happened.
  final DateTime date;

  /// How many birds were harvested. Always greater than zero.
  final int birdCount;

  /// When the entry was typed in, which can be earlier than when it synced.
  final DateTime recordedAt;

  /// Builds a [Harvest] from a Supabase row (snake_case keys).
  factory Harvest.fromJson(Map<String, dynamic> json) {
    return Harvest(
      harvestId: json['harvest_id'] as String,
      batchId: json['batch_id'] as String,
      recordedBy: json['recorded_by'] as String,
      date: DateTime.parse(json['date'] as String),
      birdCount: json['bird_count'] as int,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }
}