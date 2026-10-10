import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';

void main() {
  group('MorseKeyEvent', () {
    test('names the edge and the time', () {
      expect(
        const MorseKeyEvent.down(Duration(milliseconds: 10)).toString(),
        'down@10ms',
      );
      expect(
        const MorseKeyEvent.up(Duration(milliseconds: 70)).toString(),
        'up@70ms',
      );
    });

    test('equality and hash follow the edge and the time', () {
      const a = MorseKeyEvent.down(Duration(milliseconds: 10));
      const b = MorseKeyEvent(on: true, at: Duration(milliseconds: 10));
      const c = MorseKeyEvent.up(Duration(milliseconds: 10));
      const d = MorseKeyEvent.down(Duration(milliseconds: 11));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a, isNot(d));
      final all = [a, b, c, d];
      expect(all.toSet(), hasLength(3));
    });
  });

  group('MorseDecoderTarget', () {
    test('forwards key edges to the decoder', () async {
      final decoder = MorseDecoder();
      final target = MorseDecoderTarget(decoder);
      final events = <DecodeEvent>[];
      final sub = decoder.events.listen(events.add);
      final dit = decoder.config.initialDit;
      // A single dit then a long silence: the decoder commits 'E'.
      target.keyDown(Duration.zero);
      target.keyUp(dit);
      decoder.tick(dit * 20);
      await pumpEventQueue();
      // The long silence also commits a word space after the character.
      expect(decoder.text.trim(), 'E');
      expect(events, isNotEmpty);
      await sub.cancel();
      decoder.dispose();
    });
  });

  group('KeyerTiming', () {
    test('fromMorseTiming takes the element timing and ignores Farnsworth', () {
      final plain = KeyerTiming.fromMorseTiming(const MorseTiming(wpm: 20));
      final farnsworth = KeyerTiming.fromMorseTiming(
        const MorseTiming(wpm: 20, farnsworthWpm: 10),
      );
      expect(plain.dit, const Duration(milliseconds: 60));
      expect(plain.dah, const Duration(milliseconds: 180));
      expect(plain.gap, const Duration(milliseconds: 60));
      expect(farnsworth, plain);
      expect(plain, KeyerTiming.fromWpm(20));
      expect(plain.hashCode, KeyerTiming.fromWpm(20).hashCode);
    });

    test('toString lists the three durations', () {
      expect(
        KeyerTiming.fromWpm(20).toString(),
        'KeyerTiming(dit: 60ms, dah: 180ms, gap: 60ms)',
      );
    });

    test('durationOf scales gaps for characters and words', () {
      final t = KeyerTiming.standard(const Duration(milliseconds: 50));
      expect(
        t.durationOf(MorseElementKind.dit),
        const Duration(milliseconds: 50),
      );
      expect(
        t.durationOf(MorseElementKind.dah),
        const Duration(milliseconds: 150),
      );
      expect(
        t.durationOf(MorseElementKind.intraGap),
        const Duration(milliseconds: 50),
      );
      expect(
        t.durationOf(MorseElementKind.charGap),
        const Duration(milliseconds: 150),
      );
      expect(
        t.durationOf(MorseElementKind.wordGap),
        const Duration(milliseconds: 350),
      );
    });
  });

  group('NullSink', () {
    test('accepts the whole contract without side effects', () async {
      const sink = NullSink();
      await sink.prepare();
      sink
        ..on()
        ..on()
        ..off()
        ..off();
      await sink.dispose();
      // Composable like any other sink.
      final composite = CompositeSink(const [NullSink(), NullSink()]);
      await composite.prepare();
      composite
        ..on()
        ..off();
      await composite.dispose();
    });
  });

  group('SystemClock', () {
    test('is monotonic and shares one process-wide instance', () async {
      final clock = SystemClock();
      final a = clock.now();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final b = clock.now();
      expect(b, greaterThanOrEqualTo(a));
      expect(identical(SystemClock.shared, SystemClock.shared), isTrue);
    });

    test('schedule fires once, and a negative delay fires at once', () async {
      final clock = SystemClock();
      final fired = Completer<void>();
      final timer = clock.schedule(
        const Duration(milliseconds: -5),
        fired.complete,
      );
      await fired.future.timeout(const Duration(seconds: 1));
      expect(timer.isActive, isFalse);

      var count = 0;
      final later = clock.schedule(
        const Duration(milliseconds: 80),
        () => count++,
      );
      expect(later.isActive, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(count, 0, reason: 'a positive delay is not collapsed to zero');
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(count, 1);
      expect(later.isActive, isFalse);
    });

    test('a cancelled timer never fires', () async {
      final clock = SystemClock();
      var fired = false;
      clock
          .schedule(const Duration(milliseconds: 5), () => fired = true)
          .cancel();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fired, isFalse);
    });
  });
}
