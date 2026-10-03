/// One weight sample: a hand-picked sample of birds weighed together.
///
/// This is the standard shape of a weight sample inside the app. Both
/// the local (Drift) and remote (Supabase) repositories return this
/// class, so nothing above them needs to know where the data came from.
///
/// This file imports nothing on purpose. It must stay safe to compile in
/// both the mobile build and the web build.
class WeightSample {
  const WeightSample({
    required this.weightSampleId,
    required this.batchId,
    required this.recordedBy,
    required this.date,
    required this.sampleWeight,
    required this.sampleCount,
    required this.recordedAt,
  });

  /// Unique id, generated on the device when the sample is created.
  final String weightSampleId;

  /// The batch this sample was taken from.
  final String batchId;

  /// The account (Staff) that recorded this sample.
  final String recordedBy;

  /// The day the sample was taken.
  final DateTime date;

  /// Total weight of the sampled birds. Always greater than zero.
  final double sampleWeight;

  /// How many birds were weighed together. Always greater than zero.
  final int sampleCount;

  /// When the entry was typed in, which can be earlier than when it synced.
  final DateTime recordedAt;

  /// Builds a [WeightSample] from a Supabase row (snake_case keys).
  factory WeightSample.fromJson(Map<String, dynamic> json) {
    return WeightSample(
      weightSampleId: json['weight_sample_id'] as String,
      batchId: json['batch_id'] as String,
      recordedBy: json['recorded_by'] as String,
      date: DateTime.parse(json['date'] as String),
      sampleWeight: (json['sample_weight'] as num).toDouble(),
      sampleCount: json['sample_count'] as int,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }
}
