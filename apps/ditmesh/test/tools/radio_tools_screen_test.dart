import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_tools/radio_tools.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/reference/reference_screen.dart';
import 'package:ditmesh/ui/tools/band_tool.dart';
import 'package:ditmesh/ui/tools/beacon_tool.dart';
import 'package:ditmesh/ui/tools/cw_speed_tool.dart';
import 'package:ditmesh/ui/tools/grid_locator_tool.dart';
import 'package:ditmesh/ui/tools/power_tool.dart';
import 'package:ditmesh/ui/tools/radio_tools_screen.dart';
import 'package:ditmesh/ui/tools/rst_tool.dart';
import 'package:ditmesh/ui/tools/sun_tool.dart';
import 'package:ditmesh/ui/tools/swr_tool.dart';
import 'package:ditmesh/ui/tools/utc_clock_tool.dart';

import '../reference/reference_test_support.dart';

const Size _smallPhone = Size(360, 640);

final S en = kTestStrings;

Future<void> _pumpIn(
  WidgetTester tester,
  Widget home, {
  Size size = _smallPhone,
  Locale locale = kTestLocale,
}) async {
  setSurfaceSize(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: locale,
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, Key key, String text) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.enterText(find.byKey(key), text);
  await tester.pumpAndSettle();
}

void main() {
  group('RadioToolsScreen', () {
    for (final size in <Size>[_smallPhone, kDesktop]) {
      for (final locale in S.supportedLocales) {
        testWidgets('every tool opens cleanly at $size in $locale', (
          tester,
        ) async {
          await _pumpIn(
            tester,
            const RadioToolsScreen(),
            size: size,
            locale: locale,
          );
          for (final tool in RadioTool.values) {
            await tester.ensureVisible(find.byKey(tool.tileKey));
            await tester.tap(find.byKey(tool.tileKey));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: tool.name);
            expect(
              find.widgetWithText(AppBar, tool.title(lookupS(locale))),
              findsOneWidget,
            );
            await tester.tap(find.byType(BackButton));
            await tester.pumpAndSettle();
          }
        });
      }
    }

    testWidgets('the reference app bar opens the tools', (tester) async {
      final fake = FakeReferencePlayer();
      setSurfaceSize(tester, _smallPhone);
      await pumpScreen(tester, ReferenceScreen(playerFactory: fake.create));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(ReferenceScreen.radioToolsKey));
      await tester.pumpAndSettle();
      expect(find.byType(RadioToolsScreen), findsOneWidget);
      expect(find.text(en.toolsGridTitle), findsOneWidget);
    });
  });

  group('GridLocatorTool', () {
    testWidgets('coordinates give a locator; bad ones an error', (
      tester,
    ) async {
      await _pumpIn(tester, const GridLocatorTool());
      await _enter(tester, GridLocatorTool.latitudeKey, '48.14666');
      await _enter(tester, GridLocatorTool.longitudeKey, '11,60833');
      expect(find.textContaining('JN58td'), findsOneWidget);
      await _enter(tester, GridLocatorTool.latitudeKey, '95');
      expect(find.text(en.toolsGridInvalidCoordinates), findsOneWidget);
    });

    testWidgets('two locators give distance and headings', (tester) async {
      await _pumpIn(tester, const GridLocatorTool());
      await _enter(tester, GridLocatorTool.mineKey, 'jn58td');
      expect(find.text(en.toolsGridCenter), findsOneWidget);
      await _enter(tester, GridLocatorTool.theirsKey, 'JN5');
      expect(find.text(en.toolsGridInvalidLocator), findsOneWidget);
      await _enter(tester, GridLocatorTool.theirsKey, 'JN58');
      expect(find.text(en.toolsGridInvalidLocator), findsNothing);
      expect(find.text(en.toolsGridDistance), findsOneWidget);
      expect(find.text(en.toolsGridShortPath), findsOneWidget);
      expect(find.text(en.toolsGridLongPath), findsOneWidget);
    });

    test('formatting helpers', () {
      expect(formatBearing(359.6), '0°');
      expect(formatBearing(90.4), '90°');
    });
  });

  group('BandTool', () {
    testWidgets('band membership follows the region', (tester) async {
      await _pumpIn(tester, const BandTool());
      await _enter(tester, BandTool.frequencyKey, '7.25');
      expect(find.text(en.toolsBandsOutOfBand), findsOneWidget);
      await tester.ensureVisible(find.text(en.toolsBandsRegionLabel(2)));
      await tester.tap(find.text(en.toolsBandsRegionLabel(2)));
      await tester.pumpAndSettle();
      expect(find.text(en.toolsBandsInBand('40m')), findsOneWidget);
      expect(find.text(en.toolsBandsWavelength), findsOneWidget);
      await _enter(tester, BandTool.frequencyKey, '-1');
      expect(find.text(en.toolsBandsInvalidFrequency), findsOneWidget);
    });

    test('formatting helpers', () {
      expect(formatMhz(7.0), '7.0');
      expect(formatMhz(5.3515), '5.3515');
      expect(formatMhz(14.35), '14.35');
      expect(formatMetres(20.3434), '20.34 m');
      expect(formatMetres(2209.4), '2209 m');
    });
  });

  testWidgets('CwSpeedTool shows PARIS timing at 20 WPM', (tester) async {
    await _pumpIn(tester, const CwSpeedTool());
    expect(find.text('60 ms'), findsOneWidget);
    expect(find.text('180 ms'), findsNWidgets(2)); // dah and character gap
    expect(find.text('420 ms'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    await tester.tap(find.text(en.toolsSpeedFarnsworth));
    await tester.pumpAndSettle();
    expect(find.text(en.toolsSpeedOverall), findsOneWidget);
    expect(find.text('50'), findsOneWidget); // 10 WPM overall
  });

  testWidgets('RstTool composes the report from the chips', (tester) async {
    await _pumpIn(tester, const RstTool());
    expect(find.text('599'), findsOneWidget);
    expect(find.text('5NN'), findsOneWidget);
    final strength7 = find.descendant(
      of: find.ancestor(
        of: find.text(en.toolsRstStrength),
        matching: find.byType(Card),
      ),
      matching: find.widgetWithText(ChoiceChip, '7'),
    );
    await tester.ensureVisible(strength7);
    await tester.tap(strength7);
    await tester.pumpAndSettle();
    expect(find.text('579'), findsOneWidget);
    expect(find.text('57'), findsOneWidget);
    expect(find.text(en.toolsRstS7), findsOneWidget);
  });

  group('UtcClockTool', () {
    testWidgets('shows UTC from the injected clock', (tester) async {
      final now = DateTime.utc(2026, 10, 2, 7, 5, 9);
      await _pumpIn(tester, UtcClockTool(now: () => now));
      expect(find.text('07:05:09Z'), findsOneWidget);
      expect(find.text('2026-10-02'), findsWidgets);
    });

    test('offset formatting', () {
      expect(formatOffset(const Duration(hours: 8)), 'UTC+8');
      expect(formatOffset(const Duration(hours: -3, minutes: -30)), 'UTC-3:30');
      expect(formatOffset(Duration.zero), 'UTC+0');
    });
  });

  group('PowerTool', () {
    testWidgets('watts give dBm and S-meter readings', (tester) async {
      await _pumpIn(tester, const PowerTool());
      await _enter(tester, PowerTool.valueKey, '100');
      expect(find.text('100 W'), findsOneWidget);
      expect(find.text('50.0 dBm · 20.0 dBW'), findsOneWidget);
      expect(find.text('S9+123'), findsOneWidget);
      expect(find.text('S9+143'), findsOneWidget);
      await tester.ensureVisible(find.text(PowerUnit.dbm.symbol));
      await tester.tap(find.text(PowerUnit.dbm.symbol));
      await tester.pumpAndSettle();
      await _enter(tester, PowerTool.valueKey, '-79');
      expect(find.text('S8'), findsOneWidget); // HF
      expect(find.text('S9+14'), findsOneWidget); // VHF
      expect(find.text('12.6 pW'), findsOneWidget);
      await tester.ensureVisible(find.text(PowerUnit.watts.symbol));
      await tester.tap(find.text(PowerUnit.watts.symbol));
      await tester.pumpAndSettle();
      await _enter(tester, PowerTool.valueKey, '0');
      expect(find.text(en.toolsPowerInvalid), findsOneWidget);
    });

    testWidgets('decibels give ratios', (tester) async {
      await _pumpIn(tester, const PowerTool());
      await _enter(tester, PowerTool.dbKey, '10');
      expect(find.text('× 10.0'), findsOneWidget);
      expect(find.text('× 3.16'), findsOneWidget);
      expect(find.text('1.7'), findsOneWidget); // S-units
    });

    test('formatting helpers', () {
      expect(formatWatts(1500), '1.50 kW');
      expect(formatWatts(100), '100 W');
      expect(formatWatts(5), '5.00 W');
      expect(formatWatts(0.005), '5.00 mW');
      expect(formatWatts(1e-7), '100 nW');
      expect(formatWatts(2.5e-7), '250 nW');
      expect(formatWatts(1e-13), '0.10 pW');
      expect(formatRatio(1e6), '1000000');
      expect(formatRatio(2), '2.00');
    });
  });

  group('SwrTool', () {
    testWidgets('power readings give SWR, impedance too', (tester) async {
      await _pumpIn(tester, const SwrTool());
      await _enter(tester, SwrTool.forwardKey, '100');
      await _enter(tester, SwrTool.reflectedKey, '4');
      expect(find.text('1.50:1'), findsOneWidget);
      expect(find.text('14.0 dB'), findsOneWidget);
      expect(find.text('4.0 %'), findsOneWidget);
      expect(find.text('0.18 dB'), findsOneWidget);
      await _enter(tester, SwrTool.reflectedKey, '101');
      expect(find.text(en.toolsSwrInvalidPower), findsOneWidget);
      await _enter(tester, SwrTool.resistanceKey, '100');
      expect(find.text('2.00:1'), findsOneWidget);
      await _enter(tester, SwrTool.referenceKey, '0');
      expect(find.text(en.toolsSwrInvalidImpedance), findsOneWidget);
    });

    test('formatting helpers', () {
      expect(formatSwr(1.5), '1.50:1');
      expect(formatSwr(double.infinity), '∞');
      expect(formatDb(double.infinity), '∞ dB');
      expect(formatDb(13.979), '14.0 dB');
    });
  });

  group('SunTool', () {
    testWidgets('a locator gives sunrise and sunset; polar day is named', (
      tester,
    ) async {
      final now = DateTime.utc(2026, 6, 21, 15);
      await _pumpIn(tester, SunTool(now: () => now));
      expect(find.text('2026-06-21'), findsOneWidget);
      await _enter(tester, SunTool.mineKey, 'jn58td');
      expect(find.text('JN58td'), findsOneWidget);
      final day = SolarDay.compute(Maidenhead.toPoint('JN58td'), now);
      expect(find.text('${formatHourMinute(day.sunrise!)}Z'), findsOneWidget);
      expect(find.text('${formatHourMinute(day.sunset!)}Z'), findsOneWidget);
      expect(day.sunrise!.hour, 3); // 05:13 CEST
      expect(day.sunset!.hour, 19); // 21:17 CEST
      expect(find.text(en.toolsSunDayLength), findsOneWidget);
      await _enter(tester, SunTool.theirsKey, 'JQ78'); // Svalbard
      expect(find.text(en.toolsSunPolarDay), findsOneWidget);
      await _enter(tester, SunTool.theirsKey, 'JQ7');
      expect(find.text(en.toolsGridInvalidLocator), findsOneWidget);
      expect(find.text(en.toolsSunPolarDay), findsNothing);
    });

    test('formatting helpers', () {
      expect(formatHourMinute(DateTime.utc(2026, 1, 1, 7, 5)), '07:05');
      expect(
        formatHoursMinutes(const Duration(hours: 15, minutes: 4)),
        '15 h 04 min',
      );
    });
  });

  group('BeaconTool', () {
    testWidgets('shows the beacon on each band and the path to it', (
      tester,
    ) async {
      // 12:00:05 UTC: slot 0, 4U1UN on 14.100, five seconds left.
      final now = DateTime.utc(2026, 10, 17, 12, 0, 5);
      await _pumpIn(tester, BeaconTool(now: () => now), size: kDesktop);
      expect(find.text('12:00:05Z'), findsOneWidget);
      expect(find.text('5 s'), findsOneWidget);
      expect(find.text('4U1UN'), findsNWidgets(2)); // on air + schedule
      expect(find.text(en.toolsBeaconsPlace4u1un), findsNWidgets(2));
      expect(find.text(en.toolsBeaconsOnAirNow), findsOneWidget);
      expect(find.text(en.toolsBeaconsNextIn('0:05')), findsOneWidget); // VE8AT
      await _enter(tester, BeaconTool.mineKey, 'JN58td');
      final path = formatPathTo(
        Maidenhead.toPoint('JN58td'),
        Maidenhead.toPoint('FN30as'),
      );
      expect(path, matches(RegExp(r'^\d+° · 6\d\d\d km$'))); // ~6500 km
      expect(find.text(path), findsOneWidget);
    });

    test('formatting helpers', () {
      expect(formatMinSec(const Duration(minutes: 2, seconds: 5)), '2:05');
      expect(formatMinSec(Duration.zero), '0:00');
      expect(
        formatPathTo(const GeoPoint(0, 0), const GeoPoint(0, 10)),
        '90° · 1112 km',
      );
    });
  });
}
