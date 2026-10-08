import 'telegraph_table.g.dart';

/// Which of the two codebooks a code is looked up in. The mainland (1983)
/// and Taiwan / Hong Kong books agree on most characters; 419 differ.
enum TelegraphCodebook { mainland, taiwan }

/// One input character with the code it maps to, or null when the codebook
/// has no entry for it (Latin letters, punctuation, rare characters).
class TelegraphUnit {
  const TelegraphUnit(this.char, this.code);

  final String char;

  /// Four digits, zero-padded (`'0022'`), or null.
  final String? code;

  bool get hasCode => code != null;

  @override
  String toString() => code == null ? char : '$char($code)';
}

/// Chinese telegraph code (中文电码): each Chinese character is a four-digit
/// group, sent in Morse as digits. Tables come from the Unicode Unihan
/// database (`tool/gen_telegraph_table.dart`).
abstract final class ChineseTelegraphCode {
  /// Unihan version behind the tables.
  static String get unicodeVersion => telegraphTableUnicodeVersion;

  static Map<String, int> _table(TelegraphCodebook book) => switch (book) {
        TelegraphCodebook.mainland => mainlandTelegraphCodes,
        TelegraphCodebook.taiwan => taiwanTelegraphCodes,
      };

  static final Map<TelegraphCodebook, Map<int, List<String>>> _reverse = {};

  static Map<int, String> _aliases(TelegraphCodebook book) => switch (book) {
        TelegraphCodebook.mainland => mainlandTelegraphAliases,
        TelegraphCodebook.taiwan => taiwanTelegraphAliases,
      };

  static Map<int, List<String>> _byCode(TelegraphCodebook book) =>
      _reverse.putIfAbsent(book, () {
        final map = <int, List<String>>{};
        _table(book).forEach((char, code) {
          map.putIfAbsent(code, () => <String>[]).add(char);
        });
        // A character's secondary codes decode to it as well.
        _aliases(book).forEach((code, char) {
          map.putIfAbsent(code, () => <String>[]).add(char);
        });
        return map;
      });

  /// Zero-padded four-digit text for [code].
  static String format(int code) => code.toString().padLeft(4, '0');

  /// The code of one character, or null.
  static String? codeOf(
    String char, {
    TelegraphCodebook codebook = TelegraphCodebook.mainland,
  }) {
    final code = _table(codebook)[char];
    return code == null ? null : format(code);
  }

  /// Every character the codebook assigns to [code] (simplified and
  /// traditional forms share a code), sorted by code point; empty when the
  /// code is unassigned or [code] is not four digits.
  static List<String> charsOf(
    String code, {
    TelegraphCodebook codebook = TelegraphCodebook.mainland,
  }) {
    if (!RegExp(r'^\d{4}$').hasMatch(code)) return const [];
    return List.unmodifiable(_byCode(codebook)[int.parse(code)] ?? const []);
  }

  /// Maps every character of [text] to its unit. Whitespace and characters
  /// outside the codebook come back with a null code so the caller decides
  /// how to show them.
  static List<TelegraphUnit> encode(
    String text, {
    TelegraphCodebook codebook = TelegraphCodebook.mainland,
  }) {
    final table = _table(codebook);
    return [
      for (final rune in text.runes)
        _unit(String.fromCharCode(rune), table),
    ];
  }

  static TelegraphUnit _unit(String char, Map<String, int> table) {
    final code = table[char];
    return TelegraphUnit(char, code == null ? null : format(code));
  }

  /// Whether [text] contains at least one character the codebook knows.
  static bool containsCodedChars(
    String text, {
    TelegraphCodebook codebook = TelegraphCodebook.mainland,
  }) {
    final table = _table(codebook);
    for (final rune in text.runes) {
      if (table.containsKey(String.fromCharCode(rune))) return true;
    }
    return false;
  }

  /// Rewrites [text] for Morse: every coded character becomes its four
  /// digits, separated from its neighbours by one space (so each group is a
  /// "word" on the key); everything else is kept as is.
  static String transliterate(
    String text, {
    TelegraphCodebook codebook = TelegraphCodebook.mainland,
  }) {
    final out = StringBuffer();
    var lastWasCode = false;
    for (final unit in encode(text, codebook: codebook)) {
      final code = unit.code;
      if (code != null) {
        if (out.isNotEmpty && !_endsWithSpace(out)) out.write(' ');
        out.write(code);
        lastWasCode = true;
      } else {
        if (lastWasCode && unit.char.trim().isNotEmpty) out.write(' ');
        out.write(unit.char);
        lastWasCode = false;
      }
    }
    return out.toString();
  }

  static bool _endsWithSpace(StringBuffer b) {
    final s = b.toString();
    return s.isEmpty || s.codeUnitAt(s.length - 1) == 0x20;
  }

  /// Decodes four-digit groups (any non-digit separates groups; a run of
  /// digits is split every four) into characters. An unassigned group is
  /// rendered as [unknown]; when a code has several characters the first by
  /// code point is used (see [charsOf] for the full list).
  static String decode(
    String digits, {
    TelegraphCodebook codebook = TelegraphCodebook.mainland,
    String unknown = '□',
  }) {
    final byCode = _byCode(codebook);
    final out = StringBuffer();
    for (final run in RegExp(r'\d+').allMatches(digits)) {
      final s = run.group(0)!;
      for (var i = 0; i + 4 <= s.length; i += 4) {
        final chars = byCode[int.parse(s.substring(i, i + 4))];
        out.write(chars == null || chars.isEmpty ? unknown : chars.first);
      }
    }
    return out.toString();
  }
}
