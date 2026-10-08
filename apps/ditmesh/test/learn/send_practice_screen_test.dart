import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';
import 'package:ditmesh/training/send_session.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/ui/learn/send/keyer_legend.dart';
import 'package:ditmesh/ui/learn/send/send_practice_screen.dart';
import 'package:ditmesh/ui/learn/send/send_result_view.dart';

import 'helpers/fake_playback.dart';
import 'helpers/l10n.dart';
import 'helpers/test_controller.dart';

const Duration _dit = Duration(milliseconds: 60); // 20 wpm

Future<(TestTraining, SendSession, FakeLearnPlaybackFactory)> _pump(
  WidgetTester tester, {
  required KeyerMode mode,
  String target = 'KM',
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final t = await TestTraining.create(
    settings: TrainingSettings(keyerMode: mode),
  );
  addTearDown(t.controller.dispose);
  final playback = FakeLearnPlaybackFactory();
  final session = SendSession(
    target: target,
    timing: const MorseTiming(wpm: 20),
    now: () => t.clock.now,
    lesson: 1,
  );
  await tester.pumpWidget(
    l10nApp(
      home: SendPracticeScreen(
        controller: t.controller,
        playback: playback,
        session: session,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (t, session, playback);
}

/// Advances the fake clock in tick-sized steps so the periodic decoder tick
/// runs the way it would on a device, then pumps a frame.
Future<void> _advance(WidgetTester tester, FakeClock clock, Duration by) async {
  clock.advance(by);
  await tester.pump();
}

void main() {
  group('straight key (touch)', () {
    testWidgets('pointer taps on the key decode through the real decoder', (
      tester,
    ) async {
      final (_, session, playback) = await _pump(
        tester,
        mode: KeyerMode.straight,
        target: 'K',
      );
      final key = find.byType(StraightKeyButton);
      expect(key, findsOneWidget);
      expect(tester.getSize(key).shortestSide, greaterThanOrEqualTo(48));
      final clock = playback.clock;

      Future<void> mark(Duration length) async {
        final gesture = await tester.startGesture(tester.getCenter(key));
        await tester.pump();
        await _advance(tester, clock, length);
        await gesture.up();
        await tester.pump();
      }

      // K = dah dit dah at PARIS spacing.
      await mark(_dit * 3);
      await _advance(tester, clock, _dit);
      await mark(_dit);
      await _advance(tester, clock, _dit);
      await mark(_dit * 3);
      expect(session.pendingPattern, '-.-');
      expect(find.text('-.-'), findsWidgets);

      // The periodic tick (40 ms) commits the character after > 2 dits.
      await _advance(tester, clock, _dit * 3);
      expect(session.decodedText, 'K');
      expect(find.text('K'), findsWidgets);
      // Sidetone followed every press and release.
      expect(playback.sink.events.length, 6);
      expect(playback.sink.isOn, isFalse);
      expect(find.textContaining('WPM'), findsWidgets);

      await tester.tap(find.text(en.learnDone));
      await tester.pumpAndSettle();
      expect(find.byType(SendResultView), findsOneWidget);
      expect(find.text(en.learnAccuracyPercent(100)), findsOneWidget);
      expect(find.text(en.learnSendClean), findsOneWidget);
    });

    testWidgets('done is disabled until something was keyed', (tester) async {
      await _pump(tester, mode: KeyerMode.straight);
      final done = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text(en.learnDone),
          matching: find.bySubtype<FilledButton>(),
        ),
      );
      expect(done.onPressed, isNull);
    });

    testWidgets('on a phone the keyboard legend is hidden', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await _pump(tester, mode: KeyerMode.straight);
      expect(find.byType(KeyerLegend), findsNothing);
      final key = find.byType(StraightKeyButton);
      expect(tester.getSize(key).shortestSide, greaterThanOrEqualTo(48));
      // Must be restored before the test body ends, not in a tearDown.
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('paddles (keyboard)', () {
    testWidgets('left/right Ctrl drive the iambic keyer on desktop', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final (_, session, playback) = await _pump(
        tester,
        mode: KeyerMode.iambicB,
        target: 'N',
      );
      expect(find.byType(PaddleButtons), findsOneWidget);
      expect(find.byType(KeyerLegend), findsOneWidget);
      expect(find.text(en.learnLegendPaddles), findsOneWidget);
      final clock = playback.clock;

      // Right Ctrl = dah. The keyer times the element itself; release before
      // the element ends so no second dah is queued.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlRight);
      await tester.pump();
      expect(playback.sink.isOn, isTrue, reason: 'sidetone on key-down');
      await _advance(tester, clock, const Duration(milliseconds: 100));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlRight);
      await tester.pump();
      // Dah ends at 180 ms, inter-element gap ends at 240 ms.
      await _advance(tester, clock, const Duration(milliseconds: 140));
      expect(playback.sink.isOn, isFalse);
      expect(session.pendingPattern, '-');

      // Left Ctrl = dit, started right at the end of the gap.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      await _advance(tester, clock, const Duration(milliseconds: 30));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      await _advance(tester, clock, const Duration(milliseconds: 90));
      expect(session.pendingPattern, '-.');

      // Character gap: the tick commits N.
      await _advance(tester, clock, _dit * 3);
      expect(session.decodedText, 'N');
      expect(session.marks, <Duration>[_dit * 3, _dit]);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('touch paddles are >= 48 dp and squeeze both fingers', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final (_, session, playback) = await _pump(
        tester,
        mode: KeyerMode.iambicA,
        target: 'A',
      );
      final paddles = find.byType(PaddleButtons);
      final size = tester.getSize(paddles);
      expect(size.height, greaterThanOrEqualTo(48));
      final ditCenter = tester.getCenter(find.text(en.learnDitLabel));
      final dit = await tester.startGesture(ditCenter);
      await tester.pump();
      await _advance(tester, playback.clock, const Duration(milliseconds: 30));
      await dit.up();
      await tester.pump();
      await _advance(tester, playback.clock, const Duration(milliseconds: 90));
      final dahCenter = tester.getCenter(find.text(en.learnDahLabel));
      final dah = await tester.startGesture(dahCenter);
      await tester.pump();
      await _advance(tester, playback.clock, const Duration(milliseconds: 30));
      await dah.up();
      await tester.pump();
      await _advance(tester, playback.clock, const Duration(milliseconds: 400));
      expect(session.decodedText, 'A');
      debugDefaultTargetPlatformOverride = null;
    });
  });

  testWidgets('switching keyer mode rebuilds the input and persists', (
    tester,
  ) async {
    final (t, _, _) = await _pump(tester, mode: KeyerMode.iambicB);
    expect(find.byType(PaddleButtons), findsOneWidget);
    await tester.tap(find.text(en.learnKeyerStraight));
    await tester.pumpAndSettle();
    expect(find.byType(StraightKeyButton), findsOneWidget);
    expect(find.byType(PaddleButtons), findsNothing);
    expect(t.controller.settings.keyerMode, KeyerMode.straight);
    expect(t.settingsStore.saveCount, 1);
  });

  testWidgets('copy-from-memory hides the target until the result', (
    tester,
  ) async {
    final (_, session, playback) = await _pump(
      tester,
      mode: KeyerMode.straight,
      target: 'M',
    );
    expect(find.text('M'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text(en.learnHiddenTarget), findsOneWidget);
    expect(find.text('M'), findsNothing);

    final key = find.byType(StraightKeyButton);
    final g = await tester.startGesture(tester.getCenter(key));
    await _advance(tester, playback.clock, _dit);
    await g.up();
    await tester.pump();
    await _advance(tester, playback.clock, _dit * 4);
    expect(session.decodedText, 'E');
    await tester.tap(find.text(en.learnDone));
    await tester.pumpAndSettle();
    expect(find.byType(SendResultView), findsOneWidget);
    expect(find.text(en.learnAccuracyPercent(0)), findsOneWidget);
  });
}
