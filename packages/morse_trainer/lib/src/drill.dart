import 'dart:math';

import 'morse_text.dart';

/// One piece of practice text to be sent to the trainee.
final class Drill {
  Drill({required this.text, required Set<String> chars, this.kind})
    : chars = Set<String>.unmodifiable(chars);

  /// Builds a drill whose [chars] are the distinct symbols of [text].
  factory Drill.fromText(String text, {String? kind}) =>
      Drill(text: text, chars: MorseText.charSet(text), kind: kind);

  /// The text to play, words separated by single spaces.
  final String text;

  /// Distinct symbols that appear in [text] (never contains a space).
  final Set<String> chars;

  /// Generator label such as `groups`, `words`, `callsigns`, `qso`.
  final String? kind;

  /// Symbol tokens of [text] including word-boundary spaces.
  List<String> get tokens => MorseText.tokenize(text);

  /// Number of scoreable symbols (spaces excluded).
  int get charCount => MorseText.symbols(text).length;

  bool get isEmpty => charCount == 0;

  Map<String, Object?> toJson() => <String, Object?>{
    'text': text,
    'chars': chars.toList()..sort(),
    'kind': kind,
  };

  factory Drill.fromJson(Map<String, Object?> json) => Drill(
    text: json['text'] as String,
    chars: (json['chars'] as List<Object?>).cast<String>().toSet(),
    kind: json['kind'] as String?,
  );

  @override
  String toString() => 'Drill(${kind ?? 'drill'}: "$text")';
}

/// Produces [Drill]s. Implementations must be deterministic for a given
/// [Random] so sessions can be replayed from a seed.
abstract interface class DrillGenerator {
  /// Short stable identifier, also used for [Drill.kind].
  String get kind;

  Drill generate(Random random);
}
