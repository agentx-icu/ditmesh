import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/tools/circuit_tool.dart';
import 'package:ditmesh/ui/tools/feedline_tool.dart';
import 'package:ditmesh/ui/tools/link_budget_tool.dart';
import 'package:ditmesh/ui/tools/matching_tool.dart';
import 'package:ditmesh/ui/tools/si_format.dart';
import 'package:ditmesh/ui/tools/swr_tool.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_tools/radio_tools.dart';

import '../reference/reference_test_support.dart';

const Size _smallPhone = Size(360, 640);

final S en = kTestStrings;

Future<void> _pumpIn(WidgetTester tester, Widget home) async {
  setSurfaceSize(tester, _smallPhone);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: kTestLocale,
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
  group('formatEngineering', () {
    test('picks the prefix and keeps three significant digits', () {
      expect(formatEngineering(5.033e6, 'Hz'), '5.03 MHz');
      expect(formatEngineering(4.483e-10, 'F'), '448 pF');
      expect(formatEngineering(5.604e-7, 'H'), '560 nH');
      expect(formatEngineering(1.2e-5, 'H'), '12.0 µH');
      expect(formatOhms(17.6), '17.6 Ω');
      expect(formatOhms(292.4), '292 Ω');
      expect(formatOhms(1500), '1.50 kΩ');
      expect(formatOhms(999.6), '1.00 kΩ');
      expect(formatOhms(-50), '-50.0 Ω');
      expect(formatEngineering(0, 'F'), '0 F');
      expect(formatEngineering(3.84e-6, 'V'), '3.84 µV');
      expect(formatKm(41.2), '41.2 km');
      expect(formatKm(150.4), '150 km');
    });
  });

  group('FeedlineTool', () {
    final rg213 = Feedlines.catalogue.singleWhere((c) => c.name == 'RG-213');

    testWidgets('matched run shows loss, power and stub lengths', (
      tester,
    ) async {
      await _pumpIn(tester, const FeedlineTool());
      expect(find.text('RG-213'), findsOneWidget);
      await _enter(tester, FeedlineTool.lengthKey, '30');
      await _enter(tester, FeedlineTool.frequencyKey, '144');
      final run = FeedlineRun(cable: rg213, lengthM: 30, mhz: 144);
      expect(
        find.text(formatDb(run.matchedLossDb, decimals: 2)),
        findsOneWidget,
      );
      expect(find.text(en.toolsFeedlineTotalLoss), findsNothing);
      expect(find.text(en.toolsFeedlinePowerAtAntenna), findsOneWidget);
      expect(find.text('90° · 0.25 λ'), findsNothing);
      expect(find.text(en.toolsFeedlineQuarterWave), findsOneWidget);
      final quarter = rg213.wavelengthM(144) / 4;
      expect(find.text('${quarter.toStringAsFixed(2)} m'), findsOneWidget);
    });

    testWidgets('an SWR above 1 adds the mismatch rows', (tester) async {
      await _pumpIn(tester, const FeedlineTool());
      await _enter(tester, FeedlineTool.lengthKey, '30');
      await _enter(tester, FeedlineTool.frequencyKey, '144');
      await _enter(tester, FeedlineTool.swrKey, '3');
      final run = FeedlineRun(
        cable: rg213,
        lengthM: 30,
        mhz: 144,
        swrAtLoad: 3,
      );
      expect(find.text(formatDb(run.totalLossDb, decimals: 2)), findsOneWidget);
      expect(find.text(formatSwr(run.swrAtInput)), findsOneWidget);
    });

    testWidgets('impossible values show one error', (tester) async {
      await _pumpIn(tester, const FeedlineTool());
      await _enter(tester, FeedlineTool.lengthKey, '-1');
      expect(find.text(en.toolsFeedlineInvalid), findsOneWidget);
      await _enter(tester, FeedlineTool.lengthKey, '10');
      await _enter(tester, FeedlineTool.swrKey, '0.5');
      expect(find.text(en.toolsFeedlineInvalid), findsOneWidget);
    });
  });

  group('LinkBudgetTool', () {
    testWidgets('horizons and line of sight', (tester) async {
      await _pumpIn(tester, const LinkBudgetTool());
      await _enter(tester, LinkBudgetTool.heightAKey, '100');
      expect(find.text('41.2 km'), findsOneWidget);
      expect(find.text(en.toolsLinkLineOfSight), findsNothing);
      await _enter(tester, LinkBudgetTool.heightBKey, '25');
      expect(find.text('20.6 km'), findsOneWidget);
      expect(find.text('61.8 km'), findsOneWidget);
      await _enter(tester, LinkBudgetTool.heightBKey, '-5');
      expect(find.text(en.toolsLinkInvalidHeight), findsOneWidget);
    });

    testWidgets('path budget with empty gains, then beyond the horizon', (
      tester,
    ) async {
      await _pumpIn(tester, const LinkBudgetTool());
      await _enter(tester, LinkBudgetTool.powerKey, '5');
      await _enter(tester, LinkBudgetTool.frequencyKey, '144');
      await _enter(tester, LinkBudgetTool.distanceKey, '50');
      final link = LinkBudget(
        txDbm: Decibels.wattsToDbm(5),
        distanceKm: 50,
        mhz: 144,
      );
      expect(
        find.text('${link.receivedDbm.toStringAsFixed(1)} dBm'),
        findsOneWidget,
      );
      expect(find.text(formatDb(link.pathLossDb)), findsOneWidget);
      expect(
        find.text(SMeterReading.fromDbm(link.receivedDbm, vhf: true).label),
        findsOneWidget,
      );
      expect(find.text(en.toolsLinkBeyondHorizon), findsNothing);
      await _enter(tester, LinkBudgetTool.heightAKey, '10');
      await _enter(tester, LinkBudgetTool.heightBKey, '2');
      await tester.ensureVisible(find.text(en.toolsLinkSMeter));
      expect(find.text(en.toolsLinkBeyondHorizon), findsOneWidget);
      await _enter(tester, LinkBudgetTool.txGainKey, 'abc');
      expect(find.text(en.toolsLinkInvalid), findsOneWidget);
      await _enter(tester, LinkBudgetTool.txGainKey, '');
      expect(find.text(en.toolsLinkInvalid), findsNothing);
      // A feedline cannot have negative loss.
      await _enter(tester, LinkBudgetTool.txLossKey, '-10');
      expect(find.text(en.toolsLinkInvalid), findsOneWidget);
    });
  });

  group('CircuitTool', () {
    testWidgets('two of f, L, C give the third', (tester) async {
      await _pumpIn(tester, const CircuitTool());
      await _enter(tester, CircuitTool.inductanceKey, '10');
      expect(find.text(en.toolsCircuitResonantFrequency), findsNothing);
      await _enter(tester, CircuitTool.capacitanceKey, '100');
      expect(find.text('5.03 MHz'), findsOneWidget);
      expect(find.text('316 Ω'), findsNWidgets(2));
      await _enter(tester, CircuitTool.capacitanceKey, '');
      await _enter(tester, CircuitTool.frequencyKey, '7.1');
      final c = Resonance.capacitanceF(frequencyHz: 7.1e6, inductanceH: 10e-6);
      expect(find.text(formatEngineering(c, 'F')), findsOneWidget);
      await _enter(tester, CircuitTool.frequencyKey, '-1');
      expect(find.text(en.toolsCircuitInvalid), findsOneWidget);
    });

    testWidgets('all three given: resonance of L and C, reactances at f', (
      tester,
    ) async {
      await _pumpIn(tester, const CircuitTool());
      await _enter(tester, CircuitTool.inductanceKey, '10');
      await _enter(tester, CircuitTool.capacitanceKey, '100');
      expect(
        find.text(en.toolsCircuitInductiveReactanceAt('5.03 MHz')),
        findsOneWidget,
      );
      await _enter(tester, CircuitTool.frequencyKey, '7.1');
      expect(find.text('5.03 MHz'), findsOneWidget);
      expect(
        find.text(en.toolsCircuitInductiveReactanceAt('7.10 MHz')),
        findsOneWidget,
      );
      expect(
        find.text(en.toolsCircuitCapacitiveReactanceAt('7.10 MHz')),
        findsOneWidget,
      );
      expect(find.text('446 Ω'), findsOneWidget);
      expect(find.text('224 Ω'), findsOneWidget);
    });

    testWidgets('attenuator and pad', (tester) async {
      await _pumpIn(tester, const CircuitTool());
      await _enter(tester, CircuitTool.attenuationKey, '3');
      expect(find.text('17.6 Ω'), findsOneWidget);
      expect(find.text('292 Ω'), findsOneWidget);
      expect(find.text('8.55 Ω'), findsOneWidget);
      expect(find.text('142 Ω'), findsOneWidget);
      await _enter(tester, CircuitTool.padHighKey, '75');
      await _enter(tester, CircuitTool.padLowKey, '50');
      expect(find.text('43.3 Ω'), findsOneWidget);
      expect(find.text('86.6 Ω'), findsOneWidget);
      expect(find.text('5.72 dB'), findsOneWidget);
      await _enter(tester, CircuitTool.padLowKey, '75');
      expect(find.text(en.toolsCircuitPadInvalid), findsOneWidget);
    });
  });

  group('MatchingTool', () {
    testWidgets('25 Ω at 7.1 MHz gives the two classic networks', (
      tester,
    ) async {
      await _pumpIn(tester, const MatchingTool());
      await _enter(tester, MatchingTool.frequencyKey, '7.1');
      await _enter(tester, MatchingTool.resistanceKey, '25');
      expect(find.text('2.00:1'), findsOneWidget);
      expect(
        find.text(en.toolsMatchSolution(1, en.toolsMatchLowPass)),
        findsOneWidget,
      );
      expect(
        find.text(en.toolsMatchSolution(2, en.toolsMatchHighPass)),
        findsOneWidget,
      );
      expect(find.text('L 560 nH · 25.0 Ω'), findsOneWidget);
      expect(find.text('C 448 pF · 50.0 Ω'), findsOneWidget);
      expect(find.text(en.toolsMatchSeriesAtAntenna), findsNWidgets(2));
      expect(find.text(en.toolsMatchShuntAcrossRadio), findsNWidgets(2));
    });

    testWidgets('100 Ω puts the shunt element on the antenna side', (
      tester,
    ) async {
      await _pumpIn(tester, const MatchingTool());
      await _enter(tester, MatchingTool.frequencyKey, '7.1');
      await _enter(tester, MatchingTool.resistanceKey, '100');
      expect(find.text(en.toolsMatchShuntAcrossAntenna), findsNWidgets(2));
      expect(find.text(en.toolsMatchSeriesAtRadio), findsNWidgets(2));
      expect(find.text(en.toolsMatchSeriesAtAntenna), findsNothing);
      // Q = 1 again: shunt 100 Ω, series 50 Ω.
      expect(find.text('C 224 pF · 100 Ω'), findsOneWidget);
      expect(find.text('L 1.12 µH · 50.0 Ω'), findsOneWidget);
    });

    testWidgets('matched load, bare reactance and bad input', (tester) async {
      await _pumpIn(tester, const MatchingTool());
      await _enter(tester, MatchingTool.frequencyKey, '14.2');
      await _enter(tester, MatchingTool.resistanceKey, '50');
      expect(find.text(en.toolsMatchAlreadyMatched), findsOneWidget);
      await _enter(tester, MatchingTool.reactanceKey, '30');
      expect(find.text(en.toolsMatchAlreadyMatched), findsNothing);
      expect(find.text(en.toolsMatchNoElement), findsOneWidget);
      await _enter(tester, MatchingTool.resistanceKey, '0');
      expect(find.text(en.toolsMatchInvalid), findsOneWidget);
    });

    test('describeElement', () {
      expect(describeElement(en, null), en.toolsMatchNoElement);
      final coil = ReactiveElement.fromReactance(25, 7.1e6);
      expect(describeElement(en, coil), 'L 560 nH · 25.0 Ω');
    });
  });
}
