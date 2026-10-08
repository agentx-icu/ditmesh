import 'package:morse_core/morse_core.dart';
import 'package:test/test.dart';

void main() {
  test('four-digit groups keep leading zeros and list every candidate', () {
    final tokens = TelegraphGroups.parse('0022 0948');
    expect(tokens.map((t) => t.source), ['0022', '0948']);
    expect(tokens.first.kind, TelegraphTokenKind.group);
    expect(tokens.first.candidates, contains('中'));
    expect(
      tokens.first.candidates,
      ChineseTelegraphCode.charsOf('0022'),
      reason: 'the shared table, not a second mapping',
    );
  });

  test('mixed text, long runs, short runs and unknown codes are kept and '
      'flagged', () {
    final tokens = TelegraphGroups.parse('CQ 0022  12345678 123 9999 DE');
    expect(tokens.map((t) => t.kind), [
      TelegraphTokenKind.text,
      TelegraphTokenKind.group,
      TelegraphTokenKind.malformedDigits,
      TelegraphTokenKind.malformedDigits,
      TelegraphTokenKind.group,
      TelegraphTokenKind.text,
    ]);
    expect(tokens[2].source, '12345678', reason: 'never split');
    expect(tokens[4].isUnresolved, isTrue);
    expect(tokens.last.source, 'DE');
  });

  test('every candidate comes back; none is chosen silently', () {
    // The Unihan 18 tables happen to assign no code to two characters, but
    // the parser must still return the full list whatever the table says.
    for (final book in TelegraphCodebook.values) {
      for (var c = 0; c < 10000; c += 7) {
        final code = ChineseTelegraphCode.format(c);
        final t = TelegraphGroups.parse(code, codebook: book).single;
        final all = ChineseTelegraphCode.charsOf(code, codebook: book);
        expect(t.candidates, all);
        expect(t.isAmbiguous, all.length > 1);
        expect(t.isUnresolved, all.isEmpty);
      }
    }
  });

  test('mainland and Taiwan differ and are both reachable', () {
    final m = ChineseTelegraphCode.codeOf('国');
    final t = ChineseTelegraphCode.codeOf('國', codebook: TelegraphCodebook.taiwan);
    expect(m, isNotNull);
    expect(t, isNotNull);
    expect(
      TelegraphGroups.parse(t!, codebook: TelegraphCodebook.taiwan).single.candidates,
      contains('國'),
    );
  });

  test('hasGroups needs an explicit four-digit token', () {
    expect(TelegraphGroups.hasGroups('QSO at 1530 UTC'), isTrue);
    expect(TelegraphGroups.hasGroups('599 TU 73'), isFalse);
    expect(TelegraphGroups.hasGroups('12345'), isFalse);
  });
}
