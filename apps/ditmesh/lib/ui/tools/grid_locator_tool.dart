import 'package:flutter/material.dart';
import 'package:radio_tools/radio_tools.dart';

import '../../i18n/l10n_extension.dart';
import 'tool_page.dart';

/// Maidenhead locator from coordinates, and distance / heading between two
/// locators (short and long path).
class GridLocatorTool extends StatefulWidget {
  const GridLocatorTool({super.key});

  static const Key latitudeKey = Key('grid-latitude');
  static const Key longitudeKey = Key('grid-longitude');
  static const Key mineKey = Key('grid-mine');
  static const Key theirsKey = Key('grid-theirs');

  @override
  State<GridLocatorTool> createState() => _GridLocatorToolState();
}

class _GridLocatorToolState extends State<GridLocatorTool> {
  final TextEditingController _lat = TextEditingController();
  final TextEditingController _lon = TextEditingController();
  final TextEditingController _mine = TextEditingController();
  final TextEditingController _theirs = TextEditingController();

  @override
  void dispose() {
    _lat.dispose();
    _lon.dispose();
    _mine.dispose();
    _theirs.dispose();
    super.dispose();
  }

  void _changed(String _) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ToolPage(
      title: s.toolsGridTitle,
      children: <Widget>[
        ToolSection(
          title: s.toolsGridFromCoordinates,
          children: <Widget>[..._coordinateFields(s), ..._locatorResult(s)],
        ),
        ToolSection(
          title: s.toolsGridDistanceSection,
          children: <Widget>[
            _locatorField(GridLocatorTool.mineKey, _mine, s.toolsGridMine, s),
            const SizedBox(height: 12),
            _locatorField(
              GridLocatorTool.theirsKey,
              _theirs,
              s.toolsGridTheirs,
              s,
            ),
            const SizedBox(height: 8),
            ..._distanceResult(s),
          ],
        ),
      ],
    );
  }

  List<Widget> _coordinateFields(S s) {
    const keyboard = TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    );
    return <Widget>[
      Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              key: GridLocatorTool.latitudeKey,
              controller: _lat,
              keyboardType: keyboard,
              textInputAction: TextInputAction.next,
              onChanged: _changed,
              decoration: InputDecoration(
                labelText: s.toolsGridLatitude,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: GridLocatorTool.longitudeKey,
              controller: _lon,
              keyboardType: keyboard,
              onChanged: _changed,
              decoration: InputDecoration(
                labelText: s.toolsGridLongitude,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: Text(
          s.toolsGridCoordinatesHelp,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ];
  }

  List<Widget> _locatorResult(S s) {
    final lat = parseDecimal(_lat.text);
    final lon = parseDecimal(_lon.text);
    if (lat == null || lon == null) {
      return const <Widget>[];
    }
    final point = GeoPoint(lat, lon);
    if (!point.isValid) {
      return <Widget>[_error(s.toolsGridInvalidCoordinates)];
    }
    return <Widget>[
      ResultRow(
        label: s.toolsGridLocator,
        value: Maidenhead.fromPoint(point, length: 8),
        emphasize: true,
      ),
    ];
  }

  Widget _locatorField(
    Key key,
    TextEditingController controller,
    String label,
    S s,
  ) {
    final text = controller.text.trim();
    final invalid = text.isNotEmpty && !Maidenhead.isValid(text);
    return TextField(
      key: key,
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: _changed,
      decoration: InputDecoration(
        labelText: label,
        // ui-literal-ok: Maidenhead locator example, identical in every locale
        hintText: 'OM89ex',
        errorText: invalid ? s.toolsGridInvalidLocator : null,
        border: const OutlineInputBorder(),
      ),
    );
  }

  List<Widget> _distanceResult(S s) {
    final mine = _mine.text.trim();
    final theirs = _theirs.text.trim();
    final rows = <Widget>[];
    if (Maidenhead.isValid(mine)) {
      final c = Maidenhead.toPoint(mine);
      rows.add(ResultRow(label: s.toolsGridCenter, value: formatPoint(c)));
    }
    if (!Maidenhead.isValid(mine) || !Maidenhead.isValid(theirs)) {
      return rows;
    }
    final a = Maidenhead.toPoint(mine);
    final b = Maidenhead.toPoint(theirs);
    final km = GreatCircle.distanceKm(a, b);
    return <Widget>[
      ...rows,
      ResultRow(
        label: s.toolsGridDistance,
        value:
            '${km.round()} km · '
            '${(km / GreatCircle.kmPerMile).round()} mi',
        emphasize: true,
      ),
      ResultRow(
        label: s.toolsGridShortPath,
        value: formatBearing(GreatCircle.initialBearing(a, b)),
      ),
      ResultRow(
        label: s.toolsGridLongPath,
        value: formatBearing(GreatCircle.longPathBearing(a, b)),
      ),
    ];
  }

  Widget _error(String text) =>
      Text(text, style: TextStyle(color: Theme.of(context).colorScheme.error));
}

/// `48.146°N 11.608°E`.
String formatPoint(GeoPoint p) {
  final ns = p.latitude >= 0 ? 'N' : 'S';
  final ew = p.longitude >= 0 ? 'E' : 'W';
  return '${p.latitude.abs().toStringAsFixed(3)}°$ns '
      '${p.longitude.abs().toStringAsFixed(3)}°$ew';
}

/// Whole degrees, `0°`..`359°` (360 rounds back to 0).
String formatBearing(double degrees) => '${degrees.round() % 360}°';
