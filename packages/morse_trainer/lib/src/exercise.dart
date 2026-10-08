import 'dart:math';

/// Where a recorded exercise came from (functional spec §3.2 `source`).
enum ExerciseSource {
  /// Koch lesson copying (the only source that can unlock a lesson).
  course,

  /// SRS review of due symbols.
  review,

  /// A focused drill (weak symbols, confusions, free receive practice).
  focus,

  /// Sending practice.
  send,

  /// Interactive QSO simulator (semantic score, not copying accuracy).
  qso,

  /// Copying a received chat message.
  chat,

  /// Copying a custom training material.
  material,

  /// Placement assessment.
  placement,

  /// Copying a recorded audio file.
  recording,

  /// Copying under simulated radio conditions (F11): results are kept
  /// apart from clean copying and never feed SRS, unlocks or speed advice.
  conditions;

  static ExerciseSource? parse(String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

/// Help the learner used during one attempt. Any of these makes the attempt
/// "assisted" (spec §3.3): it still counts as activity but never feeds SRS,
/// lesson unlocks or speed advice.
enum Assistance {
  /// The audio was played again after the first listen.
  replay,

  /// The full answer was revealed before submitting.
  reveal,

  /// A single symbol was revealed.
  hint,

  /// An automatic decoder's output was visible while copying.
  decoder;

  static Set<Assistance>? parseAll(Object? raw) {
    if (raw is! List) return null;
    return <Assistance>{
      for (final name in raw)
        for (final value in values)
          if (value.name == name) value,
    };
  }
}

/// What one exercise is allowed to change (spec §3.3 credit table).
final class ExerciseCredit {
  const ExerciseCredit({
    required this.activity,
    required this.receiveStats,
    required this.unlock,
    required this.speedSample,
  });

  static const ExerciseCredit none = ExerciseCredit(
    activity: false,
    receiveStats: false,
    unlock: false,
    speedSample: false,
  );

  /// History, streak, daily goal and lifetime counters.
  final bool activity;

  /// Per-symbol statistics, confusion matrix and SRS boxes (learned symbols
  /// only; the caller passes the learned set).
  final bool receiveStats;

  /// May advance the Koch lesson (course rules still apply).
  final bool unlock;

  /// May be used as evidence for a speed recommendation.
  final bool speedSample;

  @override
  String toString() =>
      'ExerciseCredit(activity $activity, stats $receiveStats, '
      'unlock $unlock, speed $speedSample)';
}

/// The single place that maps an exercise's source and conditions to credit.
abstract final class CreditPolicy {
  /// [answered] is false for playback-only or empty sessions.
  static ExerciseCredit decide({
    required ExerciseSource source,
    required bool completed,
    required bool answered,
    required Set<Assistance> assistance,
  }) {
    if (!answered || !completed) return ExerciseCredit.none;
    const activityOnly = ExerciseCredit(
      activity: true,
      receiveStats: false,
      unlock: false,
      speedSample: false,
    );
    if (assistance.isNotEmpty) return activityOnly;
    switch (source) {
      case ExerciseSource.course:
        return const ExerciseCredit(
          activity: true,
          receiveStats: true,
          unlock: true,
          speedSample: true,
        );
      case ExerciseSource.review:
      case ExerciseSource.focus:
      case ExerciseSource.chat:
      case ExerciseSource.material:
        return const ExerciseCredit(
          activity: true,
          receiveStats: true,
          unlock: false,
          speedSample: true,
        );
      case ExerciseSource.send:
      case ExerciseSource.qso:
      case ExerciseSource.placement:
      case ExerciseSource.recording:
      case ExerciseSource.conditions:
        return activityOnly;
    }
  }
}

/// Stable exercise ids: time plus randomness, so a retried save keeps its id
/// and a new attempt always gets a new one.
abstract final class ExerciseIds {
  static String next(DateTime now, Random random) {
    final r = random.nextInt(0x7fffffff).toRadixString(36);
    return 'ex_${now.microsecondsSinceEpoch.toRadixString(36)}_$r';
  }
}
