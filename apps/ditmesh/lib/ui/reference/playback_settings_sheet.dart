import 'package:flutter/material.dart';

import '../../i18n/l10n_extension.dart';
import 'reference_playback_settings.dart';

/// Opens the speed / Farnsworth / tone sheet for [settings].
Future<void> showReferencePlaybackSettings(
  BuildContext context,
  ReferencePlaybackSettings settings,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => SafeArea(
      // Scrolls on short landscape phones instead of overflowing.
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ReferencePlaybackSettingsSheet(settings: settings),
      ),
    ),
  );
}

/// Sliders for the reference playback settings; rebuilds as they change.
class ReferencePlaybackSettingsSheet extends StatelessWidget {
  const ReferencePlaybackSettingsSheet({super.key, required this.settings});

  final ReferencePlaybackSettings settings;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final S s = context.s;
    String wpmLabel(double v) => s.referenceWpmValue('${v.round()}');
    return ListenableBuilder(
      listenable: settings,
      builder: (BuildContext context, _) {
        final double? fw = settings.farnsworthWpm;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              s.referencePlaybackSettings,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _SliderRow(
              label: s.referenceCharacterSpeed,
              value: settings.wpm,
              valueLabel: wpmLabel(settings.wpm),
              min: ReferencePlaybackSettings.minWpm,
              max: ReferencePlaybackSettings.maxWpm,
              divisions:
                  (ReferencePlaybackSettings.maxWpm -
                          ReferencePlaybackSettings.minWpm)
                      .round(),
              onChanged: (double v) => settings.wpm = v,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.referenceFarnsworth),
              subtitle: Text(s.referenceFarnsworthHelp),
              value: settings.farnsworthEnabled,
              onChanged: settings.setFarnsworthEnabled,
            ),
            if (fw != null)
              _SliderRow(
                label: s.referenceEffectiveSpeed,
                value: fw,
                valueLabel: wpmLabel(fw),
                min: ReferencePlaybackSettings.minWpm,
                max: settings.wpm,
                divisions: (settings.wpm - ReferencePlaybackSettings.minWpm)
                    .round()
                    .clamp(1, 100),
                onChanged: (double v) => settings.farnsworthWpm = v,
              ),
            _SliderRow(
              label: s.referenceTone,
              value: settings.toneHz,
              valueLabel: s.referenceHzValue('${settings.toneHz.round()}'),
              min: ReferencePlaybackSettings.minToneHz,
              max: ReferencePlaybackSettings.maxToneHz,
              divisions:
                  ((ReferencePlaybackSettings.maxToneHz -
                              ReferencePlaybackSettings.minToneHz) /
                          25)
                      .round(),
              onChanged: (double v) => settings.toneHz = v,
            ),
          ],
        );
      },
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final String valueLabel;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
            Text(valueLabel, style: theme.textTheme.labelLarge),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
