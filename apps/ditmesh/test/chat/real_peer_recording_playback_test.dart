import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:ditmesh/ui/chat/playback_timeline.dart';

import '../../../../packages/ditmesh_chat/test/helpers/real_peer_rhythm.dart';

void main() {
  test('real native message fixtures retain every playable original span', () {
    for (final sender in ['alice', 'bob']) {
      for (final text in [
        'CQ DE ${sender.toUpperCase()}',
        'CQ NET ${sender.toUpperCase()}',
        'R NET ${sender.toUpperCase()}',
        'CQ SAME',
        'CQ AFTER RESTART',
        'RJ0 ${sender.toUpperCase()}',
        '1234567890',
      ]) {
        final recording = realPeerRhythm(sender, text);
        final timeline = PlaybackTimeline(
          text,
          const MorseTiming(wpm: 40, farnsworthWpm: 5),
          recording: recording,
          original: true,
        );
        expect(timeline.isOriginal, isTrue, reason: '$sender: $text');
        expect(
          timeline.elements.map((element) => element.duration.inMilliseconds),
          recording.durationsMs,
        );
      }
    }
  });
}
