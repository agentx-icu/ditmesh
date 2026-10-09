import 'package:flutter/material.dart';

import '../../i18n/l10n_extension.dart';
import 'morse_playback_settings.dart';

/// Bottom sheet with the listener's speed / Farnsworth / tone sliders and
/// the auto-play switch.
Future<void> showPlaybackSettingsSheet(
  BuildContext context,
  MorsePlaybackSettings settings,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _PlaybackSettingsSheet(settings: settings),
  );
}

class _PlaybackSettingsSheet extends StatelessWidget {
  const _PlaybackSettingsSheet({required this.settings});

  final MorsePlaybackSettings settings;

  @override
  Widget build(BuildContext context) {
    final S s = context.s;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SafeArea(
        // Scrolls on short landscape phones instead of overflowing.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.chatPlaybackSettings,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.chatOriginalRhythm),
                subtitle: Text(s.chatOriginalPreference),
                value: settings.originalRhythm,
                onChanged: (v) => settings.originalRhythm = v,
              ),
              _SliderRow(
                label: s.chatCharacterSpeed,
                value: settings.wpm,
                min: MorsePlaybackSettings.minWpm,
                max: MorsePlaybackSettings.maxWpm,
                unit: s.chatWpm,
                onChanged: (v) => settings.wpm = v.roundToDouble(),
              ),
              _SliderRow(
                label: s.chatFarnsworthSpeed,
                value: settings.farnsworthWpm,
                min: MorsePlaybackSettings.minWpm,
                max: settings.wpm,
                unit: s.chatWpm,
                onChanged: (v) => settings.farnsworthWpm = v.roundToDouble(),
              ),
              _SliderRow(
                label: s.chatTone,
                value: settings.toneHz,
                min: MorsePlaybackSettings.minToneHz,
                max: MorsePlaybackSettings.maxToneHz,
                unit: s.chatHz,
                onChanged: (v) => settings.toneHz = (v / 10).round() * 10,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.chatAutoPlay),
                value: settings.autoPlay,
                onChanged: (v) => settings.autoPlay = v,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final double clamped = value.clamp(min, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.s.chatSliderValue(label, clamped.round(), unit)),
        Slider(
          value: clamped,
          min: min,
          max: max <= min ? min + 1 : max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
