import 'package:flutter/material.dart';

import '../../i18n/l10n_extension.dart';
import 'band_tool.dart';
import 'cw_speed_tool.dart';
import 'grid_locator_tool.dart';
import 'rst_tool.dart';
import 'tool_page.dart';
import 'utc_clock_tool.dart';

/// The radio tools, in menu order.
enum RadioTool {
  grid(Icons.grid_on),
  bands(Icons.cell_tower),
  speed(Icons.speed),
  rst(Icons.signal_cellular_alt),
  clock(Icons.schedule);

  const RadioTool(this.icon);

  final IconData icon;

  String title(S s) => switch (this) {
    RadioTool.grid => s.toolsGridTitle,
    RadioTool.bands => s.toolsBandsTitle,
    RadioTool.speed => s.toolsSpeedTitle,
    RadioTool.rst => s.toolsRstTitle,
    RadioTool.clock => s.toolsClockTitle,
  };

  String hint(S s) => switch (this) {
    RadioTool.grid => s.toolsGridHint,
    RadioTool.bands => s.toolsBandsHint,
    RadioTool.speed => s.toolsSpeedHint,
    RadioTool.rst => s.toolsRstHint,
    RadioTool.clock => s.toolsClockHint,
  };

  Widget build() => switch (this) {
    RadioTool.grid => const GridLocatorTool(),
    RadioTool.bands => const BandTool(),
    RadioTool.speed => const CwSpeedTool(),
    RadioTool.rst => const RstTool(),
    RadioTool.clock => const UtcClockTool(),
  };

  /// Key of this tool's row in [RadioToolsScreen].
  Key get tileKey => Key('radio-tool-$name');
}

/// Offline helpers an operator reaches for next to the key: locator and
/// beam heading, band edges and antenna lengths, CW speed, RST, UTC.
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
