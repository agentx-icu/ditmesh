import 'package:ditmesh_chat/src/chat/recording_metadata.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('optional recorded timings round trip without changing the text', () {
    final recording = KeyedRecording(durationsMs: [83, 113, 251]);
    expect(
      RecordingMetadata.decode(RecordingMetadata.encode(recording)),
      recording,
    );
    for (final invalid in [
      null,
      '',
      'not JSON',
      '{"ditmeshRhythm":{"version":2}}',
    ]) {
      expect(RecordingMetadata.decode(invalid), isNull);
    }
  });
}
