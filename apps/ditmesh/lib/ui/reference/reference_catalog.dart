import 'package:flutter/material.dart';
import 'package:morse_core/morse_core.dart';

import '../../i18n/l10n_extension.dart';
import 'morse_pattern_text.dart';
import 'reference_abbreviations.dart';
import 'reference_localized_text.dart';
import 'reference_mnemonics.dart';
import 'reference_qcodes.dart';

/// The sections of the reference, in display order.
enum ReferenceSection {
  alphabet(Icons.abc),
  punctuation(Icons.more_horiz),
  prosigns(Icons.code),
  qCodes(Icons.question_answer_outlined),
  abbreviations(Icons.short_text),
  koch(Icons.format_list_numbered);

  const ReferenceSection(this.icon);

  final IconData icon;

  /// Localised tab / rail title.
  String label(S s) => switch (this) {
    ReferenceSection.alphabet => s.referenceSectionAlphabet,
    ReferenceSection.punctuation => s.referenceSectionPunctuation,
    ReferenceSection.prosigns => s.referenceSectionProsigns,
    ReferenceSection.qCodes => s.referenceSectionQCodes,
    ReferenceSection.abbreviations => s.referenceSectionAbbreviations,
    ReferenceSection.koch => s.referenceSectionKoch,
  };
}

/// One playable row of the reference.
///
/// [meanings] and [mnemonics] are content, given per language code (see
/// [kReferenceLanguages]); [meaning] / [mnemonic] pick the text for a locale
/// with an English fallback.
final class ReferenceEntry {
  const ReferenceEntry({
    required this.section,
    required this.label,
    required this.pattern,
    required this.playText,
    this.meanings = const <String, String>{},
    this.mnemonics = const <String, String>{},
    this.position,
  });

  final ReferenceSection section;

  /// What the row is called: `A`, `<AR>`, `QRL`, `73`.
  final String label;

  /// `.`/`-` pattern, with character gaps as spaces for multi-character
  /// entries.
  final String pattern;

  /// Text handed to `MorseEncoder` to play this entry.
  final String playText;

  /// Meaning per language code; empty for entries without one (letters).
  final Map<String, String> meanings;

  /// Mnemonic line per language code; empty for entries without one.
  final Map<String, String> mnemonics;

  /// 1-based position for Koch-order entries.
  final int? position;

  /// Stable id used by the playback controller.
  String get id => '${section.name}:$label';

  bool get hasMnemonic => mnemonics.isNotEmpty;

  /// Meaning in [locale]'s language (English fallback), or null.
  String? meaning(Locale locale) => localizedReferenceText(meanings, locale);

  /// Mnemonic in [locale]'s language (English fallback), or null.
  String? mnemonic(Locale locale) => localizedReferenceText(mnemonics, locale);

  /// Case-insensitive match over label, every language's meaning and
  /// mnemonic, and the pattern in both raw and display forms.
  bool matches(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (label.toLowerCase().contains(q)) return true;
    if (pattern.contains(q) || displayMorsePattern(pattern).contains(q)) {
      return true;
    }
    bool hit(String text) => text.toLowerCase().contains(q);
    return meanings.values.any(hit) || mnemonics.values.any(hit);
  }
}

/// Builds and caches the entries of every section.
abstract final class ReferenceCatalog {
  static final RegExp _alnum = RegExp(r'^[A-Z0-9]$');

  static final Map<String, Map<String, String>> _prosignMeanings =
      referenceRows((ReferenceText t) => t.prosigns);

  static final Map<String, Map<String, String>> _punctuationNames =
      referenceRows((ReferenceText t) => t.punctuation);

  static final List<ReferenceEntry> alphabet = <ReferenceEntry>[
    for (final MapEntry<String, String> e
        in MorseAlphabet.international.entries)
      if (_alnum.hasMatch(e.key))
        ReferenceEntry(
          section: ReferenceSection.alphabet,
          label: e.key,
          pattern: e.value,
          playText: e.key,
          mnemonics: ReferenceMnemonics.linesForCharacter(e.key, e.value),
        ),
  ];

  static final List<ReferenceEntry> punctuation = <ReferenceEntry>[
    for (final MapEntry<String, String> e
        in MorseAlphabet.international.entries)
      if (!_alnum.hasMatch(e.key))
        ReferenceEntry(
          section: ReferenceSection.punctuation,
          label: e.key,
          pattern: e.value,
          playText: e.key,
          meanings: _punctuationNames[e.key] ?? const <String, String>{},
          mnemonics: ReferenceMnemonics.linesForCharacter(e.key, e.value),
        ),
  ];

  static final List<ReferenceEntry> prosigns = <ReferenceEntry>[
    for (final MapEntry<String, String> e in MorseAlphabet.prosigns.entries)
      ReferenceEntry(
        section: ReferenceSection.prosigns,
        label: '<${e.key}>',
        pattern: e.value,
        playText: '<${e.key}>',
        meanings: _prosignMeanings[e.key] ?? const <String, String>{},
        mnemonics: ReferenceMnemonics.rhythmLines('<${e.key}>', e.value),
      ),
  ];

  static final List<ReferenceEntry> qCodes = <ReferenceEntry>[
    for (final MapEntry<String, Map<String, String>> e
        in ReferenceQCodes.meanings.entries)
      ReferenceEntry(
        section: ReferenceSection.qCodes,
        label: e.key,
        pattern: MorseEncoder.toPattern(e.key),
        playText: e.key,
        meanings: e.value,
      ),
  ];

  static final List<ReferenceEntry> abbreviations = <ReferenceEntry>[
    for (final String name in ReferenceAbbreviations.names)
      ReferenceEntry(
        section: ReferenceSection.abbreviations,
        label: name,
        pattern: MorseEncoder.toPattern(name),
        playText: name,
        meanings: ReferenceAbbreviations.meaningsOf(name),
      ),
  ];

  static final List<ReferenceEntry> koch = <ReferenceEntry>[
    for (int i = 0; i < MorseAlphabet.kochOrder.length; i++)
      _kochEntry(i + 1, MorseAlphabet.kochOrder[i]),
  ];

  static ReferenceEntry _kochEntry(int position, String symbol) {
    final String pattern = MorseEncoder.toPattern(symbol);
    final bool isProsign = symbol.startsWith('<');
    return ReferenceEntry(
      section: ReferenceSection.koch,
      label: symbol,
      pattern: pattern,
      playText: symbol,
      position: position,
      meanings:
          (isProsign
              ? _prosignMeanings[symbol.substring(1, symbol.length - 1)]
              : _punctuationNames[symbol]) ??
          const <String, String>{},
      mnemonics: isProsign
          ? ReferenceMnemonics.rhythmLines(symbol, pattern)
          : ReferenceMnemonics.linesForCharacter(symbol, pattern),
    );
  }

  static List<ReferenceEntry> entriesFor(ReferenceSection section) =>
      switch (section) {
        ReferenceSection.alphabet => alphabet,
        ReferenceSection.punctuation => punctuation,
        ReferenceSection.prosigns => prosigns,
        ReferenceSection.qCodes => qCodes,
        ReferenceSection.abbreviations => abbreviations,
        ReferenceSection.koch => koch,
      };

  /// Every entry of every section, in display order.
  static List<ReferenceEntry> get all => <ReferenceEntry>[
    for (final ReferenceSection s in ReferenceSection.values) ...entriesFor(s),
  ];

  /// Entries matching [query], grouped by section; sections with no match
  /// are omitted. An empty query returns everything.
  static Map<ReferenceSection, List<ReferenceEntry>> search(String query) {
    final Map<ReferenceSection, List<ReferenceEntry>> out =
        <ReferenceSection, List<ReferenceEntry>>{};
    for (final ReferenceSection s in ReferenceSection.values) {
      final List<ReferenceEntry> hits = entriesFor(
        s,
      ).where((ReferenceEntry e) => e.matches(query)).toList(growable: false);
      if (hits.isNotEmpty) out[s] = hits;
    }
    return out;
  }
}
