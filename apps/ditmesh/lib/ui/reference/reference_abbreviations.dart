import 'package:flutter/widgets.dart' show Locale;
import 'package:morse_trainer/morse_trainer.dart';

import 'reference_localized_text.dart';

/// CW abbreviations with meanings.
///
/// The word list the trainer drills with (`WordLists.cwAbbreviations`) is
/// the backbone so the reference and the drills never disagree; this table
/// adds the meaning for each of those and a few more that are common on the
/// air. A test asserts every drilled abbreviation has a meaning here.
///
/// Meanings are given per language (see [kReferenceLanguages]).
abstract final class ReferenceAbbreviations {
  static final Map<String, Map<String, String>> meanings = referenceRows(
    (ReferenceText t) => t.abbreviations,
  );

  /// Display order: the trainer's list first (in its order), then the extra
  /// entries in table order, without duplicates.
  static List<String> get names {
    final List<String> out = <String>[];
    final Set<String> seen = <String>{};
    for (final String name in WordLists.cwAbbreviations) {
      if (seen.add(name)) out.add(name);
    }
    for (final String name in meanings.keys) {
      if (seen.add(name)) out.add(name);
    }
    return out;
  }

  /// Per-language meanings for [name]; empty when the table has none.
  static Map<String, String> meaningsOf(String name) =>
      meanings[name] ?? const <String, String>{};

  /// Meaning for [name] in [locale]'s language (English fallback), or an
  /// empty string when the table has none.
  static String meaningOf(String name, Locale locale) =>
      localizedReferenceText(meaningsOf(name), locale) ?? '';
}
