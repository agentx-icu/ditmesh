import 'package:flutter/material.dart';
import 'package:radio_tools/radio_tools.dart';

import '../../i18n/l10n_extension.dart';
import 'tool_page.dart';

/// Frequency -> amateur band (per IARU region), wavelength and wire-antenna
/// lengths, plus the region's band edges with QRP CW calling frequencies.
class BandTool extends StatefulWidget {
  const BandTool({super.key, this.initialRegion = IaruRegion.region1});

  final IaruRegion initialRegion;

  static const Key frequencyKey = Key('band-frequency');

  @override
  State<BandTool> createState() => _BandToolState();
}

class _BandToolState extends State<BandTool> {
  final TextEditingController _frequency = TextEditingController();
  late IaruRegion _region = widget.initialRegion;

  @override
  void dispose() {
    _frequency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return ToolPage(
      title: s.toolsBandsTitle,
      children: <Widget>[
        ToolSection(
          children: <Widget>[
            SegmentedButton<IaruRegion>(
              segments: <ButtonSegment<IaruRegion>>[
                for (final r in IaruRegion.values)
                  ButtonSegment<IaruRegion>(
                    value: r,
                    label: Text(s.toolsBandsRegionLabel(r.index + 1)),
                  ),
              ],
              selected: <IaruRegion>{_region},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _region = v.single),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 12),
              child: Text(
                s.toolsBandsRegionHelp,
                style: theme.textTheme.bodySmall,
              ),
            ),
            TextField(
              key: BandTool.frequencyKey,
              controller: _frequency,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: s.toolsBandsFrequency,
                hintText: '7.030',
                errorText: _invalid ? s.toolsBandsInvalidFrequency : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ..._results(s),
          ],
        ),
        ToolSection(
          title: s.toolsBandsTable,
          children: <Widget>[
            for (final band in AmateurBands.plan(_region))
              _BandRow(band: band, selected: band == _band),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                s.toolsBandsDisclaimer,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double? get _mhz {
    final f = parseDecimal(_frequency.text);
    return f != null && f.isFinite && f > 0 ? f : null;
  }

  bool get _invalid => _frequency.text.trim().isNotEmpty && _mhz == null;

  BandAllocation? get _band {
    final f = _mhz;
    return f == null ? null : AmateurBands.bandFor(f, _region);
  }

  List<Widget> _results(S s) {
    final f = _mhz;
    if (f == null) {
      return const <Widget>[];
    }
    final band = _band;
    return <Widget>[
      Text(
        band == null ? s.toolsBandsOutOfBand : s.toolsBandsInBand(band.name),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 4),
      ResultRow(
        label: s.toolsBandsWavelength,
        value: formatMetres(AmateurBands.wavelengthM(f)),
      ),
      ResultRow(
        label: s.toolsBandsDipole,
        value: formatMetres(AmateurBands.halfWaveDipoleM(f)),
      ),
      ResultRow(
        label: s.toolsBandsQuarterWave,
        value: formatMetres(AmateurBands.quarterWaveM(f)),
      ),
      Text(
        s.toolsBandsAntennaNote,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];
  }
}

class _BandRow extends StatelessWidget {
  const _BandRow({required this.band, required this.selected});

  final BandAllocation band;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final qrp = band.qrpCwMhz;
    return Container(
      decoration: BoxDecoration(
        color: selected ? theme.colorScheme.primaryContainer : null,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 56,
            child: Text(band.name, style: theme.textTheme.titleSmall),
          ),
          // ui-literal-ok: SI unit symbol MHz, written the same in every locale
          Text('${formatMhz(band.lowerMhz)} – ${formatMhz(band.upperMhz)} MHz'),
          if (qrp != null)
            Text(
              s.toolsBandsQrp(formatMhz(qrp)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// Metres with sensible precision: `20.34 m`, `2.04 m`, `0.65 m`, `2209 m`.
String formatMetres(double m) =>
    m >= 100 ? '${m.round()} m' : '${m.toStringAsFixed(2)} m';

/// MHz without trailing zeros past the kHz digit: `7.0`, `5.3515`, `0.1357`.
String formatMhz(double mhz) {
  var text = mhz.toStringAsFixed(4);
  while (text.endsWith('0') && !text.endsWith('.0')) {
    text = text.substring(0, text.length - 1);
  }
  return text;
}
