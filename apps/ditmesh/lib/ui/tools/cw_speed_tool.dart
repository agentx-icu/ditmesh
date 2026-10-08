import 'package:flutter/material.dart';
import 'package:radio_tools/radio_tools.dart';

import '../../i18n/l10n_extension.dart';
import 'tool_page.dart';

/// WPM -> element and gap lengths, characters per minute and the time of
/// one PARIS word, with optional Farnsworth spacing - the same timing the
/// trainer plays at.
class CwSpeedTool extends StatefulWidget {
  const CwSpeedTool({super.key, this.initialWpm = 20});

  final double initialWpm;

  static const double minWpm = 5;
  static const double maxWpm = 60;

  @override
  State<CwSpeedTool> createState() => _CwSpeedToolState();
}

class _CwSpeedToolState extends State<CwSpeedTool> {
  late double _wpm = widget.initialWpm.clamp(
    CwSpeedTool.minWpm,
    CwSpeedTool.maxWpm,
  );
  bool _farnsworth = false;
  late double _overall = (_wpm / 2).roundToDouble().clamp(
    CwSpeedTool.minWpm,
    _wpm,
  );

  void _setWpm(double v) => setState(() {
    _wpm = v.roundToDouble();
    _overall = _overall.clamp(CwSpeedTool.minWpm, _wpm);
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final speed = CwSpeed(
      wpm: _wpm,
      farnsworthWpm: _farnsworth ? _overall : null,
    );
    return ToolPage(
      title: s.toolsSpeedTitle,
      children: <Widget>[
        ToolSection(
          children: <Widget>[
            _slider(
              label: s.toolsSpeedCharacter,
              value: _wpm,
              min: CwSpeedTool.minWpm,
              max: CwSpeedTool.maxWpm,
              onChanged: _setWpm,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.toolsSpeedFarnsworth),
              value: _farnsworth,
              onChanged: (v) => setState(() => _farnsworth = v),
            ),
            if (_farnsworth && _wpm > CwSpeedTool.minWpm)
              _slider(
                label: s.toolsSpeedOverall,
                value: _overall,
                min: CwSpeedTool.minWpm,
                max: _wpm,
                onChanged: (v) => setState(() => _overall = v.roundToDouble()),
              ),
          ],
        ),
        ToolSection(
          children: <Widget>[
            ResultRow(label: s.toolsSpeedDit, value: _ms(speed.ditMs)),
            ResultRow(label: s.toolsSpeedDah, value: _ms(speed.dahMs)),
            ResultRow(label: s.toolsSpeedCharGap, value: _ms(speed.charGapMs)),
            ResultRow(label: s.toolsSpeedWordGap, value: _ms(speed.wordGapMs)),
            ResultRow(
              label: s.toolsSpeedCpm,
              value: speed.charsPerMinute.round().toString(),
              emphasize: true,
            ),
            ResultRow(
              label: s.toolsSpeedParis,
              value: '${speed.parisSeconds.toStringAsFixed(2)} s',
            ),
          ],
        ),
      ],
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      ResultRow(label: label, value: '${value.round()} WPM'),
      Slider(
        value: value,
        min: min,
        max: max,
        divisions: (max - min).round(),
        label: '${value.round()}',
        onChanged: onChanged,
      ),
    ],
  );

  static String _ms(double ms) => '${ms.round()} ms';
}
