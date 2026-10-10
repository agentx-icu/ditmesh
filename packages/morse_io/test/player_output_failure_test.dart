import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';

final class _FailingOutput implements MorseSink {
  int marks = 0;
  int failMark = 2;
  bool failRelease = false;
  bool isOn = false;
  final error = StateError('device lost output');
  @override
  Future<void> prepare() async {}
  @override
  Future<void> dispose() async {}
  @override
  void on() {
    if (++marks == failMark) throw error;
    isOn = true;
  }

  @override
  void off() {
    isOn = false;
    if (failRelease) throw StateError('release failed');
  }
}

void main() {
  test(
    'opt-in player reports later output failure and never completes',
    () async {
      final clock = FakeClock();
      final sink = _FailingOutput();
      final player = MorsePlayer(
        sink: sink,
        clock: clock,
        reportOutputFailures: true,
      );
      final events = <PlayerEvent>[];
      player.events.listen(events.add);
      player.play(MorseEncoder.encode('EE', const MorseTiming(wpm: 20)));
      expect(() => clock.advance(const Duration(seconds: 10)), returnsNormally);
      expect(player.isPlaying, isFalse);
      expect(player.currentIndex, -1);
      expect(clock.pendingTimers, 0);
      expect(sink.isOn, isFalse);
      expect(events.whereType<PlayerCompleted>(), isEmpty);
      final failure = events.whereType<PlayerStopped>().single;
      expect(failure.error, same(sink.error));
      expect(failure.stackTrace, isNotNull);
      await player.dispose();
    },
  );

  test(
    'elapsed returns to zero when an output failure stops playback',
    () async {
      final clock = FakeClock();
      final sink = _FailingOutput();
      final player = MorsePlayer(
        sink: sink,
        clock: clock,
        reportOutputFailures: true,
      );
      final elapsedAtStop = <Duration>[];
      player.events.listen((event) {
        if (event is PlayerStopped) elapsedAtStop.add(player.elapsed);
      });
      final timeline = MorseEncoder.encode('EE', const MorseTiming(wpm: 20));
      final secondMarkAt = timeline.first.duration + timeline[1].duration;
      player.play(timeline);
      clock.advance(secondMarkAt - const Duration(milliseconds: 10));
      expect(player.isPlaying, isTrue);
      expect(player.elapsed, secondMarkAt - const Duration(milliseconds: 10));

      clock.advance(const Duration(milliseconds: 20)); // second mark fails
      expect(player.isPlaying, isFalse);
      expect(elapsedAtStop, <Duration>[Duration.zero]);
      expect(player.elapsed, Duration.zero);
      clock.advance(const Duration(seconds: 1));
      expect(player.elapsed, Duration.zero);
      await player.dispose();
    },
  );

  test(
    'a paused start touches no output until resume reports the failure',
    () async {
      final clock = FakeClock();
      final sink = _FailingOutput()..failMark = 1;
      final player = MorsePlayer(
        sink: sink,
        clock: clock,
        reportOutputFailures: true,
      );
      final events = <PlayerEvent>[];
      player.events.listen(events.add);
      player.play(
        MorseEncoder.encode('E', const MorseTiming(wpm: 20)),
        paused: true,
      );
      clock.advance(const Duration(seconds: 1));
      expect(sink.marks, 0, reason: 'silent while paused');
      expect(events.whereType<PlayerStopped>(), isEmpty);
      player.resume();
      expect(sink.marks, 1);
      expect(player.isPlaying, isFalse);
      expect(player.elapsed, Duration.zero);
      expect(clock.pendingTimers, 0);
      expect(events.whereType<PlayerStopped>().single.error, same(sink.error));
      await player.dispose();
    },
  );

  test('failed release reports diagnostics and cancels the timeline', () async {
    final clock = FakeClock();
    final sink = _FailingOutput()..failRelease = true;
    final player = MorsePlayer(
      sink: sink,
      clock: clock,
      reportOutputFailures: true,
    );
    final events = <PlayerEvent>[];
    player.events.listen(events.add);
    player.play(MorseEncoder.encode('EE', const MorseTiming(wpm: 20)));
    expect(() => clock.advance(const Duration(seconds: 10)), returnsNormally);
    final failure = events.whereType<PlayerStopped>().single;
    expect(failure.error, isA<StateError>());
    expect(failure.cleanupError, isA<StateError>());
    expect(events.whereType<PlayerCompleted>(), isEmpty);
    expect(clock.pendingTimers, 0);
    await player.dispose();
  });

  test('default player preserves synchronous output error behavior', () async {
    final clock = FakeClock();
    final sink = _FailingOutput()..failMark = 1;
    final player = MorsePlayer(sink: sink, clock: clock);
    expect(
      () => player.play(MorseEncoder.encode('E', const MorseTiming(wpm: 20))),
      throwsA(same(sink.error)),
    );
    await player.dispose();
  });
}
