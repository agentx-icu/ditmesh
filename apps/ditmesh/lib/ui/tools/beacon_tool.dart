import 'dart:async';

import 'package:flutter/material.dart';
import 'package:radio_tools/radio_tools.dart';

import '../../i18n/l10n_extension.dart';
import 'band_tool.dart';
import 'grid_locator_tool.dart';
import 'locator_field.dart';
import 'tool_page.dart';
import 'utc_clock_tool.dart';

/// Which NCDXF / IARU beacon is on each of the five frequencies right now,
/// with heading and distance from the operator's locator, and when every
/// beacon comes round again on 20 m.
///
/// [now] is injectable so tests can pin the clock.
class BeaconTool extends StatefulWidget {
  const BeaconTool({super.key, this.now = DateTime.now});

  final DateTime Function() now;

  static const Key mineKey = Key('beacon-mine');

  @override
  State<BeaconTool> createState() => _BeaconToolState();
}

class _BeaconToolState extends State<BeaconTool> {
  final TextEditingController _mine = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final utc = widget.now().toUtc();
    final locator = LocatorField.locatorOf(_mine);
    final from = locator == null ? null : Maidenhead.toPoint(locator);
    return ToolPage(
      title: s.toolsBeaconsTitle,
      children: <Widget>[
        ToolSection(
          title: s.toolsBeaconsOnAir,
          children: <Widget>[
            ResultRow(label: s.toolsClockUtc, value: '${formatTime(utc)}Z'),
            ResultRow(
              label: s.toolsBeaconsSlotRemaining,
              value: '${NcdxfBeacons.slotRemaining(utc).inSeconds} s',
            ),
            const SizedBox(height: 8),
            for (
              var band = 0;
              band < NcdxfBeacons.frequenciesMhz.length;
              band++
            )
              _OnAirRow(
                frequencyMhz: NcdxfBeacons.frequenciesMhz[band],
                beacon: NcdxfBeacons.onAir(utc, band),
                from: from,
              ),
          ],
        ),
        ToolSection(
          children: <Widget>[
            LocatorField(
              key: BeaconTool.mineKey,
              controller: _mine,
              label: s.toolsGridMine,
              onChanged: (_) => setState(() {}),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                s.toolsBeaconsLocatorHelp,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        ToolSection(
          title: s.toolsBeaconsSchedule,
          children: <Widget>[
            for (final beacon in NcdxfBeacons.beacons)
              _ScheduleRow(beacon: beacon, utc: utc),
          ],
        ),
        Text(s.toolsBeaconsNote, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _OnAirRow extends StatelessWidget {
  const _OnAirRow({
    required this.frequencyMhz,
    required this.beacon,
    required this.from,
  });

  final double frequencyMhz;
  final Beacon beacon;
  final GeoPoint? from;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final origin = from;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 96,
            // ui-literal-ok: SI unit symbol MHz, written the same in every locale
            child: Text('${formatMhz(frequencyMhz)} MHz'),
          ),
          Text(beacon.callsign, style: theme.textTheme.titleSmall),
          Text(beaconPlace(context.s, beacon)),
          if (origin != null)
            Text(
              formatPathTo(origin, Maidenhead.toPoint(beacon.locator)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.beacon, required this.utc});

  final Beacon beacon;
  final DateTime utc;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final onAir = NcdxfBeacons.onAir(utc, 0) == beacon;
    final next = NcdxfBeacons.untilNext(utc, beacon);
    return Container(
      decoration: BoxDecoration(
        color: onAir ? theme.colorScheme.primaryContainer : null,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 72,
            child: Text(beacon.callsign, style: theme.textTheme.titleSmall),
          ),
          Text(beaconPlace(s, beacon)),
          Text(
            beacon.locator,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          Text(
            onAir
                ? s.toolsBeaconsOnAirNow
                : s.toolsBeaconsNextIn(formatMinSec(next)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Where a beacon stands, in the user's language.
String beaconPlace(S s, Beacon beacon) => switch (beacon.callsign) {
  '4U1UN' => s.toolsBeaconsPlace4u1un,
  'VE8AT' => s.toolsBeaconsPlaceVe8at,
  'W6WX' => s.toolsBeaconsPlaceW6wx,
  'KH6RS' => s.toolsBeaconsPlaceKh6rs,
  'ZL6B' => s.toolsBeaconsPlaceZl6b,
  'VK6RBP' => s.toolsBeaconsPlaceVk6rbp,
  'JA2IGY' => s.toolsBeaconsPlaceJa2igy,
  'RR9O' => s.toolsBeaconsPlaceRr9o,
  'VR2B' => s.toolsBeaconsPlaceVr2b,
  '4S7B' => s.toolsBeaconsPlace4s7b,
  'ZS6DN' => s.toolsBeaconsPlaceZs6dn,
  '5Z4B' => s.toolsBeaconsPlace5z4b,
  '4X6TU' => s.toolsBeaconsPlace4x6tu,
  'OH2B' => s.toolsBeaconsPlaceOh2b,
  'CS3B' => s.toolsBeaconsPlaceCs3b,
  'LU4AA' => s.toolsBeaconsPlaceLu4aa,
  'OA4B' => s.toolsBeaconsPlaceOa4b,
  'YV5B' => s.toolsBeaconsPlaceYv5b,
  _ => beacon.locator,
};

/// `123° · 8456 km`: short-path heading and distance from [from] to [to].
String formatPathTo(GeoPoint from, GeoPoint to) =>
    '${formatBearing(GreatCircle.initialBearing(from, to))} · '
    '${GreatCircle.distanceKm(from, to).round()} km';

/// `2:55`.
String formatMinSec(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
