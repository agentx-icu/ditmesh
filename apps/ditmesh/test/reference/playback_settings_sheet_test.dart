import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/reference/playback_settings_sheet.dart';
import 'package:ditmesh/ui/reference/reference_playback_settings.dart';

import '../learn/helpers/l10n.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<ReferencePlaybackSettings> _pump(WidgetTester tester) async {
  _phone(tester);
  final ReferencePlaybackSettings settings = ReferencePlaybackSettings();
  addTearDown(settings.dispose);
  await tester.pumpWidget(
    l10nApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ReferencePlaybackSettingsSheet(settings: settings),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return settings;
}

Slider _slider(WidgetTester tester, int index) =>
    tester.widget<Slider>(find.byType(Slider).at(index));

void main() {
  testWidgets('shows speed and tone with their current values', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text(en.referencePlaybackSettings), findsOneWidget);
    expect(find.text(en.referenceCharacterSpeed), findsOneWidget);
    expect(find.text(en.referenceTone), findsOneWidget);
    expect(find.text(en.referenceWpmValue('15')), findsOneWidget);
    expect(find.text(en.referenceHzValue('700')), findsOneWidget);
    // Farnsworth is off: only the two sliders.
    expect(find.byType(Slider), findsNWidgets(2));
    expect(find.text(en.referenceEffectiveSpeed), findsNothing);
    expect(_slider(tester, 0).divisions, 35);
    expect(_slider(tester, 1).divisions, 24);
  });

  testWidgets('the speed slider writes through and the label follows', (
    tester,
  ) async {
    final ReferencePlaybackSettings settings = await _pump(tester);
    _slider(tester, 0).onChanged!(25);
    await tester.pump();
    expect(settings.wpm, 25);
    expect(find.text(en.referenceWpmValue('25')), findsOneWidget);
    expect(find.text(en.referenceWpmValue('15')), findsNothing);
  });

  testWidgets('the tone slider writes through and the label follows', (
    tester,
  ) async {
    final ReferencePlaybackSettings settings = await _pump(tester);
    _slider(tester, 1).onChanged!(800);
    await tester.pump();
    expect(settings.toneHz, 800);
    expect(find.text(en.referenceHzValue('800')), findsOneWidget);
  });

  testWidgets('enabling Farnsworth reveals the effective-speed slider', (
    tester,
  ) async {
    final ReferencePlaybackSettings settings = await _pump(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(settings.farnsworthEnabled, isTrue);
    expect(find.text(en.referenceEffectiveSpeed), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(3));
    // The effective slider is capped at the character speed.
    final Slider effective = _slider(tester, 1);
    expect(effective.max, settings.wpm);
    expect(effective.value, settings.farnsworthWpm);
    effective.onChanged!(8);
    await tester.pump();
    expect(settings.farnsworthWpm, 8);
    expect(find.text(en.referenceWpmValue('8')), findsOneWidget);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(settings.farnsworthEnabled, isFalse);
    expect(find.byType(Slider), findsNWidgets(2));
  });

  testWidgets('a lower character speed drags the effective speed down', (
    tester,
  ) async {
    final ReferencePlaybackSettings settings = await _pump(tester);
    settings
      ..setFarnsworthEnabled(true)
      ..farnsworthWpm = 14;
    await tester.pump();
    _slider(tester, 0).onChanged!(10);
    await tester.pump();
    expect(settings.farnsworthWpm, 10);
    expect(_slider(tester, 1).max, 10);
    expect(_slider(tester, 1).divisions, greaterThanOrEqualTo(1));
  });

  testWidgets('showReferencePlaybackSettings opens the sheet', (tester) async {
    _phone(tester);
    final ReferencePlaybackSettings settings = ReferencePlaybackSettings();
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      l10nApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showReferencePlaybackSettings(context, settings),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(ReferencePlaybackSettingsSheet), findsOneWidget);
    expect(find.text(en.referencePlaybackSettings), findsOneWidget);
  });
}
