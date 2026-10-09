import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:morse_core/morse_core.dart';

/// A text-bound timeline. Recorded duration values replace generated spans
/// only when every keyed mark has a corresponding mark in the visible text.
class PlaybackTimeline {
  PlaybackTimeline(
    String text,
    MorseTiming timing, {
    KeyedRecording? recording,
    bool original = false,
  }) {
    var marks = 0;
    for (final entry in _wordPatterns(text)) {
      final word = entry.text;
      final patterns = entry.patterns;
      if (patterns.isEmpty) continue;
      if (words.isNotEmpty) {
        elements.add(MorseElement(MorseElementKind.wordGap, timing.wordGap));
      }
      _patterns.add(patterns.join(' '));
      words.add(word);
      wordStarts.add(elements.length);
      markStarts.add(marks);
      for (var c = 0; c < patterns.length; c++) {
        if (c > 0) {
          elements.add(MorseElement(MorseElementKind.charGap, timing.charGap));
        }
        final pattern = patterns[c];
        for (var i = 0; i < pattern.length; i++) {
          if (i > 0) {
            elements.add(
              MorseElement(MorseElementKind.intraGap, timing.intraGap),
            );
          }
          final dah = pattern[i] == '-';
          elements.add(
            MorseElement(
              dah ? MorseElementKind.dah : MorseElementKind.dit,
              dah ? timing.dah : timing.dit,
            ),
          );
          marks++;
        }
      }
    }
    isOriginal =
        original &&
        recording != null &&
        recording.durationsMs.length == elements.length;
    if (isOriginal) {
      for (var i = 0; i < elements.length; i++) {
        elements[i] = MorseElement(
          elements[i].kind,
          Duration(milliseconds: recording!.durationsMs[i]),
        );
      }
    }
  }

  /// Pattern-only rendering avoids allocating a whole audio timeline for
  /// every idle bubble on each progress tick.
  static String patternFor(String text) =>
      _wordPatterns(text).map((word) => word.patterns.join(' ')).join(' / ');
  static List<String> wordsFor(String text) =>
      _wordPatterns(text).map((word) => word.text).toList();

  static Iterable<({String text, List<String> patterns})> _wordPatterns(
    String text,
  ) sync* {
    for (final word in text.trim().split(RegExp(r'\s+'))) {
      final patterns = <String>[];
      for (final match in RegExp(r'<[^>]+>|.').allMatches(word)) {
        final token = match.group(0)!;
        String? pattern;
        if (token.startsWith('<') && token.endsWith('>')) {
          final name = token.substring(1, token.length - 1);
          pattern = RegExp(r'^[.-]+$').hasMatch(name)
              ? name
              : MorseAlphabet.encodeProsign(name);
        } else {
          pattern = MorseAlphabet.encodeChar(token);
        }
        if (pattern != null) patterns.add(pattern);
      }
      if (patterns.isNotEmpty) yield (text: word, patterns: patterns);
    }
  }

  final List<String> _patterns = [];
  String get pattern => _patterns.join(' / ');

  final List<MorseElement> elements = [];
  final List<String> words = [];
  final List<int> wordStarts = [];
  final List<int> markStarts = [];
  late final bool isOriginal;

  int wordAtElement(int index) {
    for (var w = wordStarts.length - 1; w >= 0; w--) {
      if (index >= wordStarts[w]) return w;
    }
    return 0;
  }

  List<MorseElement> range(int first, int last) {
    if (words.isEmpty) return const [];
    final start = first.clamp(0, words.length - 1);
    final end = last.clamp(start, words.length - 1);
    // Drop the gap preceding the following word, just like a full clip.
    final until = end + 1 < wordStarts.length
        ? wordStarts[end + 1] - 1
        : elements.length;
    return elements.sublist(wordStarts[start], until);
  }
}
