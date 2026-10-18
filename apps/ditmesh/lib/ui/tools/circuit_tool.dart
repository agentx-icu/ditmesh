import 'package:flutter/material.dart';
import 'package:radio_tools/radio_tools.dart';

import '../../i18n/l10n_extension.dart';
import 'decimal_field.dart';
import 'si_format.dart';
import 'swr_tool.dart';
import 'tool_page.dart';

/// Bench-side RF arithmetic: LC resonance and reactance, π / T attenuator
/// resistors and the minimum-loss pad between two impedances.
class CircuitTool extends StatefulWidget {
  const CircuitTool({super.key});

  static const Key frequencyKey = Key('circuit-frequency');
  static const Key inductanceKey = Key('circuit-inductance');
  static const Key capacitanceKey = Key('circuit-capacitance');
  static const Key attenuationKey = Key('circuit-attenuation');
  static const Key impedanceKey = Key('circuit-impedance');
  static const Key padHighKey = Key('circuit-pad-high');
  static const Key padLowKey = Key('circuit-pad-low');

  @override
  State<CircuitTool> createState() => _CircuitToolState();
}

class _CircuitToolState extends State<CircuitTool> {
  final TextEditingController _frequency = TextEditingController();
  final TextEditingController _inductance = TextEditingController();
  final TextEditingController _capacitance = TextEditingController();
  final TextEditingController _attenuation = TextEditingController();
  final TextEditingController _impedance = TextEditingController(text: '50');
  final TextEditingController _padHigh = TextEditingController();
  final TextEditingController _padLow = TextEditingController();

  @override
  void dispose() {
    for (final c in <TextEditingController>[
      _frequency,
      _inductance,
      _capacitance,
      _attenuation,
      _impedance,
      _padHigh,
      _padLow,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed(String _) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return ToolPage(
      title: s.toolsCircuitTitle,
      children: <Widget>[
        ToolSection(
          title: s.toolsCircuitResonanceSection,
          children: <Widget>[
            _field(
              CircuitTool.frequencyKey,
              _frequency,
              s.toolsCircuitFrequency,
              '7.1',
            ),
            const SizedBox(height: 12),
            _field(
              CircuitTool.inductanceKey,
              _inductance,
              s.toolsCircuitInductance,
              '10',
            ),
            const SizedBox(height: 12),
            _field(
              CircuitTool.capacitanceKey,
              _capacitance,
              s.toolsCircuitCapacitance,
              '100',
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Text(
                s.toolsCircuitResonanceHelp,
                style: theme.textTheme.bodySmall,
              ),
            ),
            ..._resonanceResults(s),
          ],
        ),
        ToolSection(
          title: s.toolsCircuitAttenuatorSection,
          children: <Widget>[
            _field(
              CircuitTool.attenuationKey,
              _attenuation,
              s.toolsCircuitAttenuation,
              '10',
            ),
            const SizedBox(height: 12),
            _field(
              CircuitTool.impedanceKey,
              _impedance,
              s.toolsCircuitImpedance,
              '50',
            ),
            const SizedBox(height: 8),
            ..._attenuatorResults(s),
          ],
        ),
        ToolSection(
          title: s.toolsCircuitPadSection,
          children: <Widget>[
            _field(
              CircuitTool.padHighKey,
              _padHigh,
              s.toolsCircuitPadHigh,
              '75',
            ),
            const SizedBox(height: 12),
            _field(CircuitTool.padLowKey, _padLow, s.toolsCircuitPadLow, '50'),
            const SizedBox(height: 8),
            ..._padResults(s),
          ],
        ),
        Text(s.toolsCircuitNote, style: theme.textTheme.bodySmall),
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

  Widget _error(String text) =>
      Text(text, style: TextStyle(color: Theme.of(context).colorScheme.error));

  List<Widget> _resonanceResults(S s) {
    final fTyped = positiveOf(_frequency);
    final lTyped = positiveOf(_inductance);
    final cTyped = positiveOf(_capacitance);
    if (rejected(_frequency, fTyped) ||
        rejected(_inductance, lTyped) ||
        rejected(_capacitance, cTyped)) {
      return <Widget>[_error(s.toolsCircuitInvalid)];
    }
    final f = fTyped == null ? null : fTyped * 1e6;
    final l = lTyped == null ? null : lTyped * 1e-6;
    final c = cTyped == null ? null : cTyped * 1e-12;
    final double resonantHz;
    final double inductanceH;
    final double capacitanceF;
    if (l != null && c != null) {
      inductanceH = l;
      capacitanceF = c;
      resonantHz = Resonance.frequencyHz(inductanceH: l, capacitanceF: c);
    } else if (f != null && l != null) {
      resonantHz = f;
      inductanceH = l;
      capacitanceF = Resonance.capacitanceF(frequencyHz: f, inductanceH: l);
    } else if (f != null && c != null) {
      resonantHz = f;
      capacitanceF = c;
      inductanceH = Resonance.inductanceH(frequencyHz: f, capacitanceF: c);
    } else {
      return const <Widget>[];
    }
    final at = f ?? resonantHz;
    final atText = formatEngineering(at, 'Hz');
    return <Widget>[
      ResultRow(
        label: s.toolsCircuitResonantFrequency,
        value: formatEngineering(resonantHz, 'Hz'),
        emphasize: true,
      ),
      ResultRow(
        label: s.toolsCircuitInductanceResult,
        value: formatEngineering(inductanceH, 'H'),
      ),
      ResultRow(
        label: s.toolsCircuitCapacitanceResult,
        value: formatEngineering(capacitanceF, 'F'),
      ),
      ResultRow(
        label: s.toolsCircuitInductiveReactanceAt(atText),
        value: formatOhms(
          Resonance.inductiveReactance(
            frequencyHz: at,
            inductanceH: inductanceH,
          ),
        ),
      ),
      ResultRow(
        label: s.toolsCircuitCapacitiveReactanceAt(atText),
        value: formatOhms(
          Resonance.capacitiveReactance(
            frequencyHz: at,
            capacitanceF: capacitanceF,
          ),
        ),
      ),
    ];
  }

  List<Widget> _attenuatorResults(S s) {
    final db = positiveOf(_attenuation);
    final z0 = positiveOf(_impedance);
    if (rejected(_attenuation, db) || rejected(_impedance, z0)) {
      return <Widget>[_error(s.toolsCircuitInvalid)];
    }
    if (db == null || z0 == null) return const <Widget>[];
    final a = Attenuator.design(attenuationDb: db, impedance: z0);
    return <Widget>[
      ResultRow(label: s.toolsCircuitPiSeries, value: formatOhms(a.piSeries)),
      ResultRow(label: s.toolsCircuitPiShunt, value: formatOhms(a.piShunt)),
      ResultRow(label: s.toolsCircuitTeeSeries, value: formatOhms(a.teeSeries)),
      ResultRow(label: s.toolsCircuitTeeShunt, value: formatOhms(a.teeShunt)),
    ];
  }

  List<Widget> _padResults(S s) {
    final high = positiveOf(_padHigh);
    final low = positiveOf(_padLow);
    if (rejected(_padHigh, high) ||
        rejected(_padLow, low) ||
        (high != null && low != null && high == low)) {
      return <Widget>[_error(s.toolsCircuitPadInvalid)];
    }
    if (high == null || low == null) return const <Widget>[];
    final pad = MinimumLossPad.between(high, low);
    return <Widget>[
      ResultRow(
        label: s.toolsCircuitPadSeries,
        value: formatOhms(pad.seriesOhms),
      ),
      ResultRow(
        label: s.toolsCircuitPadShunt,
        value: formatOhms(pad.shuntOhms),
      ),
      ResultRow(
        label: s.toolsCircuitPadLoss,
        value: formatDb(pad.lossDb, decimals: 2),
        emphasize: true,
      ),
    ];
  }
}
