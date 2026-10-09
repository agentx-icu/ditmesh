import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:test/test.dart';

void main() {
  test(
    'recording owns immutable alternating durations and round trips JSON',
    () {
      final durations = [80, 123, 260];
      final recording = KeyedRecording(durationsMs: durations);
      durations[0] = 999;
      expect(recording.durationsMs, [80, 123, 260]);
      expect(recording.totalDuration, const Duration(milliseconds: 463));
      expect(() => recording.durationsMs[0] = 1, throwsUnsupportedError);
      expect(KeyedRecording.fromJson(recording.toJson()), recording);
    },
  );

  test('untrusted recordings reject invalid spans and excessive duration', () {
    for (final spans in <List<int>>[
      [],
      [1, 2],
      [0],
      [-1],
      [KeyedRecording.maxTotalDurationMs + 1],
      [9223372036854775807, 1, 1],
      [KeyedRecording.maxTotalDurationMs, 1, 1],
      List.filled(KeyedRecording.maxSpans + 2, 1),
    ]) {
      expect(() => KeyedRecording(durationsMs: spans), throwsArgumentError);
    }
    for (final value in <Object?>[
      null,
      {},
      {
        'version': 2,
        'durationsMs': [80],
      },
      {
        'version': 1,
        'durationsMs': [80.0],
      },
      {
        'version': 1,
        'durationsMs': [80, 0, 80],
      },
      {
        'version': 1,
        'durationsMs': [9223372036854775807, 1, 1],
      },
    ]) {
      expect(KeyedRecording.fromJson(value), isNull);
    }
  });

  test('fake sends retain recording through queue and copyWith', () async {
    const peer =
        'CDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCD';
    final chat = FakeChatService()
      ..addFakeFriend(const Friend(publicKey: peer, displayName: 'Bob'));
    final recording = KeyedRecording(durationsMs: [80, 123, 260]);
    try {
      final row = await chat.sendText('c2c_$peer', 'CQ', recording: recording);
      expect(row.recording, recording);
      expect(row.copyWith(status: MessageStatus.sent).recording, recording);
      expect((await chat.loadHistory('c2c_$peer')).single.recording, recording);
    } finally {
      await chat.dispose();
    }
  });
}
