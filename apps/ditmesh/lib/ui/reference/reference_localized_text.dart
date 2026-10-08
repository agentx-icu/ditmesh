import 'package:flutter/widgets.dart' show Locale;

import '../../i18n/locale_resolution.dart';
import 'text/reference_texts.dart';

export 'text/reference_texts.dart'
    show ReferenceRhythm, ReferenceText, kReferenceTexts;

/// Reference *content* (Q-code meanings, CW abbreviations, prosign meanings,
/// mnemonics) is data, not UI chrome, so it does not live in the ARB files.
/// Each language is one `text/reference_text_<tag>.dart` file registered in
/// [kReferenceTexts]; the tables below are pivoted from those into one map
/// per row, keyed by language tag.
///
/// [kReferenceFallbackLanguage] is the language every row must have; the
/// lookup helpers fall back to it when a row lacks the requested language.
const String kReferenceFallbackLanguage = 'en';

/// Languages the reference content ships in (the [kReferenceTexts] keys,
/// English first). Derived mnemonic lines are generated for each of these.
final List<String> kReferenceLanguages = List<String>.unmodifiable(
  kReferenceTexts.keys,
);

/// The registered text a tag (`zh_Hant_TW`, `ja`, `it`) reads: the most
/// specific registered key ([referenceLanguageKeysForTag]), else English.
ReferenceText referenceTextFor(String tag) {
  for (final String key in referenceLanguageKeysForTag(tag)) {
    final ReferenceText? text = kReferenceTexts[key];
    if (text != null) return text;
  }
  return kReferenceTexts[kReferenceFallbackLanguage]!;
}

/// Pivots one table of every language into rows: row key (in English
/// order) -> language tag -> text. A language missing a row is simply
/// absent from that row's map, so lookups fall back to English.
Map<String, Map<String, String>> referenceRows(
  Map<String, String> Function(ReferenceText text) table,
) {
  final Map<String, String> english = table(
    kReferenceTexts[kReferenceFallbackLanguage]!,
  );
  return <String, Map<String, String>>{
    for (final String row in english.keys)
      row: <String, String>{
        for (final MapEntry<String, ReferenceText> language
            in kReferenceTexts.entries)
          if (table(language.value)[row] case final String text)
            language.key: text,
      },
  };
}

/// Lookup keys for [locale], most specific first:
/// `language_Script_REGION` → `language_Script` → `language_REGION` →
/// `language` → [kReferenceFallbackLanguage]. A `zh-Hant-TW` UI therefore
/// reads the `zh_Hant` text, and a region or script
/// variant nobody ships still reads its language before dropping to English. (Built here explicitly: `localeTag` keeps
/// only the script when both script and region are present.)
List<String> referenceLanguageKeys(Locale locale) {
  final String language = locale.languageCode;
  final String? script = _nonEmpty(locale.scriptCode);
  final String? region = _nonEmpty(locale.countryCode);
  final List<String> keys = <String>[
    if (script != null && region != null) '${language}_${script}_$region',
    if (script != null) '${language}_$script',
    if (region != null) '${language}_$region',
    language,
    kReferenceFallbackLanguage,
  ];
  return keys.toSet().toList(growable: false);
}

/// [referenceLanguageKeys] for a key that is already a tag (`zh_Hant`,
/// `zh-Hant-TW`, `en`), so data-layer callers can pass either form.
List<String> referenceLanguageKeysForTag(String tag) =>
    referenceLanguageKeys(parseLocaleTag(tag) ?? const Locale('en'));

/// The first of [referenceLanguageKeys] that [kReferenceLanguages] carries,
/// i.e. the table column a [locale] reads (`zh_Hant` for `zh_Hant_TW`, `en` for
/// an unknown language).
String referenceLanguageFor(Locale locale) =>
    referenceLanguageKeys(locale).firstWhere(
      kReferenceLanguages.contains,
      orElse: () => kReferenceFallbackLanguage,
    );

/// Picks the text of [byLanguage] for [locale] by [referenceLanguageKeys]
/// (script- and region-aware, English last). Null when the row has none.
String? localizedReferenceText(Map<String, String> byLanguage, Locale locale) {
  for (final String key in referenceLanguageKeys(locale)) {
    final String? text = byLanguage[key];
    if (text != null) return text;
  }
  return null;
}

/// Languages written with full-width punctuation.
const Set<String> _fullWidthColonLanguages = <String>{'zh', 'ja'};

/// Separator between a label and its explanation: `: ` in Latin-script
/// languages, the full-width colon in Chinese and Japanese. [language] is
/// any tag (`zh`, `zh_Hant`, `ja-JP`); only its language code decides.
String referenceLabelSeparator(String language) =>
    _fullWidthColonLanguages.contains(referenceLanguageCode(language))
    ? '：'
    : ': ';

/// The ISO language code of a tag such as `zh_Hant_TW` / `zh-Hant`.
String referenceLanguageCode(String tag) =>
    tag.trim().split(RegExp('[-_]')).first.toLowerCase();

String? _nonEmpty(String? value) =>
    value == null || value.isEmpty ? null : value;
