import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';
import 'package:ditmesh/ui/chat/morse_playback_controller.dart';

// 20 wpm: dit 60 ms, char gap 180 ms, word gap 420 ms. 'E' is one dit.
const MorseTiming _t = MorseTiming(wpm: 20);
const Duration _ms = Duration(milliseconds: 1);

/// Lets `prepare()` resolve and the reserved clip reach the player.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeClock clock;
  late RecordingSink sink;
  late MorsePlaybackController c;

  setUp(() {
    clock = FakeClock();
    sink = RecordingSink(clock: clock);
    c = MorsePlaybackController(sink: sink, clock: clock);
  });
  tearDown(() => c.dispose());

  test('playing B over A keeps B as the playing id', () async {
    await c.play('a', 'TEST', _t);
    expect(c.playingId, 'a');
    clock.advance(_ms * 10);
    await c.play('b', 'TEST', _t);
    expect(c.playingId, 'b');
    clock.advance(_ms * 70);
    expect(c.activeMarkFor('b'), 0);
  });

  test('auto-play queues FIFO, spaced by a word gap', () async {
    c.enqueue('a', 'E', _t);
    // Still preparing: B must queue behind A, not replace it.
    c.enqueue('b', 'E', _t);
    c.enqueue('b', 'E', _t);
    expect(c.playingId, 'a');
    expect(c.queuedIds, ['b']);
    await _settle();
    clock.advance(_ms * 60);
    expect(c.playingId, 'b');
    await _settle();
    clock.advance(_ms * 1000);
    expect(c.playingId, isNull);
    expect(sink.log, [(true, 0), (false, 60), (true, 480), (false, 540)]);
  });

  test('a tapped bubble and stop drop the auto-play queue', () async {
    c.enqueue('a', 'E', _t);
    c.enqueue('b', 'E', _t);
    await c.play('m', 'E', _t);
    expect(c.queuedIds, isEmpty);
    c.enqueue('c', 'E', _t);
    c.stop();
    expect(c.playingId, isNull);
    expect(c.queuedIds, isEmpty);
  });

  test('stop while preparing leaves nothing to start', () async {
    c.enqueue('a', 'E', _t);
    c.stop();
    expect(c.playingId, isNull);
    await _settle();
    clock.advance(_ms * 500);
    expect(sink.log, isEmpty);
  });

  test('cancel removes one origin and keeps the other', () async {
    c.enqueue('a', 'TEST', _t);
    c.enqueue('b', 'E', _t);
    await _settle();
    c.cancel(PlaybackOrigin.auto);
    expect(c.playingId, 'a');
    expect(c.queuedIds, isEmpty);
    c.cancel(PlaybackOrigin.auto, includeCurrent: true);
    expect(c.playingId, isNull);
  });

  test('hand keying pauses auto-play until the key rests', () async {
    c.enqueue('a', 'TEST', _t);
    await _settle();
    clock.advance(_ms * 30);
    c.keyingSink.on();
    expect(c.playingId, isNull);
    expect(c.queuedIds, ['a']);
    clock.advance(_ms * 100);
    c.keyingSink.off();
    await _settle();
    // Nothing sounds during the hold-off.
    sink.clear();
    clock.advance(MorsePlaybackController.keyingHoldoff - _ms);
    expect(sink.log, isEmpty);
    expect(c.playingId, isNull);
    clock.advance(_ms);
    await _settle();
    clock.advance(_ms * 10);
    expect(sink.log.first.$1, isTrue);
    expect(c.playingId, 'a');
  });

  test('unsupported text is never queued', () async {
    c.enqueue('a', '中文', _t);
    expect(c.playingId, isNull);
    expect(c.queuedIds, isEmpty);
  });

  test(
    'arrivals during the keying hold-off queue behind the cut message',
    () async {
      c.enqueue('a', 'TEST', _t);
      await _settle();
      clock.advance(_ms * 30);
      c.keyingSink.on();
      clock.advance(_ms * 50);
      c.keyingSink.off();
      c.enqueue('b', 'E', _t);
      expect(c.playingId, isNull);
      expect(c.queuedIds, ['a', 'b']);
      clock.advance(MorsePlaybackController.keyingHoldoff);
      expect(c.playingId, 'a');
    },
  );

  test(
    'a message arriving right after keying still waits the hold-off',
    () async {
      c.keyingSink.on();
      clock.advance(_ms * 50);
      c.keyingSink.off();
      c.enqueue('a', 'E', _t);
      expect(c.playingId, isNull);
      clock.advance(MorsePlaybackController.keyingHoldoff);
      expect(c.playingId, 'a');
    },
  );

  test('stop also drops a held queue', () async {
    c.enqueue('a', 'TEST', _t);
    await _settle();
    c.keyingSink.on();
    c.keyingSink.off();
    sink.clear();
    c.stop();
    clock.advance(MorsePlaybackController.keyingHoldoff * 2);
    await _settle();
    expect(c.playingId, isNull);
    expect(sink.log, isEmpty);
  });

  test('the word gap counts from the last key-up, not from a cut', () async {
    // 'E' sounds 0-60 ms; queued 'T' waits the word gap (420 ms) from 60.
    c.enqueue('e', 'E', _t);
    c.enqueue('t', 'T', _t);
    await _settle();
    clock.advance(_ms * 60);
    await _settle();
    clock.advance(_ms * 140);
    // Cut 'T' during its leading gap at 200 ms; 'T' restarts from the top
    // when re-queued, still owing only what is left of the gap.
    c.cancel(PlaybackOrigin.auto, includeCurrent: true);
    c.enqueue('t2', 'T', _t);
    await _settle();
    clock.advance(_ms * 1000);
    expect(sink.log, [(true, 0), (false, 60), (true, 480), (false, 660)]);
  });

  test('a tapped bubble also waits for the key to rest', () async {
    c.keyingSink.on();
    final Future<void> pending = c.play('m', 'E', _t);
    expect(c.playingId, isNull);
    clock.advance(_ms * 50);
    c.keyingSink.off();
    await pending;
    clock.advance(MorsePlaybackController.keyingHoldoff);
    expect(c.playingId, 'm');
  });

  test('toggling auto-play keeps the hold-off after keying', () async {
    c.keyingSink.on();
    c.keyingSink.off();
    c.cancel(PlaybackOrigin.auto, includeCurrent: true);
    c.enqueue('a', 'E', _t);
    expect(c.playingId, isNull);
    clock.advance(MorsePlaybackController.keyingHoldoff - _ms);
    expect(c.playingId, isNull);
    clock.advance(_ms);
    expect(c.playingId, 'a');
  });

  test('hand keying sounds at keyingToneHz', () {
    final SidetoneSink tone = SidetoneSink(frequencyHz: 700);
    final MorsePlaybackController owned = MorsePlaybackController(
      sink: sink,
      clock: clock,
      sidetone: tone,
    );
    addTearDown(owned.dispose);
    owned.keyingToneHz = 550;
    owned.keyingSink.on();
    expect(tone.frequencyHz, 550);
    owned.keyingSink.off();
  });

  test('auto-play skips a clip longer than maxAutoClip', () async {
    // 0 is five dahs: at 5 wpm (dit 240 ms) 200 of them run far past 2 min.
    c.enqueue('long', '0' * 200, const MorseTiming(wpm: 5));
    expect(c.playingId, isNull);
    expect(c.queuedIds, isEmpty);
    // A tap still plays it.
    await c.play('long', '0' * 200, const MorseTiming(wpm: 5));
    expect(c.playingId, 'long');
  });

  test('the auto-play queue keeps the newest maxQueuedAuto clips', () async {
    c.enqueue('first', 'E', _t); // becomes current
    for (var i = 0; i < MorsePlaybackController.maxQueuedAuto + 2; i++) {
      c.enqueue('q$i', 'E', _t);
    }
    expect(c.queuedIds, hasLength(MorsePlaybackController.maxQueuedAuto));
    expect(c.queuedIds.first, 'q2');
    expect(c.queuedIds.last, 'q${MorsePlaybackController.maxQueuedAuto + 1}');
  });

  test('an interrupted clip going back to the queue keeps the cap', () async {
    c.enqueue('first', 'TEST', _t);
    await _settle();
    for (var i = 0; i < MorsePlaybackController.maxQueuedAuto; i++) {
      c.enqueue('q$i', 'E', _t);
    }
    c.keyingSink.on(); // 'first' is cut and goes back to the head
    expect(c.queuedIds, hasLength(MorsePlaybackController.maxQueuedAuto));
    expect(c.queuedIds.first, 'first');
    expect(c.queuedIds, isNot(contains('q0')));
    c.keyingSink.off();
  });

  test('cancelMessages drops deleted clips, current included', () async {
    c.enqueue('a', 'TEST', _t);
    c.enqueue('b', 'E', _t);
    c.enqueue('c', 'E', _t);
    await _settle();
    c.cancelMessages({'a', 'c'});
    expect(c.queuedIds, isEmpty);
    expect(c.playingId, 'b');
  });

  test('keyers prepare the shared sink', () async {
    await c.keyingSink.prepare();
    expect(sink.prepareCalls, 1);
  });

  group('mobile lifecycle', () {
    late _FakeForeground foreground;

    setUp(() {
      c.dispose();
      foreground = _FakeForeground();
      c = MorsePlaybackController(
        sink: sink,
        clock: clock,
        foreground: foreground,
      );
    });

    test('backgrounding pauses a tapped clip; the foreground resumes it '
        'where it stopped', () async {
      await c.play('e', 'E', _t);
      clock.advance(_ms * 20);
      foreground.set(false);
      expect(sink.log, [(true, 0), (false, 20)]);
      // The timeline must not run on silently (or buzz in a pocket).
      clock.advance(_ms * 500);
      expect(sink.log.length, 2);
      expect(c.playingId, 'e');
      foreground.set(true);
      await _settle();
      clock.advance(_ms * 40);
      expect(sink.log.sublist(2), [(true, 520), (false, 560)]);
      expect(c.playingId, isNull);
    });

    test(
      'messages received in the background wait for the foreground',
      () async {
        foreground.set(false);
        c.enqueue('a', 'E', _t);
        await _settle();
        expect(c.playingId, isNull);
        expect(c.queuedIds, ['a']);
        expect(sink.log, isEmpty);
        foreground.set(true);
        await _settle();
        expect(c.playingId, 'a');
        expect(sink.log, [(true, 0)]);
      },
    );

    test('a clip whose prepare ends in the background starts paused', () async {
      c.enqueue('a', 'E', _t);
      foreground.set(false);
      await _settle();
      expect(sink.log, [(true, 0), (false, 0)]);
      clock.advance(_ms * 500);
      expect(sink.log.length, 2);
      expect(c.playingId, 'a');
      foreground.set(true);
      await _settle();
      clock.advance(_ms * 60);
      expect(sink.log.sublist(2), [(true, 500), (false, 560)]);
      expect(c.playingId, isNull);
    });

    test('the player resumes only after lifecycle-gated sinks heard the '
        'foreground', () async {
      c.dispose();
      final _GatedSink gated = _GatedSink(sink, foreground);
      c = MorsePlaybackController(
        sink: gated,
        clock: clock,
        foreground: foreground,
      );
      await c.play('e', 'E', _t);
      clock.advance(_ms * 20);
      foreground.set(false);
      expect(sink.log, [(true, 0), (false, 20)]);
      // Resumed synchronously inside the controller's listener the key-down
      // would reach the sink before its own listener ran, and be dropped.
      foreground.set(true);
      await _settle();
      clock.advance(_ms * 40);
      expect(sink.log.sublist(2), [(true, 20), (false, 60)]);
      expect(c.playingId, isNull);
    });

    test('holdAutomatic keeps queued messages until it is cleared', () async {
      c.enqueue('a', 'E', _t);
      await _settle();
      expect(c.playingId, 'a');
      c.enqueue('b', 'E', _t);
      c.holdAutomatic = true;
      clock.advance(_ms * 60);
      await _settle();
      expect(c.playingId, isNull, reason: 'a finished');
      expect(c.queuedIds, ['b']);
      clock.advance(_ms * 2000);
      await _settle();
      expect(c.playingId, isNull, reason: 'no automatic start while held');
      c.holdAutomatic = false;
      await _settle();
      expect(c.playingId, 'b');
    });

    test('a hold set while an automatic clip prepares puts it back', () async {
      c.enqueue('a', 'E', _t);
      c.holdAutomatic = true;
      await _settle();
      expect(sink.log, isEmpty);
      expect(c.playingId, isNull);
      expect(c.queuedIds, ['a']);
      c.holdAutomatic = false;
      await _settle();
      expect(c.playingId, 'a');
    });

    test('holdAutomatic does not stop a tapped bubble', () async {
      c.holdAutomatic = true;
      await c.play('m', 'E', _t);
      expect(c.playingId, 'm');
    });

    test('dispose stops listening to the lifecycle', () {
      expect(foreground.listeners, isNotEmpty);
      c.dispose();
      expect(foreground.cancelled, 1);
    });
  });
}

final class _FakeForeground implements AppForeground {
  @override
  bool isForeground = true;
  final List<void Function(bool foreground)> listeners =
      <void Function(bool foreground)>[];
  int cancelled = 0;

  @override
  void Function() listen(void Function(bool foreground) onChange) {
    listeners.add(onChange);
    return () {
      listeners.remove(onChange);
      cancelled++;
    };
  }

  /// Notifies in subscription order, like the widgets binding does.
  void set(bool foreground) {
    isForeground = foreground;
    for (final void Function(bool) l in List.of(listeners)) {
      l(foreground);
    }
  }
}

/// A sink that gates itself on the lifecycle the way SidetoneSink and
/// HapticSink do: subscribes in [prepare] (after the controller did) and
/// ignores [on] while it believes the app is in the background.
final class _GatedSink implements MorseSink {
  _GatedSink(this._inner, this._foreground);

  final MorseSink _inner;
  final AppForeground _foreground;
  bool _background = false;
  void Function()? _stop;

  @override
  Future<void> prepare() async {
    _stop ??= _foreground.listen((bool fg) => _background = !fg);
    await _inner.prepare();
  }

  @override
  void on() {
    if (!_background) _inner.on();
  }

  @override
  void off() => _inner.off();

  @override
  Future<void> dispose() async {
    _stop?.call();
    await _inner.dispose();
  }
}
