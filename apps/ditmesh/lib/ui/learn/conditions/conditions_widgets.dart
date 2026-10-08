import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import 'conditions_playback.dart';

/// Names the active radio conditions above a round (F11).
class ConditionsChip extends StatelessWidget {
  const ConditionsChip({super.key, required this.scenario});

  final RadioScenario scenario;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: Chip(
          key: const ValueKey('conditions-chip'),
          avatar: const Icon(Icons.waves, size: 18),
          label: Text(s.conditionsActive(radioPresetLabel(s, scenario.preset))),
        ),
      ),
    );
  }
}

/// Results under the same channel and speeds only (F11), never mixed with
/// clean copying, plus what such practice does and does not change.
class ConditionsSummary extends StatelessWidget {
  const ConditionsSummary({
    super.key,
    required this.scenario,
    required this.history,
  });

  final RadioScenario scenario;
  final List<SessionSummary> history;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final same = history.where(
      (h) =>
          h.conditions?.comparableKey == scenario.comparableKey &&
          h.totalChars > 0,
    );
    var total = 0;
    var correct = 0;
    for (final h in same) {
      total += h.totalChars;
      correct += h.correctChars;
    }
    final pct = total == 0 ? 0 : (100 * correct / total).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          s.conditionsComparable(same.length, pct),
          key: const ValueKey('conditions-comparable'),
        ),
        Text(s.conditionsSeparateNote),
      ],
    );
  }
}

/// After an answer: replay the round without effects, as a reference.
class CleanReferenceButton extends StatelessWidget {
  const CleanReferenceButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: OutlinedButton.icon(
      key: const ValueKey('conditions-clean-replay'),
      onPressed: onPressed,
      icon: const Icon(Icons.hearing),
      label: Text(context.s.conditionsCleanReplay),
    ),
  );
}
