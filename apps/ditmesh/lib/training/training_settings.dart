import 'package:morse_trainer/morse_trainer.dart';

/// How the operator keys during send practice.
enum KeyerMode {
  /// Hand key: every mark and gap is timed by the operator.
  straight,

  /// Two paddles, Curtis mode A.
  iambicA,

  /// Two paddles, Curtis mode B (default for most modern keyers).
  iambicB;

  bool get isPaddle => this != KeyerMode.straight;

  static KeyerMode parse(
    String? name, {
    KeyerMode fallback = KeyerMode.iambicB,
  }) {
    for (final mode in values) {
      if (mode.name == name) {
        return mode;
      }
    }
    return fallback;
  }
}

/// App-level training preferences: the pedagogy parameters from
/// `morse_trainer` plus the feedback modalities and keyer mode that only the
/// app (via `morse_io`) knows about.
///
/// Immutable value object with JSON support; `TrainingSettingsStore`
/// persists it next to the progress file.
final class TrainingSettings {
  const TrainingSettings({
    this.trainer = TrainerSettings.defaults,
    this.soundEnabled = true,
    this.flashEnabled = false,
    this.hapticEnabled = false,
    this.keyerMode = KeyerMode.iambicB,
    this.planMinutes = 10,
  });

  static const TrainingSettings defaults = TrainingSettings();

  /// Slider bounds, shared by the settings screen and its tests.
  static const double minCharacterWpm = 10;
  static const double maxCharacterWpm = 40;
  static const double minFarnsworthWpm = 5;
  static const double minToneHz = 400;
  static const double maxToneHz = 1000;

  /// Never below the Koch course minimum: a shorter lesson session could
  /// not unlock the next lesson.
  static const int minSessionChars = KochCourse.defaultMinCharsPerSession;
  static const int maxSessionChars = 200;

  final TrainerSettings trainer;

  /// Sidetone during drills and keying.
  final bool soundEnabled;

  /// Screen flash following the key (all platforms).
  final bool flashEnabled;

  /// Vibration following the key (Android / iOS only; ignored elsewhere).
  final bool hapticEnabled;

  final KeyerMode keyerMode;

  /// Daily-plan budget in minutes (one of `DailyPlanBuilder.budgets`).
  final int planMinutes;

  /// True when at least one modality renders the key state, so a drill is
  /// perceivable. The receive screen falls back to flash when nothing is on.
  bool get hasFeedback => soundEnabled || flashEnabled || hapticEnabled;

  TrainingSettings copyWith({
    TrainerSettings? trainer,
    bool? soundEnabled,
    bool? flashEnabled,
    bool? hapticEnabled,
    KeyerMode? keyerMode,
    int? planMinutes,
  }) => TrainingSettings(
    trainer: trainer ?? this.trainer,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    flashEnabled: flashEnabled ?? this.flashEnabled,
    hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    keyerMode: keyerMode ?? this.keyerMode,
    planMinutes: planMinutes ?? this.planMinutes,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'version': 1,
    'trainer': trainer.toJson(),
    'soundEnabled': soundEnabled,
    'flashEnabled': flashEnabled,
    'hapticEnabled': hapticEnabled,
    'keyerMode': keyerMode.name,
    'planMinutes': planMinutes,
  };

  /// Reads [toJson] output; missing or malformed keys fall back to defaults.
  factory TrainingSettings.fromJson(Map<String, Object?> json) {
    const d = TrainingSettings.defaults;
    final rawTrainer = json['trainer'];
    return TrainingSettings(
      trainer: rawTrainer is Map<String, Object?>
          ? TrainerSettings.fromJson(rawTrainer)
          : d.trainer,
      soundEnabled: json['soundEnabled'] as bool? ?? d.soundEnabled,
      flashEnabled: json['flashEnabled'] as bool? ?? d.flashEnabled,
      hapticEnabled: json['hapticEnabled'] as bool? ?? d.hapticEnabled,
      keyerMode: KeyerMode.parse(json['keyerMode'] as String?),
      planMinutes: switch ((json['planMinutes'] as num?)?.toInt()) {
        final int m when DailyPlanBuilder.budgets.contains(m) => m,
        _ => d.planMinutes,
      },
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TrainingSettings &&
      other.trainer == trainer &&
      other.soundEnabled == soundEnabled &&
      other.flashEnabled == flashEnabled &&
      other.hapticEnabled == hapticEnabled &&
      other.keyerMode == keyerMode &&
      other.planMinutes == planMinutes;

  @override
  int get hashCode => Object.hash(
    trainer,
    soundEnabled,
    flashEnabled,
    hapticEnabled,
    keyerMode,
    planMinutes,
  );

  @override
  String toString() =>
      'TrainingSettings($trainer, sound $soundEnabled, flash $flashEnabled, '
      'haptic $hapticEnabled, ${keyerMode.name})';
}
