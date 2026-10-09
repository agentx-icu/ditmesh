import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/keyed_draft_recording.dart';

void main() {
  test(
    'actual spans survive word silence and deletion removes corrected mark',
    () {
      final draft = KeyedDraftRecording();
      final clock = Object();
      draft.append('', KeyedChunk('E', [73], 10, 83, clock));
      draft.append('E', KeyedChunk(' ', const [], 0, 0, clock));
      draft.append('E ', KeyedChunk('T', [249], 600, 849, clock));
      expect(draft.forText('E T')?.durationsMs, [73, 517, 249]);
      draft.reconcile('E ');
      draft.append('E ', KeyedChunk('E', [91], 1000, 1091, clock));
      expect(draft.forText('E E')?.durationsMs, [73, 917, 91]);
    },
  );
  test(
    'restored text, external edit and different clock never claim original',
    () {
      final draft = KeyedDraftRecording();
      final clock = Object();
      draft.append('CQ', KeyedChunk('E', [73], 10, 83, clock));
      expect(draft.forText('CQE'), isNull);
      draft.reconcile('');
      draft.append('', KeyedChunk('E', [73], 10, 83, clock));
      draft.append('E', KeyedChunk('T', [220], 400, 620, Object()));
      expect(draft.forText('ET'), isNull);
      draft.reconcile('');
      draft.append('', KeyedChunk('E', [73], 10, 83, clock));
      draft.reconcile('A');
      expect(draft.forText('A'), isNull);
    },
  );
  test('unknown patterns are atomic and bounds fail honestly', () {
    final draft = KeyedDraftRecording();
    final clock = Object();
    draft.append(
      '',
      KeyedChunk(
        '<..--.>',
        [60, 60, 61, 61, 200, 62, 201, 63, 64],
        0,
        932,
        clock,
      ),
    );
    expect(draft.forText('<..--.>')?.durationsMs.length, 9);
    draft.reconcile('');
    draft.append('', KeyedChunk('E', [120001], 0, 120001, clock));
    expect(draft.forText('E'), isNull);
  });
}
