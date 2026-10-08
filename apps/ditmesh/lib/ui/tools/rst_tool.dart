import 'package:flutter/material.dart';
import 'package:radio_tools/radio_tools.dart';

import '../../i18n/l10n_extension.dart';
import 'tool_page.dart';

/// Composes an RST report digit by digit and shows what each digit means.
class RstTool extends StatefulWidget {
  const RstTool({super.key});

  @override
  State<RstTool> createState() => _RstToolState();
}

class _RstToolState extends State<RstTool> {
  int _r = 5;
  int _s = 9;
  int _t = 9;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final report = RstReport(readability: _r, strength: _s, tone: _t);
    return ToolPage(
      title: s.toolsRstTitle,
      children: <Widget>[
        ToolSection(
          children: <Widget>[
            ResultRow(
              label: s.toolsRstReport,
              value: report.toString(),
              emphasize: true,
            ),
            ResultRow(label: s.toolsRstCut, value: report.cut),
            ResultRow(label: s.toolsRstPhone, value: '$_r$_s'),
          ],
        ),
        _scale(
          title: s.toolsRstReadability,
          max: 5,
          value: _r,
          meaning: rstReadability(s, _r),
          onChanged: (v) => setState(() => _r = v),
        ),
        _scale(
          title: s.toolsRstStrength,
          max: 9,
          value: _s,
          meaning: rstStrength(s, _s),
          onChanged: (v) => setState(() => _s = v),
        ),
        _scale(
          title: s.toolsRstTone,
          max: 9,
          value: _t,
          meaning: rstTone(s, _t),
          onChanged: (v) => setState(() => _t = v),
        ),
      ],
    );
  }

  /// A row of digit chips (wraps on phones) and the selected digit's meaning.
  Widget _scale({
    required String title,
    required int max,
    required int value,
    required String meaning,
    required ValueChanged<int> onChanged,
  }) => ToolSection(
    title: title,
    children: <Widget>[
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          for (var v = 1; v <= max; v++)
            ChoiceChip(
              label: Text('$v'),
              selected: v == value,
              onSelected: (_) => onChanged(v),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Text(meaning, style: Theme.of(context).textTheme.bodyLarge),
    ],
  );
}

String rstReadability(S s, int r) => switch (r) {
  1 => s.toolsRstR1,
  2 => s.toolsRstR2,
  3 => s.toolsRstR3,
  4 => s.toolsRstR4,
  _ => s.toolsRstR5,
};

String rstStrength(S s, int v) => switch (v) {
  1 => s.toolsRstS1,
  2 => s.toolsRstS2,
  3 => s.toolsRstS3,
  4 => s.toolsRstS4,
  5 => s.toolsRstS5,
  6 => s.toolsRstS6,
  7 => s.toolsRstS7,
  8 => s.toolsRstS8,
  _ => s.toolsRstS9,
};

String rstTone(S s, int t) => switch (t) {
  1 => s.toolsRstT1,
  2 => s.toolsRstT2,
  3 => s.toolsRstT3,
  4 => s.toolsRstT4,
  5 => s.toolsRstT5,
  6 => s.toolsRstT6,
  7 => s.toolsRstT7,
  8 => s.toolsRstT8,
  _ => s.toolsRstT9,
};
