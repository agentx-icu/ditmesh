import 'package:flutter/material.dart';
import 'package:radio_tools/radio_tools.dart';

import '../../i18n/l10n_extension.dart';
import '../common/field_label.dart';
import 'tool_page.dart';

/// SWR from a directional wattmeter's forward / reflected readings or from
/// a load impedance, with return loss, reflected share and mismatch loss.
class SwrTool extends StatefulWidget {
  const SwrTool({super.key});

  static const Key forwardKey = Key('swr-forward');
  static const Key reflectedKey = Key('swr-reflected');
  static const Key resistanceKey = Key('swr-resistance');
  static const Key reactanceKey = Key('swr-reactance');
  static const Key referenceKey = Key('swr-reference');

  @override
  State<SwrTool> createState() => _SwrToolState();
}

class _SwrToolState extends State<SwrTool> {
  final TextEditingController _forward = TextEditingController();
  final TextEditingController _reflected = TextEditingController();
  final TextEditingController _resistance = TextEditingController();
  final TextEditingController _reactance = TextEditingController();
  final TextEditingController _reference = TextEditingController(text: '50');

  @override
  void dispose() {
    _forward.dispose();
    _reflected.dispose();
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
      title: s.toolsSwrTitle,
      children: <Widget>[
        ToolSection(
          title: s.toolsSwrFromPower,
          children: <Widget>[
            _field(SwrTool.forwardKey, _forward, s.toolsSwrForward, '100'),
            const SizedBox(height: 12),
            _field(SwrTool.reflectedKey, _reflected, s.toolsSwrReflected, '4'),
            const SizedBox(height: 8),
            ..._powerResults(s),
          ],
        ),
        ToolSection(
          title: s.toolsSwrFromImpedance,
          children: <Widget>[
            _field(
              SwrTool.resistanceKey,
              _resistance,
              s.toolsSwrResistance,
              '75',
            ),
            const SizedBox(height: 12),
            _field(SwrTool.reactanceKey, _reactance, s.toolsSwrReactance, '0'),
            const SizedBox(height: 12),
            _field(SwrTool.referenceKey, _reference, s.toolsSwrReference, '50'),
            const SizedBox(height: 8),
            ..._impedanceResults(s),
          ],
        ),
        Text(s.toolsSwrNote, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _field(
    Key key,
    TextEditingController controller,
    String label,
    String hint,
  ) => TextField(
    key: key,
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    onChanged: _changed,
    decoration: InputDecoration(
      label: FieldLabel(label),
      hintText: hint,
      border: const OutlineInputBorder(),
    ),
  );

  List<Widget> _powerResults(S s) {
    final forward = parseDecimal(_forward.text);
    final reflected = parseDecimal(_reflected.text);
    if (forward == null || reflected == null) return const <Widget>[];
    if (!forward.isFinite ||
        forward <= 0 ||
        !reflected.isFinite ||
        reflected < 0 ||
        reflected > forward) {
      return <Widget>[_error(s.toolsSwrInvalidPower)];
    }
    final swr = Swr.fromPowers(forwardW: forward, reflectedW: reflected);
    return <Widget>[
      ..._swrRows(s, swr),
      ResultRow(
        label: s.toolsSwrReflectedShare,
        value: '${(swr.reflectedFraction * 100).toStringAsFixed(1)} %',
      ),
      ResultRow(
        label: s.toolsSwrMismatchLoss,
        value: formatDb(swr.mismatchLossDb, decimals: 2),
      ),
    ];
  }

  List<Widget> _impedanceResults(S s) {
    final r = parseDecimal(_resistance.text);
    final z0 = parseDecimal(_reference.text);
    final xText = _reactance.text.trim();
    final x = xText.isEmpty ? 0.0 : parseDecimal(xText);
    if (r == null || z0 == null || x == null) return const <Widget>[];
    if (!r.isFinite || r < 0 || !z0.isFinite || z0 <= 0 || !x.isFinite) {
      return <Widget>[_error(s.toolsSwrInvalidImpedance)];
    }
    final swr = Swr.fromImpedance(resistance: r, reactance: x, reference: z0);
    return _swrRows(s, swr);
  }

  List<Widget> _swrRows(S s, Swr swr) => <Widget>[
    ResultRow(
      label: s.toolsSwrRatio,
      value: formatSwr(swr.ratio),
      emphasize: true,
    ),
    ResultRow(label: s.toolsSwrReturnLoss, value: formatDb(swr.returnLossDb)),
    ResultRow(
      label: s.toolsSwrCoefficient,
      value: swr.reflectionCoefficient.toStringAsFixed(3),
    ),
  ];

  Widget _error(String text) =>
      Text(text, style: TextStyle(color: Theme.of(context).colorScheme.error));
}

/// `1.50:1`; `∞` for total reflection.
String formatSwr(double ratio) =>
    ratio.isInfinite ? '∞' : '${ratio.toStringAsFixed(2)}:1';

/// `14.0 dB`; `∞ dB` when the quantity is unbounded.
String formatDb(double db, {int decimals = 1}) =>
    db.isInfinite ? '∞ dB' : '${db.toStringAsFixed(decimals)} dB';
