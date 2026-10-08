import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/receive_session.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/ui/learn/conditions/conditions_playback.dart';
import 'package:ditmesh/ui/learn/receive/receive_drill_screen.dart';

import '../listen/workbench_support.dart' show FakeClipPlayer;
import 'helpers/fake_playback.dart';
import 'helpers/l10n.dart';
import 'helpers/test_controller.dart';

/// F11 in the app: a receive session under radio conditions plays rendered
/// audio only, keeps speeds, records its scenario, and earns activity only.
void main() {
  test('a conditions session keeps speeds, never counts toward the lesson', () async {
    final t = await TestTraining.create(settings: kShortSettings, seed: 3);
    addTearDown(t.controller.dispose);
    final c = t.controller;
    final clean = c.startReceiveSession(ReceiveDrillKind.groups);
    final radio = c.startReceiveSession(
      ReceiveDrillKind.groups,
      preset: RadioPreset.radio,
    );
    expect(clean.conditions, isNull);
    expect(radio.conditions!.preset, RadioPreset.radio);
    expect(radio.source, ExerciseSource.conditions);
    expect(radio.countsTowardLesson, isFalse);
    expect(radio.timing.wpm, clean.timing.wpm);
    expect(radio.timing.farnsworthWpm, clean.timing.farnsworthWpm);
    expect(radio.conditions!.toneHz, c.trainerSettings.toneHz);
    // Review stays clean.
    expect(
      c.startReceiveSession(ReceiveDrillKind.review, preset: RadioPreset.radio).conditions,
      isNull,
    );
  });

  test('recording keeps the scenario and changes no clean statistics', () async {
    final t = await TestTraining.create(settings: kShortSettings);
    addTearDown(t.controller.dispose);
    final c = t.controller;
    final statsBefore = c.progress.charStats;
    final lessonBefore = c.currentLesson;
    final session = c.startReceiveSession(
      ReceiveDrillKind.groups,
      preset: RadioPreset.light,
    );
    while (!session.isComplete) {
      session.submit(session.currentDrill.text);
    }
    final outcome = await c.recordReceiveSession(session);
    expect(outcome.credit.activity, isTrue);
    expect(outcome.credit.receiveStats, isFalse);
    expect(outcome.advanced, isFalse);
    expect(c.currentLesson, lessonBefore);
    expect(c.progress.charStats, statsBefore);
    final entry = c.progress.history.last;
    expect(entry.source, ExerciseSource.conditions);
    expect(entry.conditions, session.conditions);
  });

  group('drill screen', () {
    Future<(TestTraining, ReceiveSession, FakeLearnPlaybackFactory, FakeClipPlayer)>
    pump(WidgetTester tester, {bool sound = true}) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final t = await TestTraining.create(
        settings: kShortSettings.copyWith(soundEnabled: sound),
      );
      addTearDown(t.controller.dispose);
      final playback = FakeLearnPlaybackFactory();
      final clip = FakeClipPlayer();
      final session = t.controller.startReceiveSession(
        ReceiveDrillKind.groups,
        preset: RadioPreset.radio,
      );
      await tester.pumpWidget(
        l10nApp(
          home: ReceiveDrillScreen(
            controller: t.controller,
            playback: playback,
            session: session,
            conditionsPlayback: ConditionsPlayback(
              player: clip,
              render: ConditionsPlayback.renderNow,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (t, session, playback, clip);
    }

    testWidgets('plays rendered audio only and names the conditions', (tester) async {
      final (_, session, playback, clip) = await pump(tester);
      expect(clip.plays, hasLength(1));
      expect(playback.sink.events, isEmpty, reason: 'no unaffected flash or tone');
      expect(find.text(en.conditionsActive(en.conditionsRadio)), findsOneWidget);
      // Same round, same rendering.
      clip.end();
      // The stream event, then the rebuild it schedules.
      await tester.pump();
      await tester.pump();
      final replay = find.ancestor(
        of: find.text(en.learnReplay),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      expect(tester.widget<ButtonStyleButton>(replay).onPressed, isNotNull);
      await tester.tap(replay);
      await tester.pump();
      expect(clip.plays, hasLength(2));
      expect(clip.plays[1].$1, clip.plays[0].$1);
      expect(session.isAssisted, isTrue, reason: 'a replay after hearing it');
    });

    testWidgets('background stops the audio; return needs an explicit play', (tester) async {
      final (_, _, _, clip) = await pump(tester);
      expect(clip.isPlaying, isTrue);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      expect(clip.isPlaying, isFalse);
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      expect(clip.isPlaying, isFalse);
      expect(clip.plays, hasLength(1));
      // An interrupted round is not "heard": replaying it is not assistance.
    });

    testWidgets('after answering, a clean reference plays through the sink', (tester) async {
      final (_, session, playback, clip) = await pump(tester);
      await tester.enterText(find.byType(TextField), session.currentDrill.text);
      await tester.tap(find.text(en.learnSubmit));
      await tester.pumpAndSettle();
      expect(clip.isPlaying, isFalse);
      expect(session.isAssisted, isFalse);
      await tester.tap(find.byKey(const ValueKey('conditions-clean-replay')));
      await tester.pump();
      expect(playback.sink.events, isNotEmpty);
      expect(session.isAssisted, isFalse, reason: 'the answer was already in');
    });

    testWidgets('without sound the conditions are explained, nothing plays', (tester) async {
      final (_, _, playback, clip) = await pump(tester, sound: false);
      expect(find.text(en.conditionsNeedSound), findsOneWidget);
      expect(clip.plays, isEmpty);
      expect(playback.sink.events, isEmpty);
    });

    testWidgets('an audio engine failure is explained, not "listening" forever', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final t = await TestTraining.create(settings: kShortSettings);
      addTearDown(t.controller.dispose);
      final session = t.controller.startReceiveSession(ReceiveDrillKind.groups, preset: RadioPreset.light);
      await tester.pumpWidget(
        l10nApp(
          home: ReceiveDrillScreen(
            controller: t.controller,
            playback: FakeLearnPlaybackFactory(),
            session: session,
            conditionsPlayback: ConditionsPlayback(
              player: _FailingClipPlayer(),
              render: ConditionsPlayback.renderNow,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(en.conditionsAudioFailed), findsOneWidget);
      expect(find.text(en.learnReady), findsOneWidget);
    });

    testWidgets('backgrounded while rendering: the round is not left '
        '"listening"', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final t = await TestTraining.create(settings: kShortSettings);
      addTearDown(t.controller.dispose);
      final clip = FakeClipPlayer();
      final gate = Completer<void>();
      final session = t.controller.startReceiveSession(ReceiveDrillKind.groups, preset: RadioPreset.light);
      await tester.pumpWidget(
        l10nApp(
          home: ReceiveDrillScreen(
            controller: t.controller,
            playback: FakeLearnPlaybackFactory(),
            session: session,
            conditionsPlayback: ConditionsPlayback(
              player: clip,
              render: (text, scenario) async {
                await gate.future;
                return ConditionsPlayback.renderNow(text, scenario);
              },
            ),
          ),
        ),
      );
      await tester.pump();
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      gate.complete();
      await tester.pumpAndSettle();
      expect(clip.plays, isEmpty, reason: 'dropped, not started late');
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(find.text(en.learnReady), findsOneWidget);
      expect(session.isAssisted, isFalse);
    });

    testWidgets('dispose releases the audio', (tester) async {
      final (_, _, _, clip) = await pump(tester);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(clip.disposed, isTrue);
    });
  });
}

final class _FailingClipPlayer implements ClipPlayer {
  @override
  bool get isPlaying => false;

  @override
  Stream<bool> get playing => const Stream<bool>.empty();

  @override
  Future<void> play(Uint8List wav, {required Duration length, bool loop = false}) =>
      Future.error(StateError('no audio device'));

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
