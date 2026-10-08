import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/qso_practice.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/ui/learn/qso/qso_screen.dart';
import 'package:ditmesh/ui/learn/qso/qso_setup_screen.dart';

import 'helpers/fake_playback.dart';
import 'helpers/l10n.dart';
import 'helpers/test_controller.dart';

const QsoStation _me = QsoStation(callsign: 'BD1XYZ', name: 'LI', qth: 'PARIS');

Future<TestTraining> _training() => TestTraining.create(
  progress: TrainerProgress(currentLesson: 30),
  settings: const TrainingSettings(keyerMode: KeyerMode.straight),
);

QsoSession _session({QsoScenario scenario = QsoScenario.respondToCq}) =>
    QsoSession.start(
      scenario: scenario,
      seed: 11,
      local: _me,
      characterWpm: 20,
      effectiveWpm: 20,
    );

Future<void> _pumpScreen(
  WidgetTester tester,
  TestTraining t,
  QsoSession session,
  FakeLearnPlaybackFactory playback,
) async {
  tester.view.physicalSize = const Size(430, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    l10nApp(
      home: QsoScreen(
        controller: t.controller,
        playback: playback,
        session: session,
        screenWake: _NoWake(),
      ),
    ),
  );
  await tester.pump();
}

/// Lets the remote transmission play out on the fake clock.
Future<void> _finishPlayback(WidgetTester tester, FakeClock clock) async {
  for (var i = 0; i < 400; i++) {
    clock.advance(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

/// Keys [text] on the on-screen straight key at 20 WPM.
Future<void> _key(WidgetTester tester, FakeClock clock, String text) async {
  final key = find.byType(StraightKeyButton);
  expect(key, findsOneWidget);
  for (final e in MorseEncoder.encode(text, const MorseTiming(wpm: 20))) {
    if (e.on) {
      final g = await tester.startGesture(tester.getCenter(key));
      clock.advance(e.duration);
      await tester.pump();
      await g.up();
      await tester.pump();
    } else {
      clock.advance(e.duration);
      await tester.pump();
    }
  }
  clock.advance(const Duration(milliseconds: 400));
  await tester.pump();
}

final class _NoWake implements ScreenWakeApi {
  @override
  Future<void> keepOn(bool on) async {}
}

void main() {
  testWidgets('remote text stays hidden until revealed; reveal is a hint', (
    tester,
  ) async {
    final t = await _training();
    final playback = FakeLearnPlaybackFactory();
    final session = _session();
    await _pumpScreen(tester, t, session, playback);
    expect(find.textContaining('CQ CQ CQ'), findsNothing);
    expect(find.text(en.learnQsoRemoteHidden), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('qso-reveal-0')));
    await tester.pump();
    expect(find.textContaining('CQ CQ CQ'), findsOneWidget);
    expect(session.hints, 1);
    await _finishPlayback(tester, playback.clock);
  });

  testWidgets('keying a correct reply advances the QSO and saves a draft', (
    tester,
  ) async {
    final t = await _training();
    final playback = FakeLearnPlaybackFactory();
    final session = _session();
    await _pumpScreen(tester, t, session, playback);
    await _finishPlayback(tester, playback.clock);
    expect(find.text(en.learnQsoYourTurn), findsOneWidget);

    await _key(
      tester,
      playback.clock,
      '${session.remote.callsign} DE BD1XYZ K',
    );
    final decoded = tester.widget<Text>(
      find.byKey(const ValueKey('qso-decoded')),
    );
    expect(decoded.data!.trim(), '${session.remote.callsign} DE BD1XYZ K');
    await tester.tap(find.byKey(const ValueKey('qso-send')));
    await tester.pump();
    expect(session.stage, QsoStage.exchange);
    expect(find.text(en.learnQsoRemoteSending), findsOneWidget);
    await _finishPlayback(tester, playback.clock);
    expect(await t.controller.loadQsoDraft(), isNotNull);
    // No outbound chat, no receive statistics: only local state changed.
    expect(t.controller.progress.charStats, isEmpty);
  });

  testWidgets('a wrong callsign keeps the stage and explains why', (
    tester,
  ) async {
    final t = await _training();
    final playback = FakeLearnPlaybackFactory();
    final session = _session();
    await _pumpScreen(tester, t, session, playback);
    await _finishPlayback(tester, playback.clock);
    await _key(tester, playback.clock, 'K1ZZZ DE BD1XYZ K');
    await tester.tap(find.byKey(const ValueKey('qso-send')));
    await tester.pump();
    expect(session.stage, QsoStage.callConfirm);
    expect(find.text(en.learnQsoIssueWrongRemoteCall), findsOneWidget);
    await tester.tap(find.text(en.learnQsoHint));
    await tester.pump();
    expect(find.byKey(const ValueKey('qso-hint')), findsOneWidget);
  });

  testWidgets('the last transmission finishes, credits activity only', (
    tester,
  ) async {
    final t = await _training();
    final playback = FakeLearnPlaybackFactory();
    final session = _session(scenario: QsoScenario.callCq);
    // Play the first stages through the engine, then key the closing.
    session.submit('1', 'CQ CQ DE BD1XYZ K');
    session.submit(
      '2',
      '${session.remote.callsign} DE BD1XYZ UR RST 599 NAME LI QTH PARIS K',
    );
    session.submit('3', 'R R TNX ${session.remote.name}');
    expect(session.stage, QsoStage.closing);
    await _pumpScreen(tester, t, session, playback);
    // A resumed QSO never starts playback by itself.
    expect(find.text(en.learnQsoYourTurn), findsOneWidget);
    await _key(tester, playback.clock, 'TU 73 <SK>');
    await tester.tap(find.byKey(const ValueKey('qso-send')));
    await tester.pumpAndSettle();
    expect(session.isDone, isTrue);
    expect(find.text(en.learnQsoSummaryNote), findsOneWidget);
    final record = t.controller.progress.history.single;
    expect(record.source, ExerciseSource.qso);
    expect(t.controller.progress.charStats, isEmpty);
    expect(t.controller.currentLesson, 30);
    expect(await t.controller.loadQsoDraft(), isNull);
  });

  testWidgets('setup validates the station and offers resume', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final t = await _training();
    await t.controller.saveQsoDraft(_session());
    await tester.pumpWidget(
      l10nApp(
        home: QsoSetupScreen(
          controller: t.controller,
          playback: FakeLearnPlaybackFactory(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('qso-resume')), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '12');
    await tester.pump();
    expect(find.text(en.learnQsoInvalidCall), findsOneWidget);
    final start = tester.widget<ButtonStyleButton>(
      find.byKey(const ValueKey('qso-start')),
    );
    expect(start.onPressed, isNull);
  });

  testWidgets('a resumed QSO keeps the unsent reply and does not autoplay', (
    tester,
  ) async {
    final t = await _training();
    final playback = FakeLearnPlaybackFactory();
    final session = _session();
    final draft = QsoDraft(
      session: session,
      pendingText: '${session.remote.callsign} DE BD1XYZ K',
      pendingId: 'p1',
    );
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      l10nApp(
        home: QsoScreen(
          controller: t.controller,
          playback: playback,
          session: session,
          resumed: draft,
          screenWake: _NoWake(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(en.learnQsoYourTurn), findsOneWidget, reason: 'silent');
    expect(playback.sink.events, isEmpty);
    await tester.tap(find.byKey(const ValueKey('qso-send')));
    await tester.pump();
    expect(session.stage, QsoStage.exchange);
    await _finishPlayback(tester, playback.clock);
  });

  test('a finished QSO keeps its draft until the result is saved', () async {
    final t = await _training();
    final s = _session(scenario: QsoScenario.callCq);
    s.submit('1', 'CQ CQ DE BD1XYZ K');
    s.submit(
      '2',
      '${s.remote.callsign} DE BD1XYZ UR RST 599 NAME LI QTH PARIS K',
    );
    s.submit('3', 'R R TNX ${s.remote.name}');
    s.submit('4', 'TU 73<SK>');
    expect(s.isDone, isTrue);
    await t.controller.saveQsoDraft(s);
    // As if the app died before recording: the setup flow commits it once.
    final draft = (await t.controller.loadQsoDraft())!;
    expect(draft.session.isDone, isTrue);
    expect(await t.controller.finishQso(draft.session, Duration.zero), isTrue);
    expect(await t.controller.finishQso(draft.session, Duration.zero), isTrue);
    expect(t.controller.progress.history, hasLength(1));
    expect(await t.controller.loadQsoDraft(), isNull);
  });

  test('a parked finished QSO is committed when learning data loads', () async {
    final t = await _training();
    final s = _session(scenario: QsoScenario.callCq);
    s.submit('1', 'CQ CQ DE BD1XYZ K');
    s.submit(
      '2',
      '${s.remote.callsign} DE BD1XYZ UR RST 599 NAME LI QTH PARIS K',
    );
    s.submit('3', 'R R TNX ${s.remote.name}');
    s.submit('4', 'TU 73 <SK>');
    const doc = '${QsoPractice.finishedPrefix}a';
    final other = QsoSession.start(
      scenario: QsoScenario.callCq,
      seed: 12,
      local: _me,
      characterWpm: 20,
      effectiveWpm: 20,
    );
    other.submit('1', 'CQ CQ DE BD1XYZ K');
    other.submit(
      '2',
      '${other.remote.callsign} DE BD1XYZ UR RST 599 NAME LI QTH PARIS K',
    );
    other.submit('3', 'R R TNX ${other.remote.name}');
    other.submit('4', 'TU 73 <SK>');
    await t.controller.writeDoc('${QsoPractice.finishedPrefix}b', {
      // A second, different finished QSO (seed 12): both are recovered.
      'session': other.toJson(),
      'activeMs': 1000,
    });
    await t.controller.writeDoc(doc, {'session': s.toJson(), 'activeMs': 1000});
    await t.controller.recoverFinishedQso();
    expect(t.controller.progress.history, hasLength(2));
    expect(
      t.controller.progress.history.every(
        (h) => h.source == ExerciseSource.qso,
      ),
      isTrue,
    );
    expect(await t.controller.readDoc(doc), isNull);
    expect(await t.controller.docNames(), isNot(contains(doc)));
    await t.controller.recoverFinishedQso();
    expect(t.controller.progress.history, hasLength(2));
  });
}
