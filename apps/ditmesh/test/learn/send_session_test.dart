import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/send_session.dart';

import 'helpers/test_controller.dart';

/// Keys [pattern] (`.`/`-`, space = word gap) into [session] at PARIS
/// timing with unit [dit], starting at [start]. Returns the time after the
/// last key-up.
Duration key(
  SendSession session,
  String pattern, {
  Duration dit = const Duration(milliseconds: 60),
  Duration start = Duration.zero,
}) {
  var t = start;
  final chars = pattern.split(' ');
  for (var c = 0; c < chars.length; c++) {
    if (c > 0) {
      t += dit * 7;
    }
    final elements = chars[c].split('');
    for (var i = 0; i < elements.length; i++) {
      if (i > 0) {
        t += dit;
      }
      session.keyDown(t);
      t += elements[i] == '-' ? dit * 3 : dit;
      session.keyUp(t);
    }
  }
  return t;
}

void main() {
  SendSession make(String target) => SendSession(
    target: target,
    timing: const MorseTiming(wpm: 20),
    now: () => kTestNow,
    lesson: 1,
  );

  test('decodes clean keying into text with committed characters', () {
    final s = make('KM');
    var t = key(s, '-.-');
    expect(s.pendingPattern, '-.-');
    expect(s.decodedText, '');
    t += const Duration(milliseconds: 180);
    // Character gap: 3 dit >= 2 dit threshold commits K.
    key(s, '--', start: t);
    expect(s.decodedText, 'K');
    expect(s.pendingPattern, '--');
    expect(s.markCount, 5);
    expect(s.gaps.length, 4);
    expect(s.estimatedWpm, closeTo(20, 0.5));
    final result = s.finish();
    expect(result.attempt.decoded, 'KM');
    expect(result.score.isPerfect, isTrue);
    expect(result.isClean, isTrue);
    expect(result.measuredWpm, closeTo(20, 0.5));
    s.dispose();
  });

  test('tick resolves the trailing gap without another key-down', () {
    final s = make('K');
    final end = key(s, '-.-');
    s.tick(end + const Duration(milliseconds: 100));
    expect(s.decodedText, '');
    s.tick(end + const Duration(milliseconds: 130));
    expect(s.decodedText, 'K');
    s.dispose();
  });

  test('changes stream fires on key events and decoder commits', () {
    final s = make('K')..listenToDecoder();
    var fired = 0;
    final sub = s.changes.listen((_) => fired++);
    key(s, '.');
    expect(fired, 3, reason: 'down, decoder element event, up');
    s.tick(const Duration(seconds: 1));
    // A one-second silence crosses both the character and the word
    // threshold, so the decoder commits 'K' and then a word space.
    expect(fired, 5, reason: 'character commit + word commit');
    sub.cancel();
    s.dispose();
  });

  test('long dits surface as a ditTooLong issue with a tip', () {
    final s = make('E');
    // Three clean 60 ms dits anchor the estimate, then one 110 ms "dit": the
    // decoder still classes it as a dit (below 2 x the estimate) but it is
    // well over the 1.3 x ditTooLong ratio whichever way the clusters split.
    var t = Duration.zero;
    for (final ms in <int>[60, 60, 60, 110]) {
      s.keyDown(t);
      t += Duration(milliseconds: ms);
      s.keyUp(t);
      t += const Duration(milliseconds: 60);
    }
    final result = s.finish();
    expect(result.attempt.marks.length, 4);
    expect(result.dahCount, 0);
    expect(result.attempt.estimatedDit.inMilliseconds, greaterThan(0));
    expect(result.hasIssue(SendIssueKind.ditTooLong), isTrue);
    s.dispose();
  });

  test('finish closes a key still held and is idempotent', () {
    final s = make('E');
    s.keyDown(Duration.zero);
    final first = s.finish();
    expect(s.isKeyDown, isFalse);
    expect(first.attempt.marks.length, 1);
    expect(s.finish(), same(first));
    expect(() => s.restart(), throwsStateError);
    s.dispose();
  });

  test('restart clears text and measurements but keeps the session open', () {
    final s = make('K');
    final end = key(s, '-.-');
    // Past the character threshold (2 dit) but short of the word one (5 dit).
    s.tick(end + const Duration(milliseconds: 200));
    expect(s.decodedText, 'K');
    s.restart();
    expect(s.decodedText, '');
    expect(s.hasInput, isFalse);
    expect(s.isFinished, isFalse);
    s.dispose();
  });

  test('empty attempt evaluates without a dit estimate', () {
    final s = make('K');
    final result = s.finish();
    expect(result.attempt.estimatedDit, Duration.zero);
    expect(result.measuredWpm, 0);
    expect(result.score.accuracy, 0);
    expect(result.issues, isEmpty);
    final score = s.scoreForHistory();
    expect(score.drillKind, 'send');
    expect(score.lesson, 1);
    s.dispose();
  });
}
