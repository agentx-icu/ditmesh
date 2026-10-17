import 'package:flutter/material.dart';
import 'package:radio_tools/radio_tools.dart';

import '../../i18n/l10n_extension.dart';
import 'decimal_field.dart';
import 'power_tool.dart';
import 'si_format.dart';
import 'swr_tool.dart';
import 'tool_page.dart';

/// Radio horizon for two antenna heights, then the free-space link:
/// EIRP / ERP, path loss and the level and S-meter reading at the far end.
class LinkBudgetTool extends StatefulWidget {
  const LinkBudgetTool({super.key});

  static const Key heightAKey = Key('link-height-a');
  static const Key heightBKey = Key('link-height-b');
  static const Key powerKey = Key('link-power');
  static const Key txLossKey = Key('link-tx-loss');
  static const Key txGainKey = Key('link-tx-gain');
  static const Key rxGainKey = Key('link-rx-gain');
  static const Key frequencyKey = Key('link-frequency');
  static const Key distanceKey = Key('link-distance');

  @override
  State<LinkBudgetTool> createState() => _LinkBudgetToolState();
}

class _LinkBudgetToolState extends State<LinkBudgetTool> {
  final TextEditingController _heightA = TextEditingController();
  final TextEditingController _heightB = TextEditingController();
  final TextEditingController _power = TextEditingController();
  final TextEditingController _txLoss = TextEditingController();
  final TextEditingController _txGain = TextEditingController();
  final TextEditingController _rxGain = TextEditingController();
  final TextEditingController _frequency = TextEditingController();
  final TextEditingController _distance = TextEditingController();

  @override
  void dispose() {
    for (final c in <TextEditingController>[
      _heightA,
      _heightB,
      _power,
      _txLoss,
      _txGain,
      _rxGain,
      _frequency,
      _distance,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed(String _) => setState(() {});

  double? get _lineOfSightKm {
    final a = nonNegativeOf(_heightA);
    final b = nonNegativeOf(_heightB);
    return a == null || b == null ? null : Propagation.lineOfSightKm(a, b);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return ToolPage(
      title: s.toolsLinkTitle,
      children: <Widget>[
        ToolSection(
          title: s.toolsLinkHorizonSection,
          children: <Widget>[
            _field(
              LinkBudgetTool.heightAKey,
              _heightA,
              s.toolsLinkHeightA,
              '10',
            ),
            const SizedBox(height: 12),
            _field(
              LinkBudgetTool.heightBKey,
              _heightB,
              s.toolsLinkHeightB,
              '2',
            ),
            const SizedBox(height: 8),
            ..._horizonResults(s),
          ],
        ),
        ToolSection(
          title: s.toolsLinkPathSection,
          children: <Widget>[
            _field(LinkBudgetTool.powerKey, _power, s.toolsLinkPower, '5'),
            const SizedBox(height: 12),
            _field(LinkBudgetTool.txLossKey, _txLoss, s.toolsLinkTxLoss, '1'),
            const SizedBox(height: 12),
            _field(
              LinkBudgetTool.txGainKey,
              _txGain,
              s.toolsLinkTxGain,
              '2.15',
            ),
            const SizedBox(height: 12),
            _field(
              LinkBudgetTool.rxGainKey,
              _rxGain,
              s.toolsLinkRxGain,
              '2.15',
            ),
            const SizedBox(height: 12),
            _field(
              LinkBudgetTool.frequencyKey,
              _frequency,
              s.toolsLinkFrequency,
              '144.3',
            ),
            const SizedBox(height: 12),
            _field(
              LinkBudgetTool.distanceKey,
              _distance,
              s.toolsLinkDistance,
              '50',
            ),
            const SizedBox(height: 8),
            ..._pathResults(s),
          ],
        ),
        Text(s.toolsLinkNote, style: theme.textTheme.bodySmall),
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

  List<Widget> _horizonResults(S s) {
    final a = nonNegativeOf(_heightA);
    final b = nonNegativeOf(_heightB);
    if (rejected(_heightA, a) || rejected(_heightB, b)) {
      return <Widget>[_error(s.toolsLinkInvalidHeight)];
    }
    return <Widget>[
      if (a != null)
        ResultRow(
          label: s.toolsLinkHorizonA,
          value: formatKm(Propagation.radioHorizonKm(a)),
        ),
      if (b != null)
        ResultRow(
          label: s.toolsLinkHorizonB,
          value: formatKm(Propagation.radioHorizonKm(b)),
        ),
      if (a != null && b != null)
        ResultRow(
          label: s.toolsLinkLineOfSight,
          value: formatKm(Propagation.lineOfSightKm(a, b)),
          emphasize: true,
        ),
    ];
  }

  List<Widget> _pathResults(S s) {
    final power = positiveOf(_power);
    final mhz = positiveOf(_frequency);
    final distance = positiveOf(_distance);
    final txLoss = optionalOf(_txLoss);
    final txGain = optionalOf(_txGain);
    final rxGain = optionalOf(_rxGain);
    if (rejected(_power, power) ||
        rejected(_frequency, mhz) ||
        rejected(_distance, distance) ||
        txLoss == null ||
        txGain == null ||
        rxGain == null) {
      return <Widget>[_error(s.toolsLinkInvalid)];
    }
    if (power == null || mhz == null || distance == null) {
      return const <Widget>[];
    }
    final link = LinkBudget(
      txDbm: Decibels.wattsToDbm(power),
      txLossDb: txLoss,
      txGainDbi: txGain,
      rxGainDbi: rxGain,
      distanceKm: distance,
      mhz: mhz,
    );
    final los = _lineOfSightKm;
    final received = link.receivedDbm;
    return <Widget>[
      ResultRow(label: s.toolsLinkEirp, value: _powerAndDbm(link.eirpDbm)),
      ResultRow(label: s.toolsLinkErp, value: _powerAndDbm(link.erpDbm)),
      ResultRow(label: s.toolsLinkPathLoss, value: formatDb(link.pathLossDb)),
      ResultRow(
        label: s.toolsLinkReceived,
        value: '${received.toStringAsFixed(1)} dBm',
        emphasize: true,
      ),
      ResultRow(
        label: s.toolsLinkReceivedVoltage,
        value: formatEngineering(
          Propagation.dbmToMicrovolts(received) * 1e-6,
          'V',
        ),
      ),
      ResultRow(
        label: s.toolsLinkSMeter,
        value: SMeterReading.fromDbm(received, vhf: mhz >= 30).label,
      ),
      if (los != null && distance > los)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            s.toolsLinkBeyondHorizon,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
    ];
  }

  String _powerAndDbm(double dbm) =>
      '${formatWatts(Decibels.dbmToWatts(dbm))} · ${dbm.toStringAsFixed(1)} dBm';
}
