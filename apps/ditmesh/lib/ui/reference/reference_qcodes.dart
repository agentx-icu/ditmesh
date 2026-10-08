import 'package:flutter/widgets.dart' show Locale;

import 'reference_localized_text.dart';

/// Q-codes commonly heard on CW, with the meaning in the form that suits
/// both the question (with `?`) and the statement.
///
/// Meanings are given per language (see [kReferenceLanguages]); the code
/// itself is language-neutral.
abstract final class ReferenceQCodes {
  /// Insertion order is display order: the everyday set first, then the
  /// rest alphabetically.
  static final Map<String, Map<String, String>> meanings = referenceRows(
    (ReferenceText t) => t.qCodes,
  );

  static List<String> get codes => meanings.keys.toList(growable: false);

  /// Meaning of [code] in [locale]'s language (English fallback), or null
  /// for a code the table does not carry.
  static String? meaning(String code, Locale locale) {
    final Map<String, String>? row = meanings[code];
    return row == null ? null : localizedReferenceText(row, locale);
  }
}
