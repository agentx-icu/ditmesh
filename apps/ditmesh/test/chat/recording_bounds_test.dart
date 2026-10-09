import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/keyed_draft_recording.dart';
import 'package:morse_io/morse_io.dart';

class _Target implements KeyTarget {
  @override
  void keyDown(Duration at) {}
  @override
  void keyUp(Duration at) {}
}

void main() {
  test('capture overflow invalidates that token and recovers for the next', () {
    final target = RecordingKeyTarget(_Target(), Object());
    for (var i = 0; i < 300; i++) {
      target.keyDown(Duration(milliseconds: i * 2));
      target.keyUp(Duration(milliseconds: i * 2 + 1));
    }
    expect(target.consume('<${'.' * 300}>').spans, isEmpty);
    target.keyDown(const Duration(milliseconds: 1000));
    target.keyUp(const Duration(milliseconds: 1073));
    expect(target.consume('E').spans, [73]);
  });
  test('a draft exceeding bounds stays text-only until cleared', () {
    final draft = KeyedDraftRecording();
    final clock = Object();
    var text = '';
    for (var i = 0; i < 300; i++) {
      draft.append(text, KeyedChunk('E', [73], i * 200, i * 200 + 73, clock));
      text += 'E';
    }
    expect(draft.forText(text), isNull);
    draft.reconcile('');
    draft.append('', KeyedChunk('E', [73], 100000, 100073, clock));
    expect(draft.forText('E')?.durationsMs, [73]);
  });
}
