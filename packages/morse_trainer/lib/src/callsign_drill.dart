import 'dart:math';

import 'drill.dart';
import 'morse_text.dart';

/// Generates realistic amateur callsigns: `<prefix><digit><suffix>`.
///
/// When [allowedChars] is given, prefixes, digits and suffix letters are all
/// restricted to that set so the drill stays inside the current lesson.
final class CallsignDrill implements DrillGenerator {
  CallsignDrill({
    this.count = 5,
    Set<String>? allowedChars,
    List<String> prefixes = defaultPrefixes,
  }) : assert(count > 0, 'count must be positive'),
       allowedChars = allowedChars == null
           ? null
           : Set<String>.unmodifiable(
               allowedChars.map(MorseText.normalizeChar),
             ),
       _prefixes = _filter(prefixes, allowedChars),
       _digits = _filter(_allDigits, allowedChars),
       _letters = _filter(_allLetters, allowedChars);

  /// Common ITU prefixes without embedded digits.
  static const List<String> defaultPrefixes = <String>[
    'K',
    'W',
    'N',
    'AA',
    'AB',
    'AC',
    'AD',
    'AE',
    'AF',
    'AG',
    'AI',
    'AJ',
    'AK', //
    'KA', 'KB', 'KC', 'KD', 'KE', 'KF', 'KG', 'KI', 'KJ', 'KK', 'KM', 'KN', //
    'WA', 'WB', 'WD', 'WE', 'WM', 'WN', 'WX', 'NA', 'NC', 'ND', 'NE', 'NN', //
    'VE', 'VA', 'XE', 'CE', 'LU', 'PY', 'PU', 'YV', 'HK', 'OA', 'CX', //
    'G', 'M', 'GM', 'GW', 'GI', 'EI', 'F', 'DL', 'DJ', 'DK', 'DF', 'DG', //
    'I', 'IK', 'IZ', 'IW', 'EA', 'EB', 'EC', 'CT', 'PA', 'PD', 'PE', 'ON', //
    'OE', 'OK', 'OM', 'OZ', 'SM', 'SA', 'SP', 'SQ', 'LA', 'LB', 'OH', 'ES', //
    'YL', 'LY', 'HA', 'YO', 'LZ', 'SV', 'TA', 'UA', 'RA', 'UR', 'UT', 'UN', //
    'JA', 'JH', 'JR', 'JE', 'JF', 'JG', 'JI', 'JK', 'JL', 'JM', 'JO', 'JP', //
    'HL', 'DS', 'BA', 'BD', 'BG', 'BH', 'BV', 'VR', 'VU', 'DU', 'YB', 'YC', //
    'VK', 'ZL', 'ZS', 'ZR', 'SU', 'CN', 'EL', 'TR', 'TU', 'FR', 'FY', 'KH', //
    'KL', 'KP', 'VP', 'ZF', 'PJ', 'TI', 'HP', 'HC', 'HI', 'CO', 'CM', 'XX',
  ];

  static const List<String> _allDigits = <String>[
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];

  static const List<String> _allLetters = <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  static List<String> _filter(Iterable<String> items, Set<String>? allowed) {
    final normalisedAllowed = allowed?.map(MorseText.normalizeChar).toSet();
    return List<String>.unmodifiable(
      items
          .map((s) => s.toUpperCase())
          .where(
            (s) =>
                normalisedAllowed == null ||
                MorseText.usesOnly(s, normalisedAllowed),
          ),
    );
  }

  /// Callsigns per drill.
  final int count;

  /// Symbol set the callsigns were restricted to (null = unrestricted).
  final Set<String>? allowedChars;

  final List<String> _prefixes;
  final List<String> _digits;
  final List<String> _letters;

  /// Prefixes usable under [allowedChars].
  List<String> get prefixes => _prefixes;

  @override
  String get kind => 'callsigns';

  /// False when [allowedChars] leaves no prefix, digit or suffix letter.
  bool get canGenerate =>
      _prefixes.isNotEmpty && _digits.isNotEmpty && _letters.isNotEmpty;

  /// One callsign. Suffix length: 1 letter 10 %, 2 letters 35 %, 3 letters
  /// 55 % - roughly the real-world distribution.
  String nextCallsign(Random random) {
    if (!canGenerate) {
      throw StateError(
        'CallsignDrill cannot build a callsign from the allowed symbols',
      );
    }
    final prefix = _prefixes[random.nextInt(_prefixes.length)];
    final digit = _digits[random.nextInt(_digits.length)];
    final roll = random.nextDouble();
    final suffixLength = roll < 0.10 ? 1 : (roll < 0.45 ? 2 : 3);
    final suffix = StringBuffer();
    for (var i = 0; i < suffixLength; i++) {
      suffix.write(_letters[random.nextInt(_letters.length)]);
    }
    return '$prefix$digit$suffix';
  }

  @override
  Drill generate(Random random) {
    final calls = List<String>.generate(
      count,
      (_) => nextCallsign(random),
      growable: false,
    );
    return Drill.fromText(calls.join(' '), kind: kind);
  }
}
