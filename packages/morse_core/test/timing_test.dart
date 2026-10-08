import 'package:morse_core/morse_core.dart';
import 'package:test/test.dart';

void main() {
  group('MorseTiming standard (PARIS)', () {
    test('dit ms golden values at 5/12/20/25 WPM', () {
      expect(const MorseTiming(wpm: 5).ditMs, closeTo(240, 1e-9));
      expect(const MorseTiming(wpm: 12).ditMs, closeTo(100, 1e-9));
      expect(const MorseTiming(wpm: 20).ditMs, closeTo(60, 1e-9));
      expect(const MorseTiming(wpm: 25).ditMs, closeTo(48, 1e-9));
    });

    test('dit Duration is rounded to microseconds', () {
      // 1200 / 7 = 171.428571... ms
      expect(const MorseTiming(wpm: 7).dit.inMicroseconds, 171429);
      expect(const MorseTiming(wpm: 20).dit, const Duration(milliseconds: 60));
    });

    test('dah / gaps are 3, 1, 3, 7 dit multiples', () {
      for (final double wpm in <double>[5, 12, 20, 25, 13.5]) {
        final MorseTiming t = MorseTiming(wpm: wpm);
        final int dit = t.dit.inMicroseconds;
        expect(t.dah.inMicroseconds, closeTo(3 * dit, 3), reason: 'dah@$wpm');
        expect(t.intraGap.inMicroseconds, dit, reason: 'intra@$wpm');
        expect(t.charGap.inMicroseconds, closeTo(3 * dit, 3),
            reason: 'char@$wpm');
        expect(t.wordGap.inMicroseconds, closeTo(7 * dit, 3),
            reason: 'word@$wpm');
        expect(t.isFarnsworth, isFalse);
      }
    });

    test('koch20 is 20 WPM standard', () {
      expect(MorseTiming.koch20.wpm, 20);
      expect(MorseTiming.koch20.farnsworthWpm, isNull);
      expect(MorseTiming.koch20.dit, const Duration(milliseconds: 60));
    });
  });

  group('MorseTiming Farnsworth (ARRL)', () {
    test('18/5: char and word gaps match the hand-computed ARRL values', () {
      const MorseTiming t = MorseTiming(wpm: 18, farnsworthWpm: 5);
      expect(t.isFarnsworth, isTrue);
      // ta = (60*18 - 37.2*5) / (5*18) = 894 / 90 = 9.93333 s
      // charGap = 3 * ta / 19 = 1.568421 s ; wordGap = 7 * ta / 19 = 3.659649 s
      expect(t.charGap.inMicroseconds / 1000, closeTo(1568.421, 1.0));
      expect(t.wordGap.inMicroseconds / 1000, closeTo(3659.649, 1.0));
      // Elements themselves are unchanged.
      expect(t.dit.inMicroseconds, closeTo(66667, 1));
      expect(t.dah.inMicroseconds, closeTo(200000, 1));
      expect(t.intraGap, t.dit);
    });

    test('char:word gap ratio stays exactly 3:7', () {
      for (final (double, double) pair in <(double, double)>[
        (18, 5),
        (18, 8),
        (20, 10),
        (25, 13),
        (20, 18),
      ]) {
        final MorseTiming t = MorseTiming(wpm: pair.$1, farnsworthWpm: pair.$2);
        expect(
          (t.wordGap.inMicroseconds * 3 - t.charGap.inMicroseconds * 7).abs(),
          lessThanOrEqualTo(10),
          reason: '$t',
        );
      }
    });

    test('Farnsworth gaps are longer than standard gaps', () {
      const MorseTiming std = MorseTiming(wpm: 18);
      const MorseTiming fw = MorseTiming(wpm: 18, farnsworthWpm: 8);
      expect(fw.charGap, greaterThan(std.charGap));
      expect(fw.wordGap, greaterThan(std.wordGap));
    });

    test('farnsworthWpm >= wpm falls back to standard spacing', () {
      const MorseTiming same = MorseTiming(wpm: 20, farnsworthWpm: 20);
      const MorseTiming faster = MorseTiming(wpm: 20, farnsworthWpm: 25);
      const MorseTiming std = MorseTiming(wpm: 20);
      expect(same.isFarnsworth, isFalse);
      expect(faster.isFarnsworth, isFalse);
      expect(same.charGap, std.charGap);
      expect(same.wordGap, std.wordGap);
      expect(faster.wordGap, std.wordGap);
    });

    test('PARIS at c/s Farnsworth takes 60/s seconds per word', () {
      // PARIS has 19 dit-units of char/word gaps plus 31 units of marks and
      // intra gaps; with Farnsworth the whole word must take 60/s seconds.
      const MorseTiming t = MorseTiming(wpm: 18, farnsworthWpm: 8);
      final List<MorseElement> word = MorseEncoder.encode('PARIS', t);
      final Duration total = MorseEncoder.totalDuration(word) + t.wordGap;
      expect(total.inMicroseconds / 1e6, closeTo(60 / 8, 0.002));
    });
  });

  group('MorseTiming misc', () {
    test('copyWith', () {
      const MorseTiming t = MorseTiming(wpm: 20, farnsworthWpm: 10);
      expect(t.copyWith(wpm: 25), const MorseTiming(wpm: 25, farnsworthWpm: 10));
      expect(t.copyWith(farnsworthWpm: 12),
          const MorseTiming(wpm: 20, farnsworthWpm: 12));
      expect(t.copyWith(), t);
    });

    test('equality and toString', () {
      expect(const MorseTiming(wpm: 20), const MorseTiming(wpm: 20));
      expect(const MorseTiming(wpm: 20), isNot(const MorseTiming(wpm: 21)));
      expect(const MorseTiming(wpm: 20).toString(), contains('wpm: 20'));
    });
  });
}
