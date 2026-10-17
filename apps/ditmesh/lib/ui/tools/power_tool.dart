import 'package:flutter/material.dart';
import 'package:radio_tools/radio_tools.dart';

import '../../i18n/l10n_extension.dart';
import '../common/field_label.dart';
import 'tool_page.dart';

/// Units a power can be typed in.
enum PowerUnit {
  watts('W'),
  milliwatts('mW'),
  dbm('dBm'),
  dbw('dBW');

  const PowerUnit(this.symbol);

  /// SI / engineering symbol, the same in every language.
  final String symbol;

  /// The typed [value] as a level in dBm, or null when it is not a power.
  double? toDbm(double value) => switch (this) {
    PowerUnit.watts => value > 0 ? Decibels.wattsToDbm(value) : null,
    PowerUnit.milliwatts =>
      value > 0 ? Decibels.wattsToDbm(value / 1000) : null,
    PowerUnit.dbm => value,
    PowerUnit.dbw => value + 30,
  };
}

/// Power in watts <-> dBm / dBW with the S-meter reading it would give, and
/// decibels <-> power / voltage ratio.
class PowerTool extends StatefulWidget {
  const PowerTool({super.key});

  static const Key valueKey = Key('power-value');
  static const Key dbKey = Key('power-db');

  @override
  State<PowerTool> createState() => _PowerToolState();
}

class _PowerToolState extends State<PowerTool> {
  final TextEditingController _value = TextEditingController();
  final TextEditingController _db = TextEditingController();
  PowerUnit _unit = PowerUnit.watts;

  @override
  void dispose() {
    _value.dispose();
    _db.dispose();
    super.dispose();
  }

  double? get _dbm {
    final v = parseDecimal(_value.text);
    return v == null || !v.isFinite ? null : _unit.toDbm(v);
  }

  bool get _invalidPower => _value.text.trim().isNotEmpty && _dbm == null;

  double? get _gainDb {
    final v = parseDecimal(_db.text);
    return v != null && v.isFinite ? v : null;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return ToolPage(
      title: s.toolsPowerTitle,
      children: <Widget>[
        ToolSection(
          title: s.toolsPowerSection,
          children: <Widget>[
            SegmentedButton<PowerUnit>(
              segments: <ButtonSegment<PowerUnit>>[
                for (final u in PowerUnit.values)
                  ButtonSegment<PowerUnit>(value: u, label: Text(u.symbol)),
              ],
              selected: <PowerUnit>{_unit},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _unit = v.single),
            ),
            const SizedBox(height: 12),
            TextField(
              key: PowerTool.valueKey,
              controller: _value,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                label: FieldLabel(s.toolsPowerValue),
                hintText: '100',
                errorText: _invalidPower ? s.toolsPowerInvalid : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ..._powerResults(s),
            Text(s.toolsPowerSMeterNote, style: theme.textTheme.bodySmall),
          ],
        ),
        ToolSection(
          title: s.toolsPowerRatioSection,
          children: <Widget>[
            TextField(
              key: PowerTool.dbKey,
              controller: _db,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                label: FieldLabel(s.toolsPowerDb),
                hintText: '3',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ..._ratioResults(s),
            Text(s.toolsPowerDbNote, style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  List<Widget> _powerResults(S s) {
    final dbm = _dbm;
    if (dbm == null) return const <Widget>[];
    return <Widget>[
      ResultRow(
        label: s.toolsPowerValue,
        value: formatWatts(Decibels.dbmToWatts(dbm)),
        emphasize: true,
      ),
      ResultRow(
        label: s.toolsPowerLevel,
        value:
            '${dbm.toStringAsFixed(1)} dBm · ${(dbm - 30).toStringAsFixed(1)} dBW',
      ),
      ResultRow(
        label: s.toolsPowerSMeterHf,
        value: SMeterReading.fromDbm(dbm).label,
      ),
      ResultRow(
        label: s.toolsPowerSMeterVhf,
        value: SMeterReading.fromDbm(dbm, vhf: true).label,
      ),
    ];
  }

  List<Widget> _ratioResults(S s) {
    final db = _gainDb;
    if (db == null) return const <Widget>[];
    return <Widget>[
      ResultRow(
        label: s.toolsPowerRatio,
        value: '× ${formatRatio(Decibels.dbToPowerRatio(db))}',
        emphasize: true,
      ),
      ResultRow(
        label: s.toolsPowerVoltageRatio,
        value: '× ${formatRatio(Decibels.dbToVoltageRatio(db))}',
      ),
      ResultRow(
        label: s.toolsPowerSUnits,
        value: (db / SMeterReading.dbPerUnit).toStringAsFixed(1),
      ),
    ];
  }
}

/// Watts with an SI prefix: `1.50 kW`, `100 W`, `5.00 mW`, `0.10 µW`.
String formatWatts(double watts) {
  const prefixes = <(double, String)>[
    (1e6, 'MW'),
    (1e3, 'kW'),
    (1, 'W'),
    (1e-3, 'mW'),
    (1e-6, 'µW'),
    (1e-9, 'nW'),
  ];
  for (final (scale, unit) in prefixes) {
    if (watts >= scale) return '${_threeDigits(watts / scale)} $unit';
  }
  return '${_threeDigits(watts * 1e12)} pW';
}

/// A ratio with three significant digits up to 100, whole numbers above.
String formatRatio(double ratio) =>
    ratio >= 100 ? ratio.toStringAsFixed(0) : _threeDigits(ratio);

/// Three significant digits: `1.50`, `12.6`, `100`, `0.10`. Rounds first,
/// so 99.9999 is `100` and not `100.0`.
String _threeDigits(double v) {
  final r = double.parse(v.toStringAsPrecision(3));
  if (r >= 100) return r.toStringAsFixed(0);
  if (r >= 10) return r.toStringAsFixed(1);
  return r.toStringAsFixed(2);
}
