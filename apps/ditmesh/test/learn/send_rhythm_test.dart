import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh/training/send_detail_store.dart';
import 'package:ditmesh/training/send_session.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/ui/learn/send/send_practice_screen.dart';

import 'helpers/fake_playback.dart';
import 'helpers/l10n.dart';
import 'helpers/test_controller.dart';

const Duration _dit = Duration(milliseconds: 60);

/// A session that keyed [text] perfectly at 20 WPM.
SendSession _keyed(TrainingController c, String text) {
  final s = SendSession(
    target: text,
    timing: const MorseTiming(wpm: 20),
    now: c.now,
  );
  var at = Duration.zero;
  for (final e in MorseEncoder.encode(text, const MorseTiming(wpm: 20))) {
    if (e.on) {
      s.keyDown(at);
      s.keyUp(at + e.duration);
    }
    at += e.duration;
  }
  s.tick(at + _dit * 10);
  return s;
}

void main() {
  test('details are written before the summary refers to them', () async {
    final t = await TestTraining.create();
    final c = t.controller;
    final session = _keyed(c, 'KM');
    final result = session.finish();
    final ref = await c.saveSendDetail(session, result);
    await c.recordSendSession(session, detailRef: ref);
    expect(c.progress.history.single.detailRef, ref);
    final detail = (await c.loadSendDetail(ref))!;
    expect(detail.marks, session.marks);
    final timeline = detail.timeline();
    expect(timeline.aligned, isTrue);
    expect(timeline.issues, isEmpty);
    expect(await c.loadSendDetail('send_missing'), isNull);
  });

  test('trimming drops old details, never summaries or kept ones', () async {
    final t = await TestTraining.create();
    final c = t.controller;
    final refs = <String>[];
    // Size of one detail, to set a budget that holds about two.
    final probe = _keyed(c, 'KMKM');
    final one = (await c.loadSendDetail(
      await c.saveSendDetail(probe, probe.finish()),
    ))!.toJson().toString().length;
    await c.deleteDoc('send_index');
    for (var i = 0; i < 4; i++) {
      t.clock.advance(const Duration(minutes: 1));
      final session = _keyed(c, 'KMKM');
      final result = session.finish();
      final ref = await c.saveSendDetail(
        session,
        result,
        budgetBytes: one * 5 ~/ 2,
      );
      await c.recordSendSession(session, detailRef: ref);
      refs.add(ref);
      if (i == 0) await c.setSendDetailFavorite(ref, true);
    }
    expect(await c.loadSendDetail(refs.first), isNotNull, reason: 'kept');
    expect(await c.loadSendDetail(refs[1]), isNull, reason: 'oldest trimmed');
    expect(await c.loadSendDetail(refs.last), isNotNull);
    expect(c.progress.history, hasLength(4));
    expect(await c.isSendDetailFavorite(refs.first), isTrue);
  });

  test('a held key cancelled by background adds no phantom mark', () async {
    final t = await TestTraining.create();
    final s =
        SendSession(
            target: 'E',
            timing: const MorseTiming(wpm: 20),
            now: t.controller.now,
          )
          ..keyDown(Duration.zero)
          ..keyUp(_dit)
          ..keyDown(_dit * 2)
          ..cancelHeld();
    expect(s.marks, [_dit]);
    expect(s.gaps, isEmpty);
  });

  testWidgets('the send result shows both rhythm lanes and replays', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final t = await TestTraining.create(
      settings: const TrainingSettings(keyerMode: KeyerMode.straight),
    );
    final playback = FakeLearnPlaybackFactory();
    await tester.pumpWidget(
      l10nApp(
        home: SendPracticeScreen(
          controller: t.controller,
          playback: playback,
          session: SendSession(
            target: 'K',
            timing: const MorseTiming(wpm: 20),
            now: t.controller.now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final key = find.byType(StraightKeyButton);
    Future<void> mark(Duration d) async {
      final g = await tester.startGesture(tester.getCenter(key));
      playback.clock.advance(d);
      await tester.pump();
      await g.up();
      await tester.pump();
      playback.clock.advance(_dit);
      await tester.pump();
    }

    await mark(_dit * 3);
    await mark(_dit);
    await mark(_dit * 3);
    playback.clock.advance(_dit * 4);
    await tester.pump();
    await tester.tap(find.text(en.learnDone));
    await tester.pumpAndSettle();
    expect(find.text(en.learnRhythmMine), findsOneWidget);
    expect(find.text(en.learnRhythmStandard), findsOneWidget);
    expect(find.text(en.learnRhythmSymbolOk), findsOneWidget);
    final before = playback.sink.events.length;
    await tester.tap(find.text(en.learnRhythmPlayMine).first);
    await tester.pump();
    playback.clock.advance(const Duration(seconds: 2));
    await tester.pump();
    expect(playback.sink.events.length, greaterThan(before));
    final ref = t.controller.progress.history.single.detailRef;
    expect(ref, isNotNull);
  });
}
