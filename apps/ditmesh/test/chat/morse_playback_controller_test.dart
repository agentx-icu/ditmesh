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
}
