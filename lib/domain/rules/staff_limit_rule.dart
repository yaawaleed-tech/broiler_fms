/// A business may have at most this many active or pending Staff
/// accounts at once. Mirrors the limit enforced in the Admin web app.
const maxStaffPerBusiness = 18;

/// Checks whether one more Staff account can be added, given how many
/// active or pending Staff accounts already exist.
///
/// A pure function on purpose, same reasoning as every other rule in
/// this folder: it decides, it never fetches anything itself. The
/// caller (RemoteAccountDomain) counts the current active/pending
/// Staff first, then calls this before creating a new one.
bool canAddMoreStaff(int activeAndPendingStaffCount) {
  return activeAndPendingStaffCount < maxStaffPerBusiness;
}