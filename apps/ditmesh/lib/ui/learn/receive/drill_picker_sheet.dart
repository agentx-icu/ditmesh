import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/receive_session.dart';
import '../conditions/conditions_playback.dart';

/// Bottom sheet listing the receive drills the learned set supports, with
/// the channel conditions to play them under (F11; Clear by default, each
/// preset previewable before starting).
///
/// The list scrolls inside the sheet so a short phone screen (or a large
/// text scale) never overflows as more drills unlock. Resolves to the picked
/// kind and preset, or null when dismissed.
Future<(ReceiveDrillKind, RadioPreset)?> showDrillPickerSheet(
  BuildContext context,
  List<ReceiveDrillKind> kinds, {
  Future<void> Function(RadioPreset preset)? onPreview,
}) => showModalBottomSheet<(ReceiveDrillKind, RadioPreset)>(
  context: context,
  showDragHandle: true,
  builder: (sheetContext) => SafeArea(
    child: DrillPickerList(
      kinds: kinds,
      onPreview: onPreview,
      onPicked: (k, preset) => Navigator.of(sheetContext).pop((k, preset)),
    ),
  ),
);

/// The scrollable content of [showDrillPickerSheet].
class DrillPickerList extends StatefulWidget {
  const DrillPickerList({
    super.key,
    required this.kinds,
    required this.onPicked,
    this.onPreview,
  });

  final List<ReceiveDrillKind> kinds;
  final void Function(ReceiveDrillKind kind, RadioPreset preset) onPicked;

  /// Plays a short sample under a preset; null hides the preview button.
  final Future<void> Function(RadioPreset preset)? onPreview;

  /// Key of the row for [kind], for tests and driving harnesses.
  static Key tileKey(ReceiveDrillKind kind) => Key('drill-${kind.name}');

  /// Key of the conditions selector.
  static const Key presetKey = Key('drill-conditions');

  @override
  State<DrillPickerList> createState() => _DrillPickerListState();
}

class _DrillPickerListState extends State<DrillPickerList> {
  RadioPreset _preset = RadioPreset.clear;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final preview = widget.onPreview;
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(s.learnChooseDrill, style: theme.textTheme.titleMedium),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(s.conditionsTitle, style: theme.textTheme.titleSmall),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // Chips wrap on a narrow phone or at a large text scale.
          child: Wrap(
            key: DrillPickerList.presetKey,
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final p in RadioPreset.values)
                ChoiceChip(
                  key: Key('drill-conditions-${p.name}'),
                  label: Text(radioPresetLabel(s, p)),
                  selected: _preset == p,
                  onSelected: (_) => setState(() => _preset = p),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  radioPresetHint(s, _preset),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              if (preview != null && _preset != RadioPreset.clear)
                TextButton.icon(
                  key: const Key('drill-conditions-preview'),
                  onPressed: () => preview(_preset),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(s.conditionsPreview),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final k in widget.kinds)
          if (_preset == RadioPreset.clear || k != ReceiveDrillKind.review)
            ListTile(
              key: DrillPickerList.tileKey(k),
              leading: Icon(drillIcon(k)),
              title: Text(drillLabel(s, k)),
              subtitle: Text(drillDescription(s, k)),
              onTap: () => widget.onPicked(k, _preset),
            ),
      ],
    );
  }
}

IconData drillIcon(ReceiveDrillKind kind) => switch (kind) {
  ReceiveDrillKind.groups => Icons.grid_view,
  ReceiveDrillKind.characters => Icons.bolt,
  ReceiveDrillKind.words => Icons.text_fields,
  ReceiveDrillKind.abbreviations => Icons.short_text,
  ReceiveDrillKind.numbers => Icons.pin_outlined,
  ReceiveDrillKind.callsigns => Icons.badge_outlined,
  ReceiveDrillKind.confusables => Icons.compare_arrows,
  ReceiveDrillKind.qso => Icons.forum_outlined,
  ReceiveDrillKind.contest => Icons.emoji_events_outlined,
  ReceiveDrillKind.review => Icons.replay,
};

String drillLabel(S s, ReceiveDrillKind kind) => switch (kind) {
  ReceiveDrillKind.groups => s.learnDrillGroups,
  ReceiveDrillKind.characters => s.learnDrillCharacters,
  ReceiveDrillKind.words => s.learnDrillWords,
  ReceiveDrillKind.abbreviations => s.learnDrillAbbreviations,
  ReceiveDrillKind.numbers => s.learnDrillNumbers,
  ReceiveDrillKind.callsigns => s.learnDrillCallsigns,
  ReceiveDrillKind.confusables => s.learnDrillConfusables,
  ReceiveDrillKind.qso => s.learnDrillQso,
  ReceiveDrillKind.contest => s.learnDrillContest,
  ReceiveDrillKind.review => s.learnReviewTitle,
};

String drillDescription(S s, ReceiveDrillKind kind) => switch (kind) {
  ReceiveDrillKind.groups => s.learnDrillGroupsHint,
  ReceiveDrillKind.characters => s.learnDrillCharactersHint,
  ReceiveDrillKind.words => s.learnDrillWordsHint,
  ReceiveDrillKind.abbreviations => s.learnDrillAbbreviationsHint,
  ReceiveDrillKind.numbers => s.learnDrillNumbersHint,
  ReceiveDrillKind.callsigns => s.learnDrillCallsignsHint,
  ReceiveDrillKind.confusables => s.learnDrillConfusablesHint,
  ReceiveDrillKind.qso => s.learnDrillQsoHint,
  ReceiveDrillKind.contest => s.learnDrillContestHint,
  ReceiveDrillKind.review => s.learnDrillReviewHint,
};
