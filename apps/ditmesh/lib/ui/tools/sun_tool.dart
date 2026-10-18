import 'package:flutter/material.dart';
import 'package:radio_tools/radio_tools.dart';

import '../../i18n/l10n_extension.dart';
import 'locator_field.dart';
import 'tool_page.dart';
import 'utc_clock_tool.dart';

/// Sunrise, solar noon and sunset in UTC for today at one or two locators,
/// so both ends of a grey-line path can be compared.
///
/// [now] is injectable so tests can pin the date.
class SunTool extends StatefulWidget {
  const SunTool({super.key, this.now = DateTime.now});

  final DateTime Function() now;

  static const Key mineKey = Key('sun-mine');
  static const Key theirsKey = Key('sun-theirs');

  @override
  State<SunTool> createState() => _SunToolState();
}

class _SunToolState extends State<SunTool> {
  final TextEditingController _mine = TextEditingController();
  final TextEditingController _theirs = TextEditingController();

  @override
  void dispose() {
    _mine.dispose();
    _theirs.dispose();
    super.dispose();
  }

  void _changed(String _) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final today = widget.now().toUtc();
    return ToolPage(
      title: s.toolsSunTitle,
      children: <Widget>[
        ToolSection(
          children: <Widget>[
            ResultRow(label: s.toolsSunDate, value: formatDate(today)),
            const SizedBox(height: 8),
            LocatorField(
              key: SunTool.mineKey,
              controller: _mine,
              label: s.toolsGridMine,
              onChanged: _changed,
            ),
            const SizedBox(height: 12),
            LocatorField(
              key: SunTool.theirsKey,
              controller: _theirs,
              label: s.toolsGridTheirs,
              onChanged: _changed,
            ),
          ],
        ),
        for (final controller in <TextEditingController>[_mine, _theirs])
          if (LocatorField.locatorOf(controller) case final locator?)
            ToolSection(
              title: Maidenhead.normalize(locator),
              children: _dayRows(
                s,
                SolarDay.compute(Maidenhead.toPoint(locator), today),
              ),
            ),
        Text(s.toolsSunNote, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  List<Widget> _dayRows(S s, SolarDay day) {
    final style = Theme.of(context).textTheme.bodyLarge;
    if (day.sunNeverSets) {
      return <Widget>[Text(s.toolsSunPolarDay, style: style)];
    }
    if (day.sunNeverRises) {
      return <Widget>[Text(s.toolsSunPolarNight, style: style)];
    }
    return <Widget>[
      ResultRow(
        label: s.toolsSunSunrise,
        value: '${formatHourMinute(day.sunrise!)}Z',
        emphasize: true,
      ),
      ResultRow(label: s.toolsSunNoon, value: '${formatHourMinute(day.noon)}Z'),
      ResultRow(
        label: s.toolsSunSunset,
        value: '${formatHourMinute(day.sunset!)}Z',
        emphasize: true,
      ),
      ResultRow(
        label: s.toolsSunDayLength,
        value: formatHoursMinutes(day.dayLength),
      ),
    ];
  }
}

String _two(int v) => v.toString().padLeft(2, '0');

/// `07:05`.
String formatHourMinute(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// `15 h 34 min`.
String formatHoursMinutes(Duration d) =>
    '${d.inHours} h ${_two(d.inMinutes % 60)} min';
