import 'dart:math';

import 'drill.dart';
import 'morse_text.dart';
import 'word_lists.dart';

/// Picks whole words (or CW abbreviations) that only use known symbols.
final class WordDrill implements DrillGenerator {
  /// [words] is filtered to entries whose every symbol is in [allowedChars];
  /// pass null to allow the full list.
  WordDrill({
    required Iterable<String> words,
    Set<String>? allowedChars,
    this.wordCount = 5,
    this.kind = 'words',
  }) : assert(wordCount > 0, 'wordCount must be positive'),
       allowedChars = allowedChars == null
           ? null
           : Set<String>.unmodifiable(
               allowedChars.map(MorseText.normalizeChar),
             ),
       candidates = List<String>.unmodifiable(
         filter(words, allowedChars?.map(MorseText.normalizeChar).toSet()),
       );

  /// Common English words filtered to [allowedChars].
  factory WordDrill.commonWords({
    Set<String>? allowedChars,
    int wordCount = 5,
  }) => WordDrill(
    words: WordLists.commonWords,
    allowedChars: allowedChars,
    wordCount: wordCount,
  );

  /// CW abbreviations (CQ, DE, 73 ...) filtered to [allowedChars].
  factory WordDrill.cwAbbreviations({
    Set<String>? allowedChars,
    int wordCount = 5,
  }) => WordDrill(
    words: WordLists.cwAbbreviations,
    allowedChars: allowedChars,
    wordCount: wordCount,
    kind: 'abbreviations',
  );

  /// On-air shorthand: CW abbreviations plus Q-codes, filtered to
  /// [allowedChars].
  factory WordDrill.radioShorthand({
    Set<String>? allowedChars,
    int wordCount = 5,
  }) => WordDrill(
    words: <String>[...WordLists.cwAbbreviations, ...WordLists.qCodes],
    allowedChars: allowedChars,
    wordCount: wordCount,
    kind: 'abbreviations',
  );

  /// Returns the upper-cased, de-duplicated entries of [words] whose symbols
  /// are all in [allowed] (everything when [allowed] is null). Blank entries
  /// are dropped.
  static List<String> filter(Iterable<String> words, Set<String>? allowed) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in words) {
      final word = raw.trim().toUpperCase();
      if (word.isEmpty || !seen.add(word)) {
        continue;
      }
      if (allowed == null || MorseText.usesOnly(word, allowed)) {
        out.add(word);
      }
    }
    return out;
  }

  /// Symbol set the words were filtered against (null = unfiltered).
  final Set<String>? allowedChars;

  /// Words that survived the filter.
  final List<String> candidates;

  final int wordCount;

  @override
  final String kind;

  /// False when the filter removed every word; [generate] would throw.
  bool get hasCandidates => candidates.isNotEmpty;

  /// Draws [wordCount] candidates with replacement, space separated.
  ///
  /// Throws [StateError] when there are no candidates - check
  /// [hasCandidates] first and fall back to a [RandomGroupsDrill].
  @override
  Drill generate(Random random) {
    if (!hasCandidates) {
      throw StateError('WordDrill has no words for the allowed symbol set');
    }
    final words = List<String>.generate(
      wordCount,
      (_) => candidates[random.nextInt(candidates.length)],
      growable: false,
    );
    return Drill.fromText(words.join(' '), kind: kind);
  }
}
