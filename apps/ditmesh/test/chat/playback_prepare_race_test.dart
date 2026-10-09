import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/morse_playback_controller.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';

class _SlowSink implements MorseSink {
  _SlowSink(this.inner);
  final RecordingSink inner;
  final ready = Completer<void>();
  @override
  Future<void> prepare() => ready.future;
  @override
  void on() => inner.on();
  @override
  void off() => inner.off();
  @override
  Future<void> dispose() async {}
}

void main() {
  test('resume during preparation waits for key-up holdoff', () async {
    final clock = FakeClock();
    final records = RecordingSink(clock: clock);
    final sink = _SlowSink(records);
    final player = MorsePlaybackController(sink: sink, clock: clock);
    addTearDown(player.dispose);
    final start = player.play('m', 'T', const MorseTiming(wpm: 20));
    player.pause();
    player.keyingSink.on();
    clock.advance(const Duration(milliseconds: 50));
    player.keyingSink.off();
    player.resume();
    records.clear();
    sink.ready.complete();
    await start;
    expect(
      records.log,
      isEmpty,
      reason: 'Playback must honor holdoff after live key release',
    );
    expect(player.isPaused, isTrue);
    clock.advance(
      MorsePlaybackController.keyingHoldoff - const Duration(milliseconds: 1),
    );
    expect(records.log, isEmpty);
    clock.advance(const Duration(milliseconds: 1));
    expect(records.log, [(true, 1550)]);
    expect(player.isPaused, isFalse);
    clock.advance(const Duration(milliseconds: 180));
    expect(records.log.last, (false, 1730));
  });
  test('resume during preparation waits for live keying and holdoff', () async {
    final clock = FakeClock();
    final records = RecordingSink(clock: clock);
    final sink = _SlowSink(records);
    final tone = SidetoneSink(frequencyHz: 700);
    addTearDown(tone.dispose);
    final player = MorsePlaybackController(
      sink: sink,
      clock: clock,
      sidetone: tone,
    );
    player.keyingToneHz = 550;
    addTearDown(player.dispose);
    final start = player.play(
      'm',
      'T',
      const MorseTiming(wpm: 20),
      toneHz: 900,
    );
    player.pause();
    player.keyingSink.on();
    player.resume();
    records.clear();
    sink.ready.complete();
    await start;
    expect(
      records.log,
      isEmpty,
      reason: 'Playback must not start while live key is held',
    );
    expect(
      records.isOn,
      isTrue,
      reason: 'Playback must not silence the live mark',
    );
    expect(player.isPaused, isTrue);
    expect(
      tone.frequencyHz,
      550,
      reason: 'Preparation must not retune the held live key',
    );
    player.keyingSink.off();
    records.clear();
    clock.advance(
      MorsePlaybackController.keyingHoldoff - const Duration(milliseconds: 1),
    );
    expect(
      records.log,
      isEmpty,
      reason: 'Clip must not release a live mark or run before holdoff',
    );
    expect(tone.frequencyHz, 550);
    clock.advance(const Duration(milliseconds: 1));
    expect(records.log, [(true, 1500)]);
    expect(
      tone.frequencyHz,
      900,
      reason: 'The resumed clip uses its listening tone',
    );
    expect(player.isPaused, isFalse);
  });
  test(
    'preparation preserves an explicit manual pause after keying rests',
    () async {
      final clock = FakeClock();
      final records = RecordingSink(clock: clock);
      final sink = _SlowSink(records);
      final player = MorsePlaybackController(sink: sink, clock: clock);
      addTearDown(player.dispose);
      final start = player.play('m', 'T', const MorseTiming(wpm: 20));
      player.pause();
      player.keyingSink.on();
      player.keyingSink.off();
      records.clear();
      sink.ready.complete();
      await start;
      clock.advance(const Duration(seconds: 2));
      expect(records.log, isEmpty);
      expect(player.manuallyPaused, isTrue);
      player.resume();
      expect(records.log, [(true, 2000)]);
    },
  );
}
