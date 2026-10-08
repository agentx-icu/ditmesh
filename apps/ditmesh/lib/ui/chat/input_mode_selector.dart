import 'package:flutter/material.dart';

import '../../i18n/l10n_extension.dart';
import 'input_mode.dart';

/// Segmented straight key / paddles switch above the composer.
class InputModeSelector extends StatelessWidget {
  const InputModeSelector({
    super.key,
    required this.mode,
    required this.showLabels,
    required this.onChanged,
  });

  final InputMode mode;
  final bool showLabels;
  final ValueChanged<InputMode> onChanged;

  ButtonSegment<InputMode> _segment(
    InputMode value,
    IconData icon,
    String label,
  ) => ButtonSegment<InputMode>(
    value: value,
    icon: Icon(icon),
    label: showLabels ? Text(label) : null,
    tooltip: label,
  );

  @override
  Widget build(BuildContext context) {
    final S s = context.s;
    return SegmentedButton<InputMode>(
      showSelectedIcon: false,
      selected: <InputMode>{mode},
      onSelectionChanged: (sel) => onChanged(sel.first),
      segments: [
        _segment(
          InputMode.straightKey,
          Icons.radio_button_checked,
          s.chatModeStraightKey,
        ),
        _segment(
          InputMode.paddles,
          Icons.view_column_outlined,
          s.chatModePaddles,
        ),
      ],
    );
  }
}
