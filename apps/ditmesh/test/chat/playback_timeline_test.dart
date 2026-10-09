import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/playback_timeline.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:morse_core/morse_core.dart';

void main() {
  const timing = MorseTiming(wpm: 20);
  test(
    'original spans remain exact while word and mark positions follow text',
    () {
      final recording = KeyedRecording(durationsMs: [73, 517, 249]);
      final timeline = PlaybackTimeline(
        'E T',
        timing,
        recording: recording,
        original: true,
      );
      expect(timeline.isOriginal, isTrue);
      expect(timeline.elements.map((e) => e.duration.inMilliseconds), [
        73,
        517,
        249,
      ]);
      expect(timeline.words, ['E', 'T']);
      expect(timeline.wordStarts, [0, 2]);
      expect(timeline.markStarts, [0, 1]);
    },
  );
  test(
    'mismatched recording falls back and raw unknown patterns stay atomic',
    () {
      final bad = PlaybackTimeline(
        'SOS',
        timing,
        recording: KeyedRecording(durationsMs: [73]),
        original: true,
      );
      expect(bad.isOriginal, isFalse);
      final raw = PlaybackTimeline('<..--.> <AR>', timing);
      expect(raw.words, ['<..--.>', '<AR>']);
      expect(raw.elements.where((e) => e.on).length, 10);
    },
  );
}
