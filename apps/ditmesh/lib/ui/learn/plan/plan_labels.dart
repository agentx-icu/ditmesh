import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';

/// Localised titles, reasons and icons for daily-plan steps. The plan
/// carries reason codes only; prose lives in the ARBs.
abstract final class PlanLabels {
  static String title(S s, PlanStep step) => switch (step.kind) {
    PlanStepKind.review => s.learnPlanStepReview,
    PlanStepKind.focus => s.learnPlanStepFocus,
    PlanStepKind.course => s.learnPlanStepCourse(step.lesson),
    PlanStepKind.send => s.learnPlanStepSend,
  };

  static IconData icon(PlanStepKind kind) => switch (kind) {
    PlanStepKind.review => Icons.replay,
    PlanStepKind.focus => Icons.center_focus_strong_outlined,
    PlanStepKind.course => Icons.school_outlined,
    PlanStepKind.send => Icons.touch_app_outlined,
  };

  static String reason(S s, PlanStep step) {
    final symbols = step.pool.take(6).join(' ');
    return switch (step.reason) {
      PlanReason.dueReview => s.learnPlanReasonDueReview(symbols),
      PlanReason.confusions => s.learnPlanReasonConfusions(symbols),
      PlanReason.weakSymbols => s.learnPlanReasonWeak(symbols),
      PlanReason.courseChallenge => s.learnPlanReasonChallenge(step.charBudget),
      PlanReason.courseExtended => s.learnPlanReasonExtended(step.charBudget),
      PlanReason.courseConsolidate => s.learnPlanReasonConsolidate,
      PlanReason.courseOutdated => s.learnPlanReasonOutdated(step.lesson),
      PlanReason.sendRhythm => s.learnPlanReasonSend(step.charBudget),
    };
  }
}
