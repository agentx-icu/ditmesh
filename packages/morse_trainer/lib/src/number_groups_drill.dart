import 'dart:math';

import 'drill.dart';
import 'morse_text.dart';
import 'random_groups_drill.dart';

/// Groups of digits only - the traffic / contest number drill.
///
/// Digits are restricted to [allowedChars] (when given) so the drill stays
/// inside the current Koch lesson; it needs at least two digits to be worth
/// drilling, see [canGenerate].
final class NumberGroupsDrill implements DrillGenerator {
  NumberGroupsDrill({
    this.groupCount = 1,
    this.groupSize = 5,
    Set<String>? allowedChars,
  }) : assert(groupCount > 0, 'groupCount must be positive'),
       assert(groupSize > 0, 'groupSize must be positive'),
       digits = List<String>.unmodifiable(
         allDigits.where(
           (d) =>
               allowedChars == null ||
               allowedChars.map(MorseText.normalizeChar).contains(d),
         ),
       );

  static const List<String> allDigits = <String>[
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', //
  ];

  final int groupCount;
  final int groupSize;

  /// Digits the groups draw from, in numeric order.
  final List<String> digits;

  @override
  String get kind => 'numbers';

  /// False when fewer than two digits are allowed.
  bool get canGenerate => digits.length >= 2;

  @override
  Drill generate(Random random) {
    if (!canGenerate) {
      throw StateError('NumberGroupsDrill needs at least two allowed digits');
    }
    final groups = RandomGroupsDrill(
      chars: digits,
      groupCount: groupCount,
      groupSize: groupSize,
    ).generate(random);
    return Drill.fromText(groups.text, kind: kind);
  }
}
