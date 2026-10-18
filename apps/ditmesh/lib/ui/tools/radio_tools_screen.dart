import 'package:flutter/material.dart';

import '../../i18n/l10n_extension.dart';
import 'band_tool.dart';
import 'beacon_tool.dart';
import 'circuit_tool.dart';
import 'cw_speed_tool.dart';
import 'feedline_tool.dart';
import 'grid_locator_tool.dart';
import 'link_budget_tool.dart';
import 'matching_tool.dart';
import 'power_tool.dart';
import 'rst_tool.dart';
import 'sun_tool.dart';
import 'swr_tool.dart';
import 'tool_page.dart';
import 'utc_clock_tool.dart';

/// The radio tools, in menu order.
enum RadioTool {
  grid(Icons.grid_on),
  bands(Icons.cell_tower),
  power(Icons.bolt),
  swr(Icons.waves),
  feedline(Icons.cable),
  matching(Icons.tune),
  circuits(Icons.memory),
  link(Icons.settings_input_antenna),
  speed(Icons.speed),
  rst(Icons.signal_cellular_alt),
  sun(Icons.wb_twilight),
  beacons(Icons.podcasts),
  clock(Icons.schedule);

  const RadioTool(this.icon);

  final IconData icon;

  String title(S s) => switch (this) {
    RadioTool.grid => s.toolsGridTitle,
    RadioTool.bands => s.toolsBandsTitle,
    RadioTool.power => s.toolsPowerTitle,
    RadioTool.swr => s.toolsSwrTitle,
    RadioTool.feedline => s.toolsFeedlineTitle,
    RadioTool.matching => s.toolsMatchTitle,
    RadioTool.circuits => s.toolsCircuitTitle,
    RadioTool.link => s.toolsLinkTitle,
    RadioTool.speed => s.toolsSpeedTitle,
    RadioTool.rst => s.toolsRstTitle,
    RadioTool.sun => s.toolsSunTitle,
    RadioTool.beacons => s.toolsBeaconsTitle,
    RadioTool.clock => s.toolsClockTitle,
  };

  String hint(S s) => switch (this) {
    RadioTool.grid => s.toolsGridHint,
    RadioTool.bands => s.toolsBandsHint,
    RadioTool.power => s.toolsPowerHint,
    RadioTool.swr => s.toolsSwrHint,
    RadioTool.feedline => s.toolsFeedlineHint,
    RadioTool.matching => s.toolsMatchHint,
    RadioTool.circuits => s.toolsCircuitHint,
    RadioTool.link => s.toolsLinkHint,
    RadioTool.speed => s.toolsSpeedHint,
    RadioTool.rst => s.toolsRstHint,
    RadioTool.sun => s.toolsSunHint,
    RadioTool.beacons => s.toolsBeaconsHint,
    RadioTool.clock => s.toolsClockHint,
  };

  Widget build() => switch (this) {
    RadioTool.grid => const GridLocatorTool(),
    RadioTool.bands => const BandTool(),
    RadioTool.power => const PowerTool(),
    RadioTool.swr => const SwrTool(),
    RadioTool.feedline => const FeedlineTool(),
    RadioTool.matching => const MatchingTool(),
    RadioTool.circuits => const CircuitTool(),
    RadioTool.link => const LinkBudgetTool(),
    RadioTool.speed => const CwSpeedTool(),
    RadioTool.rst => const RstTool(),
    RadioTool.sun => const SunTool(),
    RadioTool.beacons => const BeaconTool(),
    RadioTool.clock => const UtcClockTool(),
  };

  /// Key of this tool's row in [RadioToolsScreen].
  Key get tileKey => Key('radio-tool-$name');
}

/// Offline helpers an operator reaches for next to the key: locator and
/// beam heading, band edges and antenna lengths, power and SWR, feedline
/// loss, L-network matching, LC / attenuator arithmetic, the link budget,
/// CW speed, RST, sunrise for the grey line, the NCDXF beacons, UTC.
///
/// A plain list on every form factor; each tool is its own route so the
/// back gesture / button behaves the same on phones and desktop.
class RadioToolsScreen extends StatelessWidget {
  const RadioToolsScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const RadioToolsScreen());

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ToolPage(
      title: s.toolsTitle,
      children: <Widget>[
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              for (final tool in RadioTool.values)
                ListTile(
                  key: tool.tileKey,
                  leading: Icon(tool.icon),
                  title: Text(tool.title(s)),
                  subtitle: Text(tool.hint(s)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => tool.build())),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
