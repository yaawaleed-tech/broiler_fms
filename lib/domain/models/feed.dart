/// One feed entry: feed given to a batch on a given day.
///
/// This is the standard shape of a feed entry inside the app. Both the
/// local (Drift) and remote (Supabase) repositories return this class,
/// so nothing above them needs to know where the data came from.
///
/// This file imports nothing on purpose. It must stay safe to compile in
/// both the mobile build and the web build.
class Feed {
  const Feed({
    required this.feedEntryId,
    required this.batchId,
    required this.recordedBy,
    required this.date,
    required this.quantity,
    required this.recordedAt,
  });

  /// Unique id, generated on the device when the entry is created.
  final String feedEntryId;

  /// The batch this feed was given to.
  final String batchId;

  /// The account (Staff) that recorded this entry.
  final String recordedBy;

  /// The day the feed was given.
  final DateTime date;

  /// How much feed was given. Always greater than zero.
  final double quantity;

  /// When the entry was typed in, which can be earlier than when it synced.
  final DateTime recordedAt;

  /// Builds a [Feed] from a Supabase row (snake_case keys).
  factory Feed.fromJson(Map<String, dynamic> json) {
    return Feed(
      feedEntryId: json['feed_entry_id'] as String,
      batchId: json['batch_id'] as String,
      recordedBy: json['recorded_by'] as String,
      date: DateTime.parse(json['date'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }
}
