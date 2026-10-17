import 'package:flutter/material.dart';
import 'package:radio_tools/radio_tools.dart';

import '../../i18n/l10n_extension.dart';
import '../common/field_label.dart';
import 'band_tool.dart';
import 'decimal_field.dart';
import 'power_tool.dart';
import 'si_format.dart';
import 'swr_tool.dart';
import 'tool_page.dart';

/// Loss of a coax run at a frequency, what an antenna's SWR does to it and
/// to the SWR the radio sees, and λ/4 / λ/2 section lengths in that cable.
class FeedlineTool extends StatefulWidget {
  const FeedlineTool({super.key});

  static const Key cableKey = Key('feedline-cable');
  static const Key lengthKey = Key('feedline-length');
  static const Key frequencyKey = Key('feedline-frequency');
  static const Key swrKey = Key('feedline-swr');
  static const Key powerKey = Key('feedline-power');

  @override
  State<FeedlineTool> createState() => _FeedlineToolState();
}

class _FeedlineToolState extends State<FeedlineTool> {
  CoaxCable _cable = Feedlines.catalogue.singleWhere((c) => c.name == 'RG-213');
  final TextEditingController _length = TextEditingController();
  final TextEditingController _frequency = TextEditingController();
  final TextEditingController _swr = TextEditingController(text: '1');
  final TextEditingController _power = TextEditingController(text: '100');

  @override
  void dispose() {
    _length.dispose();
    _frequency.dispose();
    _swr.dispose();
    _power.dispose();
    super.dispose();
  }

  void _changed(String _) => setState(() {});

  double? get _swrValue {
    final v = parseDecimal(_swr.text);
    return v != null && v.isFinite && v >= 1 ? v : null;
  }

  bool get _invalid =>
      rejected(_length, nonNegativeOf(_length)) ||
      rejected(_frequency, positiveOf(_frequency)) ||
      rejected(_swr, _swrValue) ||
      rejected(_power, positiveOf(_power));

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final mhz = positiveOf(_frequency);
    return ToolPage(
      title: s.toolsFeedlineTitle,
      children: <Widget>[
        ToolSection(
          children: <Widget>[
            DropdownButtonFormField<CoaxCable>(
              key: FeedlineTool.cableKey,
              initialValue: _cable,
              isExpanded: true,
              decoration: InputDecoration(
                label: FieldLabel(s.toolsFeedlineCable),
                border: const OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<CoaxCable>>[
                for (final c in Feedlines.catalogue)
                  DropdownMenuItem<CoaxCable>(value: c, child: Text(c.name)),
              ],
              onChanged: (c) => setState(() => _cable = c ?? _cable),
            ),
            const SizedBox(height: 12),
            DecimalField(
              key: FeedlineTool.lengthKey,
              controller: _length,
              label: s.toolsFeedlineLength,
              hint: '30',
              onChanged: _changed,
            ),
            const SizedBox(height: 12),
            DecimalField(
              key: FeedlineTool.frequencyKey,
              controller: _frequency,
              label: s.toolsFeedlineFrequency,
              hint: '144.3',
              onChanged: _changed,
            ),
            const SizedBox(height: 12),
            DecimalField(
              key: FeedlineTool.swrKey,
              controller: _swr,
              label: s.toolsFeedlineSwr,
              hint: '1.5',
              onChanged: _changed,
            ),
            const SizedBox(height: 12),
            DecimalField(
              key: FeedlineTool.powerKey,
              controller: _power,
              label: s.toolsFeedlinePower,
              hint: '100',
              onChanged: _changed,
            ),
            const SizedBox(height: 8),
            if (_invalid)
              Text(
                s.toolsFeedlineInvalid,
                style: TextStyle(color: theme.colorScheme.error),
              )
            else
              ..._results(s),
          ],
        ),
        ToolSection(
          title: s.toolsFeedlineSections,
          children: <Widget>[
            ResultRow(
              label: s.toolsFeedlineImpedance,
              value: formatOhms(_cable.impedance),
            ),
            ResultRow(
              label: s.toolsFeedlineVelocityFactor,
              value: _cable.velocityFactor.toStringAsFixed(2),
            ),
            if (mhz != null) ...<Widget>[
              ResultRow(
                label: s.toolsFeedlineQuarterWave,
                value: formatMetres(_cable.wavelengthM(mhz) / 4),
              ),
              ResultRow(
                label: s.toolsFeedlineHalfWave,
                value: formatMetres(_cable.wavelengthM(mhz) / 2),
              ),
            ],
          ],
        ),
        Text(s.toolsFeedlineNote, style: theme.textTheme.bodySmall),
      ],
    );
  }

  List<Widget> _results(S s) {
    final length = nonNegativeOf(_length);
    final mhz = positiveOf(_frequency);
    final swr = _swrValue;
    if (length == null || mhz == null || swr == null) return const <Widget>[];
    final run = FeedlineRun(
      cable: _cable,
      lengthM: length,
      mhz: mhz,
      swrAtLoad: swr,
    );
    final power = positiveOf(_power);
    return <Widget>[
      ResultRow(
        label: s.toolsFeedlineMatchedLoss,
        value: formatDb(run.matchedLossDb, decimals: 2),
        emphasize: swr == 1,
      ),
      if (swr > 1) ...<Widget>[
        ResultRow(
          label: s.toolsFeedlineTotalLoss,
          value: formatDb(run.totalLossDb, decimals: 2),
          emphasize: true,
        ),
        ResultRow(
          label: s.toolsFeedlineSwrAtRadio,
          value: formatSwr(run.swrAtInput),
        ),
      ],
      if (power != null)
        ResultRow(
          label: s.toolsFeedlinePowerAtAntenna,
          value:
              '${formatWatts(run.powerDeliveredW(power))} · '
              '${(run.powerDeliveredW(power) / power * 100).toStringAsFixed(0)} %',
        ),
      ResultRow(
        label: s.toolsFeedlineElectricalLength,
        value:
            '${run.electricalDegrees.toStringAsFixed(0)}° · '
            '${run.electricalWavelengths.toStringAsFixed(2)} λ',
      ),
    ];
  }
}
