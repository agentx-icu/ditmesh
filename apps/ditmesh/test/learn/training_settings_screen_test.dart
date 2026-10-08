import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/ui/learn/settings/training_settings_screen.dart';

import 'helpers/fake_playback.dart';
import 'helpers/l10n.dart';
import 'helpers/test_controller.dart';

Future<(TestTraining, FakeLearnPlaybackFactory)> _pump(
  WidgetTester tester, {
  TrainingSettings? settings,
  // Tall enough that every tile is on screen without scrolling.
  Size size = const Size(390, 1600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final t = await TestTraining.create(settings: settings);
  addTearDown(t.controller.dispose);
  final playback = FakeLearnPlaybackFactory();
  await tester.pumpWidget(
    l10nApp(
      home: TrainingSettingsScreen(
        controller: t.controller,
        playback: playback,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (t, playback);
}

Finder _switchFor(String title) => find.ancestor(
  of: find.text(title),
  matching: find.byType(SwitchListTile),
);

void main() {
  testWidgets('shows the current values', (tester) async {
    await _pump(tester);
    expect(find.text(en.learnWpmValue('20')), findsOneWidget);
    expect(find.text(en.learnHzValue('700')), findsOneWidget);
    expect(find.text(en.learnCharsCount(50)), findsOneWidget);
    expect(find.text(en.learnCharsCount(100)), findsOneWidget);
    // Defaults have Farnsworth 8 wpm on.
    expect(find.text(en.learnWpmValue('8')), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(_switchFor(en.learnFarnsworth)).value,
      isTrue,
    );
  });

  testWidgets('toggling Farnsworth off persists and hides its slider', (
    tester,
  ) async {
    final (t, _) = await _pump(tester);
    await tester.tap(_switchFor(en.learnFarnsworth));
    await tester.pumpAndSettle();
    expect(t.controller.settings.trainer.farnsworthWpm, isNull);
    expect(t.controller.settings.trainer.isFarnsworth, isFalse);
    expect(t.settingsStore.saveCount, 1);
    expect(find.text(en.learnEffectiveSpeed), findsNothing);

    await tester.tap(_switchFor(en.learnFarnsworth));
    await tester.pumpAndSettle();
    expect(t.controller.settings.trainer.farnsworthWpm, 8);
    expect(find.text(en.learnEffectiveSpeed), findsOneWidget);
    expect(await t.settingsStore.load(), t.controller.settings);
  });

  testWidgets('dragging the speed slider persists once on release', (
    tester,
  ) async {
    final (t, _) = await _pump(tester);
    final slider = find.byType(Slider).first;
    final rect = tester.getRect(slider);
    // Drag from the current position (20 of 10..40 = 1/3) to the far right.
    final start = Offset(rect.left + rect.width / 3, rect.center.dy);
    final gesture = await tester.startGesture(start);
    await gesture.moveTo(Offset(rect.right + 20, rect.center.dy));
    await tester.pump();
    // Draft follows the drag; nothing is persisted yet.
    expect(t.settingsStore.saveCount, 0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(t.controller.settings.trainer.characterWpm, 40);
    expect(t.settingsStore.saveCount, 1);
    expect(find.text(en.learnWpmValue('40')), findsOneWidget);
  });

  testWidgets('lowering character speed clamps Farnsworth below it', (
    tester,
  ) async {
    final (t, _) = await _pump(
      tester,
      settings: const TrainingSettings(
        trainer: TrainerSettings(characterWpm: 30, farnsworthWpm: 25),
      ),
    );
    final slider = find.byType(Slider).first;
    final rect = tester.getRect(slider);
    final gesture = await tester.startGesture(
      Offset(rect.left + rect.width * 2 / 3, rect.center.dy),
    );
    await gesture.moveTo(Offset(rect.left - 20, rect.center.dy));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(t.controller.settings.trainer.characterWpm, 10);
    expect(t.controller.settings.trainer.farnsworthWpm, 10);
  });

  testWidgets('feedback toggles persist and haptics hide on desktop', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final (t, _) = await _pump(tester);
    expect(find.text(en.learnHaptic), findsNothing);
    await tester.tap(_switchFor(en.learnFlash));
    await tester.pumpAndSettle();
    expect(t.controller.settings.flashEnabled, isTrue);
    await tester.tap(_switchFor(en.learnSound));
    await tester.pumpAndSettle();
    expect(t.controller.settings.soundEnabled, isFalse);
    expect(t.settingsStore.saveCount, 2);
    // Must be restored before the test body ends, not in a tearDown.
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('haptics toggle is offered on a phone', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final (t, _) = await _pump(tester);
    await tester.scrollUntilVisible(
      find.text(en.learnHaptic),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(_switchFor(en.learnHaptic));
    await tester.pumpAndSettle();
    expect(t.controller.settings.hapticEnabled, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('keyer mode segmented button persists', (tester) async {
    final (t, _) = await _pump(tester);
    await tester.scrollUntilVisible(
      find.text(en.learnKeyerStraight),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(en.learnKeyerStraight));
    await tester.pumpAndSettle();
    expect(t.controller.settings.keyerMode, KeyerMode.straight);
    expect((await t.settingsStore.load())!.keyerMode, KeyerMode.straight);
  });

  testWidgets('play sample renders CQ through the playback factory', (
    tester,
  ) async {
    final (t, playback) = await _pump(tester);
    await tester.tap(find.byTooltip(en.learnPlaySample));
    await tester.pump();
    expect(playback.created.single, t.controller.settings);
    expect(playback.sink.events.first.on, isTrue);
    final timeline = MorseEncoder.encode(
      TrainingSettingsScreen.sampleText,
      t.controller.settings.trainer.toTiming(),
    );
    playback.clock.advance(
      MorseEncoder.totalDuration(timeline) + const Duration(milliseconds: 1),
    );
    await tester.pump();
    expect(
      playback.sink.events.where((e) => e.on).length,
      timeline.where((e) => e.on).length,
    );
    expect(playback.sink.isOn, isFalse);
    // Button is re-enabled after completion.
    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(en.learnPlaySample),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.onPressed, isNotNull);
  });

  test('route carries the /settings/training name', () {
    expect(TrainingSettingsScreen.routeName, '/settings/training');
  });
}
