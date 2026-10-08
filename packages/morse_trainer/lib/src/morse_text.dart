/// Tokenisation shared by every drill, scorer and scheduler in this package.
///
/// A "character" in trainer terms is one Morse symbol: a single letter, digit
/// or punctuation mark, **or** a bracketed prosign such as `<BT>` which is one
/// symbol even though it spells as four code units. Every API in this package
/// that talks about "chars" means tokens as produced by [MorseText.tokenize].
abstract final class MorseText {
  /// Token used for a word boundary when `keepSpaces` is true.
  static const String space = ' ';

  /// Splits [text] into symbol tokens.
  ///
  /// * Letters are upper-cased.
  /// * `<XX>` runs are kept as one token (upper-cased, brackets retained).
  /// * Whitespace runs collapse to a single [space] token when [keepSpaces] is
  ///   true and are dropped entirely otherwise. Leading/trailing whitespace
  ///   never produces a token.
  static List<String> tokenize(String text, {bool keepSpaces = true}) {
    final tokens = <String>[];
    var pendingSpace = false;
    var i = 0;
    while (i < text.length) {
      final ch = text[i];
      if (_isWhitespace(ch)) {
        pendingSpace = tokens.isNotEmpty;
        i++;
        continue;
      }
      if (pendingSpace && keepSpaces) {
        tokens.add(space);
      }
      pendingSpace = false;
      if (ch == '<') {
        final close = text.indexOf('>', i + 1);
        if (close > i + 1 && !text.substring(i + 1, close).contains(' ')) {
          tokens.add(text.substring(i, close + 1).toUpperCase());
          i = close + 1;
          continue;
        }
      }
      tokens.add(ch.toUpperCase());
      i++;
    }
    return tokens;
  }

  /// Symbol tokens of [text] with word boundaries removed.
  static List<String> symbols(String text) => tokenize(text, keepSpaces: false);

  /// Distinct symbols used by [text] (no spaces).
  static Set<String> charSet(String text) => symbols(text).toSet();

  /// Whether every symbol of [text] is contained in [allowed].
  static bool usesOnly(String text, Set<String> allowed) =>
      symbols(text).every(allowed.contains);

  /// Normalises a single symbol the same way [tokenize] does.
  static String normalizeChar(String char) => char.trim().toUpperCase();

  static bool _isWhitespace(String ch) =>
      ch == ' ' || ch == '\n' || ch == '\t' || ch == '\r';
}
