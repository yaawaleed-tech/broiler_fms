/// Who is allowed to record an entry (mortality, feed, harvest, weight,
/// vaccination) against a batch.
///
/// A batch with a Staff member assigned to it is that person's to
/// record entries for: a Manager loses the entry actions as soon as an
/// assignment exists, so two people are never writing the same batch's
/// data at once.
///
/// A pure function on purpose, same reasoning as bird_count_rule.dart:
/// it decides, it never fetches anything itself. The caller already has
/// the signed-in [role] and the batch's [assignedStaffId] in hand by
/// the time this runs.
///
/// An unassigned batch ([assignedStaffId] null) stays open to the
/// Manager, which is the normal state between creating a batch and
/// assigning someone to run it.
bool canRecordEntryForBatch({
  required String role,
  required String? assignedStaffId,
}) {
  if (role != 'manager') return true;
  return assignedStaffId == null;
}
