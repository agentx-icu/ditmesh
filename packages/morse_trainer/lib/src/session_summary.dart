import 'char_stats.dart';
import 'exercise.dart';
import 'radio_conditions.dart';
import 'session_score.dart';

/// Compact record of one finished session, kept in progress history.
///
/// Doubles as the exercise record of the functional spec (§3.2): the fields
/// after [elapsed] are optional exercise metadata. Summaries written before
/// they existed load with them null, which means *unknown* (never a measured
/// zero): an unknown [assistance] is not evidence of unassisted practice.
final class SessionSummary {
  SessionSummary({
    required this.at,
    required this.totalChars,
    required this.correctChars,
    this.lesson,
    this.drillKind,
    this.elapsed,
    this.id,
    this.source,
    this.characterWpm,
    this.effectiveWpm,
    this.toneHz,
    this.insertions,
    this.completed = true,
    Set<Assistance>? assistance,
    this.active,
    this.planStepId,
    this.sourceRef,
    this.detailRef,
    this.conditions,
    Map<String, CharStats>? perChar,
  }) : assert(totalChars >= 0, 'totalChars must be >= 0'),
       assert(
         correctChars >= 0 && correctChars <= totalChars,
         'correctChars must be within 0..totalChars',
       ),
       assistance = assistance == null
           ? null
           : Set<Assistance>.unmodifiable(assistance),
       perChar = perChar == null
           ? null
           : Map<String, CharStats>.unmodifiable(perChar);

  factory SessionSummary.fromScore(
    SessionScore score, {
    DateTime? at,
    int? lesson,
  }) => SessionSummary(
    at: at ?? score.at ?? DateTime.now(),
    totalChars: score.totalChars,
    correctChars: score.correctChars,
    lesson: lesson ?? score.lesson,
    drillKind: score.drillKind,
    elapsed: score.elapsed,
  );

  /// A full exercise record for [score] (new flows use this).
  factory SessionSummary.exercise(
    SessionScore score, {
    required String id,
    required ExerciseSource source,
    required DateTime at,
    required Set<Assistance> assistance,
    int? lesson,
    double? characterWpm,
    double? effectiveWpm,
    double? toneHz,
    bool completed = true,
    Duration? active,
    String? planStepId,
    String? sourceRef,
    String? detailRef,
    RadioScenario? conditions,
  }) => SessionSummary(
    at: at,
    totalChars: score.totalChars,
    correctChars: score.correctChars,
    lesson: lesson ?? score.lesson,
    drillKind: score.drillKind,
    elapsed: score.elapsed,
    id: id,
    source: source,
    characterWpm: characterWpm,
    effectiveWpm: effectiveWpm,
    toneHz: toneHz,
    insertions: score.insertions,
    completed: completed,
    assistance: assistance,
    active: active,
    planStepId: planStepId,
    sourceRef: sourceRef,
    detailRef: detailRef,
    conditions: conditions,
    perChar: score.charStats,
  );

  static const int schemaVersion = 2;

  final DateTime at;
  final int totalChars;
  final int correctChars;
  final int? lesson;
  final String? drillKind;

  /// Wall-clock length. Legacy files only have this; it is never relabelled
  /// as [active].
  final Duration? elapsed;

  /// Stable per attempt; null for legacy summaries.
  final String? id;
  final ExerciseSource? source;
  final double? characterWpm;
  final double? effectiveWpm;
  final double? toneHz;

  /// Extra symbols typed; null when unknown.
  final int? insertions;
  final bool completed;

  /// Help used during the attempt; null = unknown (legacy).
  final Set<Assistance>? assistance;

  /// Time spent actually practising (pauses and background excluded).
  final Duration? active;
  final String? planStepId;

  /// Local origin, e.g. `chat:<profile>/<conversation>/<message>`.
  final String? sourceRef;

  /// Optional detail file (rhythm, audio); may be missing on load.
  final String? detailRef;

  /// Simulated radio conditions the attempt was played under (F11); null
  /// for clean playback.
  final RadioScenario? conditions;

  /// Per-symbol results of this attempt alone (recent-window statistics).
  final Map<String, CharStats>? perChar;

  double get accuracy => totalChars == 0 ? 0 : correctChars / totalChars;

  /// Correct / (sent + inserted). Falls back to [accuracy] when the
  /// insertion count is unknown.
  double get strictAccuracy {
    final denominator = totalChars + (insertions ?? 0);
    return denominator == 0 ? 0 : correctChars / denominator;
  }

  /// Known and empty assistance.
  bool get isKnownUnassisted => assistance != null && assistance!.isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'at': at.toIso8601String(),
    'totalChars': totalChars,
    'correctChars': correctChars,
    'lesson': lesson,
    'drillKind': drillKind,
    'elapsedMs': elapsed?.inMilliseconds,
    if (id != null) ...<String, Object?>{
      'v': schemaVersion,
      'id': id,
      'source': source?.name,
      'characterWpm': characterWpm,
      'effectiveWpm': effectiveWpm,
      'toneHz': toneHz,
      'insertions': insertions,
      'completed': completed,
      'assistance': assistance?.map((a) => a.name).toList(),
      'activeMs': active?.inMilliseconds,
      'planStepId': planStepId,
      'sourceRef': sourceRef,
      'detailRef': detailRef,
      if (conditions != null) 'conditions': conditions!.toJson(),
      if (perChar != null) 'perChar': CharStats.mapToJson(perChar!),
    },
  };

  factory SessionSummary.fromJson(Map<String, Object?> json) {
    final elapsedMs = (json['elapsedMs'] as num?)?.toInt();
    final activeMs = (json['activeMs'] as num?)?.toInt();
    final perChar = json['perChar'];
    return SessionSummary(
      at: DateTime.parse(json['at'] as String),
      totalChars: (json['totalChars'] as num).toInt(),
      correctChars: (json['correctChars'] as num).toInt(),
      lesson: (json['lesson'] as num?)?.toInt(),
      drillKind: json['drillKind'] as String?,
      elapsed: elapsedMs == null ? null : Duration(milliseconds: elapsedMs),
      id: json['id'] as String?,
      source: ExerciseSource.parse(json['source'] as String?),
      characterWpm: (json['characterWpm'] as num?)?.toDouble(),
      effectiveWpm: (json['effectiveWpm'] as num?)?.toDouble(),
      toneHz: (json['toneHz'] as num?)?.toDouble(),
      insertions: (json['insertions'] as num?)?.toInt(),
      completed: json['completed'] as bool? ?? true,
      assistance: Assistance.parseAll(json['assistance']),
      active: activeMs == null ? null : Duration(milliseconds: activeMs),
      planStepId: json['planStepId'] as String?,
      sourceRef: json['sourceRef'] as String?,
      detailRef: json['detailRef'] as String?,
      conditions: RadioScenario.fromJson(json['conditions']),
      perChar: perChar is Map<String, Object?>
          ? CharStats.mapFromJson(perChar)
          : null,
    );
  }

  @override
  String toString() =>
      'SessionSummary($at, L$lesson ${drillKind ?? ''} '
      '$correctChars/$totalChars${id == null ? '' : ' $id'})';

  @override
  bool operator ==(Object other) =>
      other is SessionSummary &&
      other.at == at &&
      other.totalChars == totalChars &&
      other.correctChars == correctChars &&
      other.lesson == lesson &&
      other.drillKind == drillKind &&
      other.elapsed == elapsed &&
      other.id == id;

  @override
  int get hashCode =>
      Object.hash(at, totalChars, correctChars, lesson, drillKind, elapsed, id);
}
