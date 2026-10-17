import 'package:flutter/material.dart';
import 'package:radio_tools/radio_tools.dart';

import '../../i18n/l10n_extension.dart';
import 'decimal_field.dart';
import 'si_format.dart';
import 'swr_tool.dart';
import 'tool_page.dart';

/// Coil and capacitor values of the L-networks that bring an antenna's
/// `R + jX` to the feedline impedance at a frequency.
class MatchingTool extends StatefulWidget {
  const MatchingTool({super.key});

  static const Key frequencyKey = Key('match-frequency');
  static const Key resistanceKey = Key('match-resistance');
  static const Key reactanceKey = Key('match-reactance');
  static const Key referenceKey = Key('match-reference');

  @override
  State<MatchingTool> createState() => _MatchingToolState();
}

class _MatchingToolState extends State<MatchingTool> {
  final TextEditingController _frequency = TextEditingController();
  final TextEditingController _resistance = TextEditingController();
  final TextEditingController _reactance = TextEditingController();
  final TextEditingController _reference = TextEditingController(text: '50');

  @override
  void dispose() {
    _frequency.dispose();
    _resistance.dispose();
    _reactance.dispose();
    _reference.dispose();
    super.dispose();
  }

  void _changed(String _) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return ToolPage(
      title: s.toolsMatchTitle,
      children: <Widget>[
        ToolSection(
          children: <Widget>[
            _field(
              MatchingTool.frequencyKey,
              _frequency,
              s.toolsMatchFrequency,
              '7.1',
            ),
            const SizedBox(height: 12),
            _field(
              MatchingTool.resistanceKey,
              _resistance,
              s.toolsMatchResistance,
              '25',
            ),
            const SizedBox(height: 12),
            _field(
              MatchingTool.reactanceKey,
              _reactance,
              s.toolsMatchReactance,
              '0',
            ),
            const SizedBox(height: 12),
            _field(
              MatchingTool.referenceKey,
              _reference,
              s.toolsMatchReference,
              '50',
            ),
          ],
        ),
        ..._results(s),
        Text(s.toolsMatchNote, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _field(
    Key key,
    TextEditingController controller,
    String label,
    String hint,
  ) => DecimalField(
    key: key,
    controller: controller,
    label: label,
    hint: hint,
    onChanged: _changed,
  );

  List<Widget> _results(S s) {
    final mhz = positiveOf(_frequency);
    final r = positiveOf(_resistance);
    final x = optionalOf(_reactance);
    final z0 = positiveOf(_reference);
    if (rejected(_frequency, mhz) ||
        rejected(_resistance, r) ||
        x == null ||
        rejected(_reference, z0)) {
      return <Widget>[
        ToolSection(
          children: <Widget>[
            Text(
              s.toolsMatchInvalid,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      ];
    }
    if (mhz == null || r == null || z0 == null) return const <Widget>[];
    final swr = Swr.fromImpedance(resistance: r, reactance: x, reference: z0);
    final solutions = LNetwork.solutions(
      resistance: r,
      reactance: x,
      reference: z0,
      frequencyHz: mhz * 1e6,
    );
    return <Widget>[
      ToolSection(
        children: <Widget>[
          ResultRow(label: s.toolsMatchSwrBefore, value: formatSwr(swr.ratio)),
          if (solutions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(s.toolsMatchAlreadyMatched),
            ),
        ],
      ),
      for (var i = 0; i < solutions.length; i++)
        _SolutionCard(index: i + 1, match: solutions[i]),
    ];
  }
}

class _SolutionCard extends StatelessWidget {
  const _SolutionCard({required this.index, required this.match});

  final int index;
  final LMatch match;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final kind = match.lowPass ? s.toolsMatchLowPass : s.toolsMatchHighPass;
    return ToolSection(
      title: s.toolsMatchSolution(index, kind),
      children: <Widget>[
        ResultRow(
          label: match.shuntAtLoad
              ? s.toolsMatchShuntAcrossAntenna
              : s.toolsMatchSeriesAtAntenna,
          value: describeElement(
            s,
            match.shuntAtLoad ? match.shunt : match.series,
          ),
          emphasize: true,
        ),
        ResultRow(
          label: match.shuntAtLoad
              ? s.toolsMatchSeriesAtRadio
              : s.toolsMatchShuntAcrossRadio,
          value: describeElement(
            s,
            match.shuntAtLoad ? match.series : match.shunt,
          ),
          emphasize: true,
        ),
        ResultRow(label: s.toolsMatchQ, value: match.q.toStringAsFixed(2)),
      ],
    );
  }
}

/// `L 0.560 µH · 25.0 Ω`, `C 448 pF · 50.0 Ω`, or the "nothing needed" text.
String describeElement(S s, ReactiveElement? element) {
  if (element == null) return s.toolsMatchNoElement;
  final (symbol, unit) = switch (element.kind) {
    ReactiveKind.inductor => ('L', 'H'),
    ReactiveKind.capacitor => ('C', 'F'),
  };
  return '$symbol ${formatEngineering(element.value, unit)} · '
      '${formatOhms(element.reactanceOhms.abs())}';
}
