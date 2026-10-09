import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/morse_playback_controller.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/testing.dart';
import 'package:morse_io/morse_io.dart';

void main() {
  const timing = MorseTiming(wpm: 20);
  test(
    'original plays exact durations and manual pause keeps the remaining mark',
    () async {
      final clock = FakeClock();
      final sink = RecordingSink(clock: clock);
      final foreground = _Foreground();
      final player = MorsePlaybackController(
        sink: sink,
        clock: clock,
        foreground: foreground,
      );
      addTearDown(player.dispose);
      await player.play(
        'm',
        'E T',
        timing,
        recording: KeyedRecording(durationsMs: [73, 517, 249]),
        original: true,
      );
      expect(player.usingOriginal, isTrue);
      clock.advance(const Duration(milliseconds: 31));
      player.pause();
      expect(player.isPaused, isTrue);
      expect(player.elapsed.inMilliseconds, 31);
      foreground.set(false);
      clock.advance(const Duration(milliseconds: 500));
      foreground.set(true);
      await Future<void>.delayed(Duration.zero);
      expect(player.isPaused, isTrue);
      player.resume();
      clock.advance(const Duration(milliseconds: 42));
      expect(sink.log, [(true, 0), (false, 31), (true, 531), (false, 573)]);
      clock.advance(const Duration(milliseconds: 517));
      expect(player.activeWord, 1);
      clock.advance(const Duration(milliseconds: 249));
      expect(player.playingId, isNull);
    },
  );
  test(
    'a manually paused message survives keying and resume waits for quiet',
    () async {
      final clock = FakeClock();
      final sink = RecordingSink(clock: clock);
      final player = MorsePlaybackController(sink: sink, clock: clock);
      addTearDown(player.dispose);
      await player.play('m', 'T', timing);
      clock.advance(const Duration(milliseconds: 30));
      player.pause();
      player.keyingSink.on();
      expect(player.playingId, 'm');
      clock.advance(const Duration(milliseconds: 100));
      player.resume();
      expect(player.isPaused, isTrue);
      player.keyingSink.off();
      sink.clear();
      clock.advance(
        MorsePlaybackController.keyingHoldoff - const Duration(milliseconds: 1),
      );
      expect(sink.log, isEmpty);
      clock.advance(const Duration(milliseconds: 1));
      expect(player.isPaused, isFalse);
      expect(sink.log.single.$1, isTrue);
    },
  );
  test(
    'word navigation during live keying waits without touching the sink',
    () async {
      final clock = FakeClock();
      final sink = RecordingSink(clock: clock);
      final player = MorsePlaybackController(sink: sink, clock: clock);
      addTearDown(player.dispose);
      await player.play('m', 'E T', timing);
      player.pause();
      player.keyingSink.on();
      sink.clear();
      await player.seekWord(1);
      expect(player.playingId, isNull);
      expect(player.queuedIds, ['m']);
      expect(sink.log, isEmpty);
      player.keyingSink.off();
      clock.advance(MorsePlaybackController.keyingHoldoff);
      await Future<void>.delayed(Duration.zero);
      expect(player.playingId, 'm');
      expect(player.isPaused, isTrue);
      expect(player.activeWord, 1);
    },
  );
  test(
    'word navigation and bounded range loop keep global mark positions',
    () async {
      final clock = FakeClock();
      final sink = RecordingSink(clock: clock);
      final player = MorsePlaybackController(sink: sink, clock: clock);
      addTearDown(player.dispose);
      await player.play('m', 'E T E', timing);
      await player.seekWord(1);
      expect(player.activeWord, 1);
      expect(player.activeMarkFor('m'), 1);
      player.pause();
      await player.previousWord();
      expect(player.isPaused, isTrue);
      expect(player.activeWord, 0);
      player.resume();
      await player.setWordRange(1, 1, loop: true);
      expect(player.total.inMilliseconds, 180);
      clock.advance(const Duration(milliseconds: 180));
      await Future<void>.delayed(Duration.zero);
      expect(player.playingId, 'm');
      expect(player.activeWord, 1);
      expect(player.rangeStart, 1);
      player.stop();
      clock.advance(const Duration(milliseconds: 1000));
      expect(player.playingId, isNull);
    },
  );
}

class _Foreground implements AppForeground {
  @override
  bool isForeground = true;
  final callbacks = <void Function(bool)>[];
  @override
  void Function() listen(void Function(bool) callback) {
    callbacks.add(callback);
    return () => callbacks.remove(callback);
  }

  void set(bool value) {
    isForeground = value;
    for (final callback in callbacks.toList()) {
      callback(value);
    }
  }
}
