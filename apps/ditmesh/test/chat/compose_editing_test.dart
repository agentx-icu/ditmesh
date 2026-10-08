import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/compose_editing.dart';

/// Delete-last removes what the decoder appended as one unit (M7).
void main() {
  final cases = <String, String>{
    '': '',
    'CQ': 'C',
    'CQ <SK>': 'CQ ',
    '<SK>': '',
    'E<..--.>': 'E',
    '<AR><SK>': '<AR>',
    'CQ ': 'CQ',
    '<SK> ': '<SK>',
    '<>': '<',
    'A<': 'A',
    '>': '',
    'A<B<C>': 'A<B',
    'E <AR': 'E <A',
    'café': 'caf',
    'café': 'caf',
    'A\u{1F1E9}\u{1F1EA}': 'A',
    'A\u{1F468}‍\u{1F469}‍\u{1F467}': 'A',
    'A\u{1F600}': 'A',
  };
  for (final MapEntry<String, String> c in cases.entries) {
    test('"${c.key}" -> "${c.value}"', () {
      expect(withoutLastKeyedUnit(c.key), c.value);
    });
  }
}
