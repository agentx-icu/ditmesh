import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/reference/reference_screen.dart';
import 'package:ditmesh/ui/tools/band_tool.dart';
import 'package:ditmesh/ui/tools/cw_speed_tool.dart';
import 'package:ditmesh/ui/tools/grid_locator_tool.dart';
import 'package:ditmesh/ui/tools/radio_tools_screen.dart';
import 'package:ditmesh/ui/tools/rst_tool.dart';
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
}
