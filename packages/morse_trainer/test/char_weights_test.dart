import 'dart:math';

import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  group('CharWeights', () {
    test('uniform weighs everything 1', () {
      final w = CharWeights.uniform();
      expect(w.weightOf('K'), 1);
      expect(w.weightsFor(['A', 'B']), [1, 1]);
    });

    test('formula w = 1 + k(1 - acc) with floor', () {
      final w = CharWeights.fromAccuracy(
        {'K': 1.0, 'M': 0.5, 'R': 0.0},
        k: 2,
        floor: 1.2,
      );
      expect(w.weightOf('K'), 1.2); // 1 + 0 -> floored
      expect(w.weightOf('M'), closeTo(2.0, 1e-9));
      expect(w.weightOf('R'), closeTo(3.0, 1e-9));
      // Unknown symbol is treated as accuracy 0 -> max weight.
      expect(w.weightOf('Z'), closeTo(3.0, 1e-9));
      expect(w.defaultWeight, closeTo(3.0, 1e-9));
    });

    test('recent boost multiplies', () {
      final w = CharWeights.fromAccuracy(
        {'K': 0.5},
        k: 2,
        recent: const {'K', 'U'},
        recentBoost: 3,
      );
      expect(w.weightOf('K'), closeTo(6.0, 1e-9));
      expect(w.weightOf('U'), closeTo(9.0, 1e-9)); // unknown (3.0) x 3
      expect(w.symbols, containsAll(['K', 'U']));
    });

    test('fromStats honours minAttempts', () {
      final w = CharWeights.fromStats({
        'K': const CharStats(attempts: 10, correct: 10),
        'M': const CharStats(attempts: 1, correct: 1),
      }, minAttempts: 2);
      expect(w.weightOf('K'), 1);
      expect(w.weightOf('M'), w.defaultWeight);
    });

    test('accuracy is clamped, explicit rejects negatives', () {
      final w = CharWeights.fromAccuracy({'K': 1.7, 'M': -2});
      expect(w.weightOf('K'), 1);
      expect(w.weightOf('M'), 3);
      expect(() => CharWeights.explicit({'K': -1}), throwsArgumentError);
    });

    test('pick is deterministic and biased', () {
      final w = CharWeights.explicit({'K': 9, 'M': 1});
      const chars = ['K', 'M'];
      final a = w.pickMany(Random(3), chars, 200);
      final b = w.pickMany(Random(3), chars, 200);
      expect(a, b);
      final ks = a.where((c) => c == 'K').length;
      expect(ks, inInclusiveRange(150, 200));
    });

    test('pick with all-zero weights falls back to uniform', () {
      final w = CharWeights.explicit({'K': 0, 'M': 0});
      final picks = w.pickMany(Random(1), ['K', 'M'], 50).toSet();
      expect(picks, {'K', 'M'});
    });

    test('pick from empty list throws', () {
      expect(
        () => CharWeights.uniform().pick(Random(1), []),
        throwsArgumentError,
      );
    });

    test('JSON round trip', () {
      final w = CharWeights.fromAccuracy({'K': 0.25}, recent: const {'M'});
      final back = CharWeights.fromJson(w.toJson());
      expect(back.weightOf('K'), w.weightOf('K'));
      expect(back.weightOf('M'), w.weightOf('M'));
      expect(back.defaultWeight, w.defaultWeight);
    });
  });
}
