import 'dart:math';

import 'char_stats.dart';
import 'confusion_matrix.dart';
import 'daily_plan.dart';
import 'koch_course.dart';

/// Everything a plan is generated from. Injected so a fixed input always
/// produces the same plan.
final class PlanInputs {
  PlanInputs({
    required this.now,
    required this.profileKey,
    required this.budgetMinutes,
    required this.lesson,
    required this.course,
    required this.due,
    required this.charStats,
    required this.confusion,
    required this.settings,
    required this.seed,
  });

  final DateTime now;
  final String profileKey;
  final int budgetMinutes;
  final int lesson;
  final KochCourse course;

  /// SRS-due learned symbols (not the "never tracked" fallback).
  final List<String> due;
  final Map<String, CharStats> charStats;
  final ConfusionMatrix confusion;
  final PlanSettings settings;
  final int seed;
}

/// Pure plan generator (functional spec §4.2). It owns every decision; the
/// app only displays and executes the result.
abstract final class DailyPlanBuilder {
  /// Budgets offered to the learner.
  static const List<int> budgets = <int>[5, 10, 15];

  /// Minutes per category for a 10-minute plan; scaled for other budgets.
  static const Map<PlanStepKind, double> allocation = <PlanStepKind, double>{
    PlanStepKind.review: 3,
    PlanStepKind.focus: 2,
    PlanStepKind.course: 3,
    PlanStepKind.send: 2,
  };

  /// Evidence needed before a symbol is a focus candidate.
  static const int minConfusions = 3;
  static const int minAttemptsForWeakness = 10;
  static const double weakAccuracy = 0.9;

  /// Fraction of a step spent listening (the rest is answering).
  static const double listenShare = 0.5;

  /// Send targets per minute of sending.
  static const double sendTargetsPerMinute = 1.5;

  /// Symbols copied in [minutes] at [effectiveWpm] (PARIS: 5 symbols/word).
  static int charsFor(double minutes, double effectiveWpm) =>
      max(10, (minutes * effectiveWpm * 5 * listenShare).round());

  /// Minutes needed to copy [chars] at [effectiveWpm].
  static double minutesFor(int chars, double effectiveWpm) =>
      chars / (effectiveWpm * 5 * listenShare);

  static DailyPlan build(PlanInputs inputs) {
    final date = DailyPlan.dateKey(inputs.now);
    final id = 'plan_${date}_${inputs.seed.toRadixString(36)}';
    return DailyPlan(
      id: id,
      date: date,
      profileKey: inputs.profileKey,
      seed: inputs.seed,
      budgetMinutes: inputs.budgetMinutes,
      settings: inputs.settings,
      steps: _steps(inputs, id, 0),
    );
  }

  /// Rebuilds the steps that have not started, keeping done and active
  /// steps (and their snapshots) untouched.
  static DailyPlan refreshPending(DailyPlan plan, PlanInputs inputs) {
    final kept = plan.steps
        .where((s) => s.state != PlanStepState.pending)
        .toList();
    final keptKinds = kept.map((s) => s.kind).toSet();
    final fresh = _steps(
      inputs,
      plan.id,
      plan.steps.length,
    ).where((s) => !keptKinds.contains(s.kind));
    // Started steps keep their own frozen speeds; the plan's current speeds
    // and budget follow the inputs for everything new.
    return plan.withSettings(inputs.settings, inputs.budgetMinutes).withSteps([
      ...kept,
      ...fresh,
    ]);
  }

  /// Pool of symbols with enough evidence of trouble, worst first.
  static List<String> focusPool(PlanInputs inputs) {
    final learned = inputs.course.charSetForLesson(inputs.lesson);
    final scores = <String, double>{};
    for (final c in learned) {
      final errors = inputs.confusion.errorsFor(c);
      final stats = inputs.charStats[c];
      if (errors >= minConfusions) {
        scores[c] = (scores[c] ?? 0) + errors.toDouble();
        final partner = inputs.confusion.mostConfusedWith(c);
        if (partner != null && partner != c && learned.contains(partner)) {
          scores[partner] = (scores[partner] ?? 0) + errors / 2;
        }
      }
      if (stats != null &&
          stats.attempts >= minAttemptsForWeakness &&
          stats.accuracy < weakAccuracy) {
        scores[c] = (scores[c] ?? 0) + (1 - stats.accuracy) * 10;
      }
    }
    final ordered = scores.keys.toList()
      ..sort((a, b) {
        final byScore = scores[b]!.compareTo(scores[a]!);
        return byScore != 0 ? byScore : a.compareTo(b);
      });
    return ordered;
  }

  static List<PlanStep> _steps(PlanInputs inputs, String planId, int offset) {
    final course = inputs.course;
    final lesson = course.clampLesson(inputs.lesson);
    final learned = course.charsForLesson(lesson);
    final learnedSet = learned.toSet();
    final due = inputs.due.where(learnedSet.contains).toList();
    final focus = focusPool(inputs);
    final hasConfusions = focus.any(
      (c) => inputs.confusion.errorsFor(c) >= minConfusions,
    );

    final available = <PlanStepKind>{
      if (due.isNotEmpty) PlanStepKind.review,
      if (focus.isNotEmpty) PlanStepKind.focus,
      PlanStepKind.course,
      PlanStepKind.send,
    };
    final scale = inputs.budgetMinutes / 10;
    final missing = allocation.entries
        .where((e) => !available.contains(e.key))
        .fold(0.0, (a, e) => a + e.value);
    final present = allocation.entries
        .where((e) => available.contains(e.key))
        .fold(0.0, (a, e) => a + e.value);
    double minutesOf(PlanStepKind kind) =>
        allocation[kind]! * (1 + missing / present) * scale;

    final random = Random(inputs.seed);
    final eff = inputs.settings.effectiveWpm;
    final steps = <PlanStep>[];
    String nextId() => '$planId/${offset + steps.length}';
    int nextSeed() =>
        (inputs.seed * 31 + (offset + steps.length + 1) * 7919) & 0x3fffffff;

    // Priority order (spec §4.2.2): review, focus, course, send.
    if (available.contains(PlanStepKind.review)) {
      final minutes = minutesOf(PlanStepKind.review);
      final pool = due.length >= 2 ? due : _withFallback(due, learned, random);
      steps.add(
        PlanStep(
          id: nextId(),
          seed: nextSeed(),
          kind: PlanStepKind.review,
          pool: pool,
          minutes: minutes,
          charBudget: charsFor(minutes, eff),
          lesson: lesson,
          reason: PlanReason.dueReview,
        ),
      );
    }
    if (available.contains(PlanStepKind.focus)) {
      final minutes = minutesOf(PlanStepKind.focus);
      final top = focus.take(4).toList();
      steps.add(
        PlanStep(
          id: nextId(),
          seed: nextSeed(),
          kind: PlanStepKind.focus,
          pool: top.length >= 2 ? top : _withFallback(top, learned, random),
          minutes: minutes,
          charBudget: charsFor(minutes, eff),
          lesson: lesson,
          reason: hasConfusions
              ? PlanReason.confusions
              : PlanReason.weakSymbols,
        ),
      );
    }
    {
      var minutes = minutesOf(PlanStepKind.course);
      var chars = charsFor(minutes, eff);
      final minChars = course.minCharsPerSession;
      var reason = PlanReason.courseChallenge;
      var eligible = true;
      if (chars < minChars) {
        if (inputs.budgetMinutes >= 10) {
          chars = minChars;
          minutes = minutesFor(chars, eff);
          reason = PlanReason.courseExtended;
        } else {
          eligible = false;
          reason = PlanReason.courseConsolidate;
        }
      }
      steps.add(
        PlanStep(
          id: nextId(),
          seed: nextSeed(),
          kind: PlanStepKind.course,
          pool: learned,
          minutes: minutes,
          charBudget: chars,
          lesson: lesson,
          reason: reason,
          unlockEligible: eligible,
        ),
      );
    }
    {
      final minutes = minutesOf(PlanStepKind.send);
      steps.add(
        PlanStep(
          id: nextId(),
          seed: nextSeed(),
          kind: PlanStepKind.send,
          pool: learned,
          minutes: minutes,
          charBudget: max(2, (minutes * sendTargetsPerMinute).round()),
          lesson: lesson,
          reason: PlanReason.sendRhythm,
        ),
      );
    }
    return steps;
  }

  /// [pool] topped up from [learned] to two symbols (existing drill
  /// fallback: a drill needs at least two symbols to be meaningful).
  static List<String> _withFallback(
    List<String> pool,
    List<String> learned,
    Random random,
  ) {
    final out = <String>[...pool];
    final rest = learned.where((c) => !out.contains(c)).toList()
      ..shuffle(random);
    for (final c in rest) {
      if (out.length >= 2) break;
      out.add(c);
    }
    return out;
  }

  /// The course step as it should run now: when the course moved past the
  /// step's lesson it becomes consolidation without unlock eligibility, so
  /// old questions can never unlock a new lesson.
  static PlanStep effectiveStep(PlanStep step, int currentLesson) {
    if (step.kind != PlanStepKind.course || step.lesson == currentLesson) {
      return step;
    }
    return step.copyWith(
      unlockEligible: false,
      reason: PlanReason.courseOutdated,
    );
  }
}
