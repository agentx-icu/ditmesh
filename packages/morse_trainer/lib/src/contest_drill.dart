import 'dart:math';

import 'callsign_drill.dart';
import 'drill.dart';
import 'morse_text.dart';

/// Contest exchanges: `<call> 599 <number>`, as heard in a pile-up.
///
/// The number is a serial of two or three digits (`07`, `124`). With
/// probability [cutNumberChance] the exchange uses cut numbers - `9` as `N`
/// and `0` as `T`, so `599 007` becomes `5NN TT7` - which is how contesters
/// actually send it. The trainee copies what is sent, letters included.
///
/// With [allowedChars] every symbol of every exchange is drawn from that set
/// (the callsign via [CallsignDrill], the report and the serial digit by
/// digit), so the answer keypad can always type it; [canGenerate] says
/// whether the set is rich enough at all.
final class ContestExchangeDrill implements DrillGenerator {
  ContestExchangeDrill({Set<String>? allowedChars, this.cutNumberChance = 0.5})
    : assert(
        cutNumberChance >= 0 && cutNumberChance <= 1,
        'cutNumberChance must be in [0, 1]',
      ),
      callsigns = CallsignDrill(count: 1, allowedChars: allowedChars),
      _plainDigits = _digits(allowedChars, cut: false),
      _cutDigits = _digits(allowedChars, cut: true);

  static const List<String> _allDigits = <String>[
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', //
  ];

  final CallsignDrill callsigns;

  /// Probability that one exchange is sent with cut numbers.
  final double cutNumberChance;

  /// Digits whose plain / cut spelling is allowed. A style is usable only
  /// when its report (`599` / `5NN`) is spellable, i.e. 5 and 9 are in it.
  final List<String> _plainDigits;
  final List<String> _cutDigits;

  @override
  String get kind => 'contest';

  bool get _plainUsable =>
      _plainDigits.contains('5') && _plainDigits.contains('9');
  bool get _cutUsable => _cutDigits.contains('5') && _cutDigits.contains('9');

  /// False when the allowed set cannot spell a callsign and a report.
  bool get canGenerate => callsigns.canGenerate && (_plainUsable || _cutUsable);

  /// Replaces `0` with `T` and `9` with `N` (the universal cut numbers).
  static String cut(String digits) =>
      digits.replaceAll('0', 'T').replaceAll('9', 'N');

  /// One exchange such as `DL1ABC 5NN T42` or `JA7XYZ 599 25`.
  String nextExchange(Random random) {
    if (!canGenerate) {
      throw StateError(
        'ContestExchangeDrill cannot build an exchange from the allowed symbols',
      );
    }
    final call = callsigns.nextCallsign(random);
    final wantCut = random.nextDouble() < cutNumberChance;
    final useCut = _cutUsable && (wantCut || !_plainUsable);
    final pool = useCut ? _cutDigits : _plainDigits;
    final length = random.nextBool() ? 3 : 2;
    var number = '';
    for (var i = 0; i < length; i++) {
      number += pool[random.nextInt(pool.length)];
    }
    final report = useCut ? cut('599') : '599';
    return '$call $report ${useCut ? cut(number) : number}';
  }

  @override
  Drill generate(Random random) =>
      Drill.fromText(nextExchange(random), kind: kind);

  static List<String> _digits(Set<String>? allowed, {required bool cut}) {
    if (allowed == null) return _allDigits;
    final normalised = allowed.map(MorseText.normalizeChar).toSet();
    return List<String>.unmodifiable(
      _allDigits.where(
        (d) => normalised.contains(cut ? ContestExchangeDrill.cut(d) : d),
      ),
    );
  }
}
