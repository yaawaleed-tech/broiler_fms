import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Thousands grouping for whole-number inputs, e.g. 1600 -> "1,600".
final _groupFormat = NumberFormat('#,###');

/// Formats a whole-naira / whole-bird input with thousands separators
/// while the user types: "1600" becomes "1,600".
///
/// Digits only, no decimals. Leading zeros are stripped ("007" ->
/// "7"), and a lone "0" is rejected outright so zero is never an
/// accepted value. The cursor keeps its place relative to the digits
/// around it instead of jumping to the end: the count of digits after
/// the old cursor is measured, then the new cursor is put back so the
/// same number of digits sit after it.
class WholeNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final stripped = digitsOnly.replaceFirst(RegExp(r'^0+'), '');
    if (stripped.isEmpty) {
      // A lone "0" (or only zeros): reject the change entirely.
      return oldValue;
    }
    final formatted = _groupFormat.format(int.parse(stripped));

    // Digits after the old cursor, counted on digit characters only so
    // commas never shift the anchor.
    var digitsAfterCursor = 0;
    final cursor = newValue.selection.end;
    if (cursor >= 0) {
      for (var i = cursor; i < newValue.text.length; i++) {
        if (RegExp(r'[0-9]').hasMatch(newValue.text[i])) digitsAfterCursor++;
      }
    }
    // Clamp: typed digits can exceed kept digits when zeros collapse.
    final keptDigits = stripped.length;
    if (digitsAfterCursor > keptDigits) {
      digitsAfterCursor = keptDigits;
    }
    var newOffset = formatted.length;
    var seen = 0;
    for (var i = formatted.length - 1; i >= 0; i--) {
      if (RegExp(r'[0-9]').hasMatch(formatted[i])) {
        seen++;
        if (seen == digitsAfterCursor) {
          newOffset = i;
          break;
        }
      }
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}

/// Parses a formatted whole-number field back to an int, or null when
/// the field is empty. Never throws: anything unparseable is null.
int? parseWholeNumber(String text) {
  final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.isEmpty) return null;
  return int.tryParse(digitsOnly);
}

/// Formats an int with thousands separators, e.g. 1600 -> "1,600".
/// For writing programmatic values back into a formatted field.
String formatWholeNumber(int value) => _groupFormat.format(value);
