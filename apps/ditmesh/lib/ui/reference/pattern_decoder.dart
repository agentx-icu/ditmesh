import 'package:morse_core/morse_core.dart';

import 'morse_pattern_text.dart';

/// One decoded token of a typed Morse pattern.
final class DecodedToken {
  const DecodedToken({
    required this.pattern,
    required this.text,
    required this.known,
  });

  /// Normalised `.`/`-` pattern as typed.
  final String pattern;

  /// The character, `<PROSIGN>`, or `<pattern>` when nothing matches.
  final String text;

  /// False when [text] is the `<pattern>` fallback.
  final bool known;
}

/// Turns a hand-typed pattern (`.- -... / -.-.`) into text.
///
/// * `.` / `·` are dits, `-` / `−` / `_` are dahs.
/// * whitespace separates characters, `/` (or `|`) separates words.
/// * a token is looked up in the international table first, then as a
///   prosign (`<AR>`); otherwise it renders as `<pattern>` so the user can
///   see exactly what did not decode.
abstract final class PatternDecoder {
  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _wordBreak = RegExp(r'[/|]');

  /// Rewrites display glyphs and lookalikes into `.` and `-`.
  static String normalize(String input) {
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final String ch = input[i];
      switch (ch) {
        case kDitGlyph:
        case '•': // bullet
        case '*':
          out.write('.');
        case kDahGlyph:
        case '_':
        case '–': // en dash
        case '—': // em dash
          out.write('-');
        default:
          out.write(ch);
      }
    }
    return out.toString();
  }

  /// Decodes [input] word by word; words are joined with a single space.
  static String decode(String input) {
    final List<List<DecodedToken>> words = decodeWords(input);
    return words
        .map((List<DecodedToken> w) => w.map((DecodedToken t) => t.text).join())
        .join(' ');
  }

  /// Decodes [input] into words of tokens. Empty words (from a leading,
  /// trailing or doubled `/`) are dropped.
  static List<List<DecodedToken>> decodeWords(String input) {
    final String normalized = normalize(input);
    final List<List<DecodedToken>> words = <List<DecodedToken>>[];
    for (final String word in normalized.split(_wordBreak)) {
      final List<DecodedToken> tokens = <DecodedToken>[];
      for (final String raw in word.trim().split(_whitespace)) {
        if (raw.isEmpty) continue;
        tokens.add(decodeToken(raw));
      }
      if (tokens.isNotEmpty) words.add(tokens);
    }
    return words;
  }

  /// Decodes a single normalised token.
  static DecodedToken decodeToken(String pattern) {
    final String? char = MorseAlphabet.decodePattern(pattern);
    if (char != null) {
      return DecodedToken(pattern: pattern, text: char, known: true);
    }
    final String? prosign = MorseAlphabet.decodeProsignPattern(pattern);
    if (prosign != null) {
      return DecodedToken(pattern: pattern, text: '<$prosign>', known: true);
    }
    return DecodedToken(pattern: pattern, text: '<$pattern>', known: false);
  }

  /// True when at least one token of [input] did not decode.
  static bool hasUnknown(String input) => decodeWords(
    input,
  ).any((List<DecodedToken> w) => w.any((DecodedToken t) => !t.known));
}
