import 'package:morse_trainer/morse_trainer.dart';

import 'receive_session.dart';

/// Which drill generator serves each [ReceiveDrillKind] for a learner's
/// current state. Single source of truth for both the drill picker and the
/// sessions that are started.
final class DrillCatalog {
  const DrillCatalog({
    required this.course,
    required this.progress,
    required this.settings,
  });

  /// Lesson from which QSO drills are offered (they need most letters).
  static const int qsoFromLesson = 30;

  /// Abbreviations / Q-codes needed before that drill is offered.
  static const int minShorthandWords = 3;

  final KochCourse course;
  final TrainerProgress progress;
  final TrainerSettings settings;

  int get lesson => progress.currentLesson;

  CharWeights weights() => CharWeights.fromStats(
    progress.charStats,
    recent: course.recentCharsForLesson(lesson),
  );

  /// The drill for [kind], falling back to lesson groups when [chars]
  /// cannot support it yet.
  DrillGenerator generatorFor(ReceiveDrillKind kind, List<String> chars) =>
      drillFor(kind, chars) ?? drillFor(ReceiveDrillKind.groups, chars)!;

  /// The drill for [kind] over [chars], or null when [chars] (or the
  /// current lesson) cannot support it.
  DrillGenerator? drillFor(ReceiveDrillKind kind, List<String> chars) {
    final allowed = chars.toSet();
    final t = settings;
    final lateLessons = lesson >= qsoFromLesson;
    switch (kind) {
      case ReceiveDrillKind.groups:
      case ReceiveDrillKind.review:
        return RandomGroupsDrill(
          chars: chars,
          groupCount: 1,
          groupSize: t.groupSize,
          weights: weights(),
        );
      case ReceiveDrillKind.characters:
        return RandomGroupsDrill(
          chars: chars,
          groupCount: 1,
          groupSize: 1,
          weights: weights(),
        );
      case ReceiveDrillKind.words:
        final words = WordDrill.commonWords(
          allowedChars: allowed,
          wordCount: 2,
        );
        return words.hasCandidates ? words : null;
      case ReceiveDrillKind.abbreviations:
        final shorthand = WordDrill.radioShorthand(
          allowedChars: allowed,
          wordCount: 2,
        );
        // `K` alone is an abbreviation; a drill of only `K K` is not one.
        return shorthand.candidates.length >= minShorthandWords
            ? shorthand
            : null;
      case ReceiveDrillKind.numbers:
        final numbers = NumberGroupsDrill(
          groupSize: t.groupSize,
          allowedChars: allowed,
        );
        return numbers.canGenerate ? numbers : null;
      case ReceiveDrillKind.callsigns:
        final calls = CallsignDrill(count: 1, allowedChars: allowed);
        return calls.canGenerate ? calls : null;
      case ReceiveDrillKind.confusables:
        final pairs = ConfusableDrill(
          chars: chars,
          confusion: progress.confusion,
          groupSize: t.groupSize,
        );
        return pairs.canGenerate ? pairs : null;
      case ReceiveDrillKind.qso:
        return lateLessons ? QsoDrill() : null;
      case ReceiveDrillKind.contest:
        final contest = ContestExchangeDrill(allowedChars: allowed);
        return lateLessons && contest.canGenerate ? contest : null;
    }
  }
}
