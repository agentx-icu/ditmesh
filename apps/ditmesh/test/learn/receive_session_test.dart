import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/receive_session.dart';

import 'helpers/test_controller.dart';

void main() {
  ReceiveSession session({int charBudget = 10, TestClock? clock}) {
    final c = clock ?? TestClock();
    return ReceiveSession(
      generator: RandomGroupsDrill(
        chars: const <String>['K', 'M'],
        groupCount: 1,
        groupSize: 5,
      ),
      chars: const <String>['K', 'M'],
      timing: const MorseTiming(wpm: 20),
      charBudget: charBudget,
      lesson: 1,
      random: Random(3),
      now: () => c.now,
    );
  }

  test('starts with a generated round and a timeline', () {
    final s = session();
    expect(s.currentDrill.charCount, 5);
    expect(s.currentTimeline, isNotEmpty);
    expect(s.currentTimeline.first.on, isTrue);
    expect(s.roundCount, 0);
    expect(s.progress, 0);
    expect(s.isComplete, isFalse);
  });

  test('completes once the character budget is answered', () {
    final s = session(charBudget: 10);
    final first = s.submit(s.currentDrill.text);
    expect(first.index, 0);
    expect(first.score.isPerfect, isTrue);
    expect(s.charsAnswered, 5);
    expect(s.progress, 0.5);
    expect(s.isComplete, isFalse);
    expect(s.currentDrill, isNot(same(first.drill)));

    s.submit(s.currentDrill.text);
    expect(s.isComplete, isTrue);
    expect(s.progress, 1);
    expect(() => s.finish(), returnsNormally);
    expect(s.isFinished, isTrue);
    expect(() => s.submit('K'), throwsStateError);
  });

  test('aggregate score sums the rounds and carries bookkeeping', () {
    final s = session(charBudget: 10);
    final target1 = s.currentDrill.text;
    s.submit(target1);
    final target2 = s.currentDrill.text;
    // Miss the last symbol of the second round.
    s.submit(target2.substring(0, 4));
    final score = s.finish();
    expect(score.totalChars, 10);
    expect(score.correctChars, 9);
    expect(score.deletions, 1);
    expect(score.lesson, 1);
    expect(score.drillKind, 'groups');
    expect(score.at, kTestNow);
    expect(s.weakChars(), <String>[target2[4]]);
    expect(s.finish(), same(score), reason: 'finish is idempotent');
  });

  test('confusion pairs are counted across rounds, most frequent first', () {
    final s = session(charBudget: 15);
    for (var i = 0; i < 3; i++) {
      final target = s.currentDrill.text;
      // Swap K and M in the copy so every symbol is a confusion.
      s.submit(target.split('').map((c) => c == 'K' ? 'M' : 'K').join());
    }
    final pairs = s.confusionPairs(limit: 2);
    expect(pairs.length, 2);
    expect(pairs.first.$3, greaterThanOrEqualTo(pairs.last.$3));
    // The aligner may explain a fully swapped copy with a shift (one miss +
    // one insertion) instead of substitutions, so only the shape is fixed:
    // every target is a learned symbol and it was never heard as itself.
    for (final (target, answered, count) in pairs) {
      expect(target, isIn(<String>['K', 'M']));
      expect(answered, isNot(target));
      expect(count, greaterThan(0));
    }
    expect(s.confusionPairs(limit: 1).length, 1);
  });
}
