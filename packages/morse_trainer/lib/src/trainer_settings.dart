import 'package:morse_core/morse_core.dart';

/// User-tunable training parameters.
///
/// Pure value object with JSON support; persisting it is the app's job.
final class TrainerSettings {
  const TrainerSettings({
    this.characterWpm = 20,
    this.farnsworthWpm = 8,
    this.toneHz = 700,
    this.sessionLengthChars = 50,
    this.sessionLengthSeconds,
    this.groupSize = 5,
  }) : assert(characterWpm > 0, 'characterWpm must be positive'),
       assert(
         farnsworthWpm == null || farnsworthWpm > 0,
         'farnsworthWpm must be positive',
       ),
       assert(toneHz > 0, 'toneHz must be positive'),
       assert(sessionLengthChars > 0, 'sessionLengthChars must be positive'),
       assert(
         sessionLengthSeconds == null || sessionLengthSeconds > 0,
         'sessionLengthSeconds must be positive',
       ),
       assert(groupSize > 0, 'groupSize must be positive');

  static const TrainerSettings defaults = TrainerSettings();

  /// Character (element) speed in words per minute. Koch default: 20.
  final double characterWpm;

  /// Effective overall speed with Farnsworth spacing, or null for standard
  /// spacing. Ignored by the timing when >= [characterWpm].
  final double? farnsworthWpm;

  /// Sidetone frequency in Hz.
  final double toneHz;

  /// Symbols per session (the Koch unlock rule needs at least 50 by default).
  final int sessionLengthChars;

  /// Optional wall-clock cap on a session; null means unlimited.
  final int? sessionLengthSeconds;

  /// Symbols per random group.
  final int groupSize;

  /// Whether Farnsworth stretching will actually apply.
  bool get isFarnsworth =>
      farnsworthWpm != null && farnsworthWpm! < characterWpm;

  /// The timing morse_core / morse_io should play with.
  MorseTiming toTiming() =>
      MorseTiming(wpm: characterWpm, farnsworthWpm: farnsworthWpm);

  TrainerSettings copyWith({
    double? characterWpm,
    double? farnsworthWpm,
    bool clearFarnsworth = false,
    double? toneHz,
    int? sessionLengthChars,
    int? sessionLengthSeconds,
    bool clearSessionLengthSeconds = false,
    int? groupSize,
  }) => TrainerSettings(
    characterWpm: characterWpm ?? this.characterWpm,
    farnsworthWpm: clearFarnsworth
        ? null
        : (farnsworthWpm ?? this.farnsworthWpm),
    toneHz: toneHz ?? this.toneHz,
    sessionLengthChars: sessionLengthChars ?? this.sessionLengthChars,
    sessionLengthSeconds: clearSessionLengthSeconds
        ? null
        : (sessionLengthSeconds ?? this.sessionLengthSeconds),
    groupSize: groupSize ?? this.groupSize,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'characterWpm': characterWpm,
    'farnsworthWpm': farnsworthWpm,
    'toneHz': toneHz,
    'sessionLengthChars': sessionLengthChars,
    'sessionLengthSeconds': sessionLengthSeconds,
    'groupSize': groupSize,
  };

  /// Reads settings written by [toJson]; missing keys fall back to defaults.
  factory TrainerSettings.fromJson(Map<String, Object?> json) {
    const d = TrainerSettings.defaults;
    return TrainerSettings(
      characterWpm:
          (json['characterWpm'] as num?)?.toDouble() ?? d.characterWpm,
      farnsworthWpm: json.containsKey('farnsworthWpm')
          ? (json['farnsworthWpm'] as num?)?.toDouble()
          : d.farnsworthWpm,
      toneHz: (json['toneHz'] as num?)?.toDouble() ?? d.toneHz,
      sessionLengthChars:
          (json['sessionLengthChars'] as num?)?.toInt() ?? d.sessionLengthChars,
      sessionLengthSeconds: (json['sessionLengthSeconds'] as num?)?.toInt(),
      groupSize: (json['groupSize'] as num?)?.toInt() ?? d.groupSize,
    );
  }

  @override
  String toString() =>
      'TrainerSettings(char $characterWpm wpm, farnsworth $farnsworthWpm, '
      '$toneHz Hz, $sessionLengthChars chars'
      '${sessionLengthSeconds == null ? '' : ' / ${sessionLengthSeconds}s'})';

  @override
  bool operator ==(Object other) =>
      other is TrainerSettings &&
      other.characterWpm == characterWpm &&
      other.farnsworthWpm == farnsworthWpm &&
      other.toneHz == toneHz &&
      other.sessionLengthChars == sessionLengthChars &&
      other.sessionLengthSeconds == sessionLengthSeconds &&
      other.groupSize == groupSize;

  @override
  int get hashCode => Object.hash(
    characterWpm,
    farnsworthWpm,
    toneHz,
    sessionLengthChars,
    sessionLengthSeconds,
    groupSize,
  );
}
