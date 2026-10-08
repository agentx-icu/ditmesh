/// PARIS-standard timing with optional Farnsworth spacing.
///
/// `dit = 1200 / wpm` milliseconds. dah = 3 dit, intra-character gap = 1 dit,
/// character gap = 3 dit, word gap = 7 dit.
///
/// Farnsworth: characters are keyed at [wpm] but the character and word gaps
/// are stretched so the overall throughput equals [farnsworthWpm]
/// (ARRL formula). When [farnsworthWpm] is null or >= [wpm], standard
/// spacing applies.
final class MorseTiming {
  const MorseTiming({required this.wpm, this.farnsworthWpm})
      : assert(wpm > 0, 'wpm must be positive'),
        assert(farnsworthWpm == null || farnsworthWpm > 0,
            'farnsworthWpm must be positive');

  /// Character (element) speed in words per minute.
  final double wpm;

  /// Effective overall speed when Farnsworth spacing is in use.
  final double? farnsworthWpm;

  /// Standard 20 WPM character speed used by the Koch method.
  static const MorseTiming koch20 = MorseTiming(wpm: 20);

  /// Whether Farnsworth stretching is active.
  bool get isFarnsworth => farnsworthWpm != null && farnsworthWpm! < wpm;

  /// One dit in milliseconds (fractional; callers round when they need ints).
  double get ditMs => 1200 / wpm;

  Duration get dit => _fromMs(ditMs);
  Duration get dah => _fromMs(3 * ditMs);
  Duration get intraGap => _fromMs(ditMs);

  /// Character gap after Farnsworth stretching (3 dit when not stretched).
  Duration get charGap =>
      isFarnsworth ? _fromSeconds(3 * _farnsworthGapSeconds / 19) : _fromMs(3 * ditMs);

  /// Word gap after Farnsworth stretching (7 dit when not stretched).
  Duration get wordGap =>
      isFarnsworth ? _fromSeconds(7 * _farnsworthGapSeconds / 19) : _fromMs(7 * ditMs);

  /// ARRL Farnsworth formula: total time (seconds) available for the 19 gap
  /// units of the word PARIS (4 character gaps x 3 + 1 word gap x 7) when
  /// characters are sent at `c = wpm` and the overall speed is
  /// `s = farnsworthWpm`:
  ///
  /// `ta = (60c - 37.2s) / (s * c)`
  ///
  /// With c == s this collapses to `22.8 / c`, i.e. exactly 19 dits.
  double get _farnsworthGapSeconds {
    final double c = wpm;
    final double s = farnsworthWpm!;
    return (60 * c - 37.2 * s) / (s * c);
  }

  MorseTiming copyWith({double? wpm, double? farnsworthWpm}) => MorseTiming(
        wpm: wpm ?? this.wpm,
        farnsworthWpm: farnsworthWpm ?? this.farnsworthWpm,
      );

  /// Round a millisecond value to the nearest microsecond.
  static Duration _fromMs(double ms) =>
      Duration(microseconds: (ms * Duration.microsecondsPerMillisecond).round());

  static Duration _fromSeconds(double s) =>
      Duration(microseconds: (s * Duration.microsecondsPerSecond).round());

  @override
  bool operator ==(Object other) =>
      other is MorseTiming &&
      other.wpm == wpm &&
      other.farnsworthWpm == farnsworthWpm;

  @override
  int get hashCode => Object.hash(wpm, farnsworthWpm);

  @override
  String toString() => 'MorseTiming(wpm: $wpm, farnsworthWpm: $farnsworthWpm)';
}
