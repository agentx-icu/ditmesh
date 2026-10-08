/// One language's reference *content*: Q-code and CW-abbreviation meanings,
/// prosign meanings, punctuation names, translated digit mnemonics and the
/// way operators voice dits and dahs.
///
/// Every language lives in its own `reference_text_<tag>.dart` file and is
/// registered in `reference_texts.dart`; the English file defines the rows
/// (and their display order) every other language must translate. A test
/// asserts each registered language carries exactly the English keys.
final class ReferenceText {
  const ReferenceText({
    required this.qCodes,
    required this.abbreviations,
    required this.prosigns,
    required this.punctuation,
    this.digitPhrases = const <String, String>{},
    this.phraseNote = '',
    this.rhythm = ReferenceRhythm.english,
  });

  /// Q-code -> meaning (`QRL` -> `Is the frequency in use? / …`).
  final Map<String, String> qCodes;

  /// CW abbreviation -> meaning (`73` -> `Best regards.`).
  final Map<String, String> abbreviations;

  /// Prosign without brackets -> meaning (`AR` -> `End of message.`).
  final Map<String, String> prosigns;

  /// Punctuation character -> its name (`.` -> `Period (full stop)`).
  final Map<String, String> punctuation;

  /// Digit -> translated memory phrase (`1` -> `one dit, then four dahs`).
  /// Empty for English, whose phrases live in `ReferenceMnemonics.phrases`.
  final Map<String, String> digitPhrases;

  /// Appended to an English phonetic letter phrase in this language, e.g.
  /// `（英文口诀中重读音节为划）`. Empty for English.
  final String phraseNote;

  /// How dits and dahs are voiced when a pattern is read aloud.
  final ReferenceRhythm rhythm;
}

/// Spoken form of a Morse pattern: `di-DAH` in English, `嘀嗒` in Chinese.
final class ReferenceRhythm {
  const ReferenceRhythm({
    required this.dit,
    required this.finalDit,
    required this.dah,
    required this.joiner,
  });

  /// A dit that is not the last element (`di`).
  final String dit;

  /// A dit that ends the pattern (`dit`).
  final String finalDit;

  /// A dah (`DAH`).
  final String dah;

  /// Placed between elements (`-`; empty in Chinese).
  final String joiner;

  /// `.-` -> `di-DAH`, `-...` -> `DAH-di-di-dit`.
  static const ReferenceRhythm english = ReferenceRhythm(
    dit: 'di',
    finalDit: 'dit',
    dah: 'DAH',
    joiner: '-',
  );

  /// Reads [pattern] (`.`/`-`, other characters ignored) aloud.
  String voice(String pattern) {
    final List<String> parts = <String>[];
    for (int i = 0; i < pattern.length; i++) {
      final String ch = pattern[i];
      if (ch == '-') {
        parts.add(dah);
      } else if (ch == '.') {
        parts.add(i == pattern.length - 1 ? finalDit : dit);
      }
    }
    return parts.join(joiner);
  }
}
