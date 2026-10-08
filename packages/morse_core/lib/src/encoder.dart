import 'alphabet.dart';
import 'element.dart';
import 'timing.dart';

/// Text -> Morse pattern string and text -> playable timeline.
abstract final class MorseEncoder {
  /// `"SOS"` -> `"... --- ..."`; words separated by ` / `.
  ///
  /// Unsupported characters are skipped (or mapped via [onUnsupported] when
  /// provided). `<AR>`-style prosigns in the input are honoured.
  ///
  /// [onUnsupported] receives the offending character and returns replacement
  /// text, which is encoded in its place (it may itself contain several
  /// characters or a bracketed prosign). Returning `''` skips the character.
  /// Characters that are still unsupported after replacement are dropped.
  static String toPattern(
    String text, {
    String Function(String char)? onUnsupported,
  }) {
    final List<List<String>> words = _tokenize(text, onUnsupported);
    return words.map((List<String> w) => w.join(' ')).join(' / ');
  }

  /// Full on/off timeline for [text] at [timing].
  ///
  /// The timeline never starts or ends with a gap. Consecutive gaps are
  /// merged (a word gap replaces, not adds to, the preceding char gap).
  /// Prosigns are keyed as one run of elements with only intra-character gaps
  /// inside.
  static List<MorseElement> encode(String text, MorseTiming timing) {
    final List<List<String>> words = _tokenize(text, null);
    final List<MorseElement> out = <MorseElement>[];
    final MorseElement dit = MorseElement(MorseElementKind.dit, timing.dit);
    final MorseElement dah = MorseElement(MorseElementKind.dah, timing.dah);
    final MorseElement intra =
        MorseElement(MorseElementKind.intraGap, timing.intraGap);
    final MorseElement charGap =
        MorseElement(MorseElementKind.charGap, timing.charGap);
    final MorseElement wordGap =
        MorseElement(MorseElementKind.wordGap, timing.wordGap);

    for (int w = 0; w < words.length; w++) {
      if (w > 0) out.add(wordGap);
      final List<String> patterns = words[w];
      for (int c = 0; c < patterns.length; c++) {
        if (c > 0) out.add(charGap);
        final String pattern = patterns[c];
        for (int i = 0; i < pattern.length; i++) {
          if (i > 0) out.add(intra);
          out.add(pattern[i] == '-' ? dah : dit);
        }
      }
    }
    return out;
  }

  /// Total wall-clock length of a timeline.
  static Duration totalDuration(Iterable<MorseElement> elements) {
    int us = 0;
    for (final MorseElement e in elements) {
      us += e.duration.inMicroseconds;
    }
    return Duration(microseconds: us);
  }

  /// Split [text] into words (runs separated by whitespace), each word being
  /// the list of patterns for its characters / prosigns. Empty words (from
  /// repeated whitespace or all-unsupported runs) are dropped, so the output
  /// never contains an empty inner list.
  static List<List<String>> _tokenize(
    String text,
    String Function(String char)? onUnsupported,
  ) {
    final List<String> chars =
        text.runes.map<String>(String.fromCharCode).toList(growable: false);
    final List<List<String>> words = <List<String>>[];
    List<String> current = <String>[];

    void endWord() {
      if (current.isNotEmpty) {
        words.add(current);
        current = <String>[];
      }
    }

    int i = 0;
    while (i < chars.length) {
      final String ch = chars[i];
      if (ch.trim().isEmpty) {
        endWord();
        i++;
        continue;
      }
      if (ch == '<') {
        final int close = chars.indexOf('>', i + 1);
        if (close > i) {
          final String name = chars.sublist(i + 1, close).join();
          final String? prosign = MorseAlphabet.encodeProsign(name);
          if (prosign != null) {
            current.add(prosign);
            i = close + 1;
            continue;
          }
        }
      }
      final String? pattern = MorseAlphabet.encodeChar(ch);
      if (pattern != null) {
        current.add(pattern);
      } else if (onUnsupported != null) {
        final String replacement = onUnsupported(ch);
        if (replacement.isNotEmpty) {
          // Re-encode the replacement without the callback so a mapping that
          // returns another unsupported character cannot recurse forever.
          for (final List<String> word in _tokenize(replacement, null)) {
            current.addAll(word);
          }
        }
      }
      i++;
    }
    endWord();
    return words;
  }
}
