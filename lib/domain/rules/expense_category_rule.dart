/// Checks an expense's category is one of the values the database
/// allows, before the device ever writes it. Mirrors the CHECK
/// constraint on the expense table in schema.sql.
///
/// A pure function on purpose, same reasoning as every other rule in
/// this folder: it decides, it never fetches anything itself.
const _validCategories = ['chicks', 'feed', 'vet_medication', 'other'];

String? expenseCategoryError(String category) {
  if (!_validCategories.contains(category)) {
    return 'Choose a valid expense category.';
  }
  return null;
}