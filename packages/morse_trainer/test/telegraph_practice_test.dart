import 'dart:math';

import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  test('the curated list is coded in both codebooks', () {
    expect(TelegraphCurriculum.introductoryFor(TelegraphCodebook.mainland).length, greaterThanOrEqualTo(45));
    expect(TelegraphCurriculum.introductoryFor(TelegraphCodebook.taiwan).length, greaterThanOrEqualTo(45));
  });

  test('source refs carry the codebook and table version', () {
    final ref = TelegraphCurriculum.sourceRef(TelegraphCodebook.taiwan);
    expect(ref, 'telegraph:taiwan:${ChineseTelegraphCode.unicodeVersion}');
    expect(TelegraphCurriculum.codebookOf(ref), TelegraphCodebook.taiwan);
    expect(TelegraphCurriculum.codebookOf('chat:x'), isNull);
    expect(TelegraphCurriculum.codebookOf(null), isNull);
  });

  test('digit drill: real four-digit codes, leading zeros, digit symbols', () {
    final drill = TelegraphDigitsDrill(chars: ['中', '一'], groupCount: 2);
    expect(drill.codes, containsAll(['0022', '0001']));
    final d = drill.generate(Random(1));
    expect(d.text, matches(RegExp(r'^\d{4} \d{4}$')));
    expect(d.chars, TelegraphDigitsDrill.digitSymbols);
    final ofCodes = TelegraphDigitsDrill.ofCodes(['0022', '12', 'abcd', '0022']);
    expect(ofCodes.codes, ['0022']);
    expect(() => TelegraphDigitsDrill.ofCodes(const []).generate(Random()), throwsStateError);
    // Copy scoring is ordinary Morse digit scoring.
    final score = SessionScore.evaluate('0022', '0012');
    expect(score.totalChars, 4);
    expect(score.correctChars, 3);
  });

  test('recall cards accept every equivalent form', () {
    final r = Random(3);
    final toCode = TelegraphRecallCard.make('中', TelegraphRecallDirection.charToCode, TelegraphCodebook.mainland, r);
    expect(toCode.isCorrect('0022'), isTrue);
    expect(toCode.isCorrect('22'), isFalse, reason: 'leading zeros matter');
    final pool = TelegraphCurriculum.introductoryFor(TelegraphCodebook.mainland);
    final toChar = TelegraphRecallCard.make('中', TelegraphRecallDirection.codeToChar, TelegraphCodebook.mainland, r, distractors: pool);
    expect(toChar.choices, contains('中'));
    expect(toChar.choices.toSet(), hasLength(toChar.choices.length));
    for (final c in ChineseTelegraphCode.charsOf('0022')) {
      expect(toChar.isCorrect(c), isTrue);
    }
  });

  test('recall stats: separate per codebook, assisted never known, json', () {
    var s = TelegraphRecallStats.empty;
    s = s.record(TelegraphCodebook.mainland, '中', correct: true, assisted: false);
    s = s.record(TelegraphCodebook.mainland, '国', correct: true, assisted: true);
    s = s.record(TelegraphCodebook.taiwan, '國', correct: false, assisted: false);
    expect(s.of(TelegraphCodebook.mainland, '国'), (1, 0, 1));
    expect(s.accuracy(TelegraphCodebook.mainland), 1.0);
    expect(s.accuracy(TelegraphCodebook.taiwan), 0.0);
    expect(s.answered(TelegraphCodebook.mainland), 2);
    final back = TelegraphRecallStats.fromJson(s.toJson());
    expect(back.of(TelegraphCodebook.taiwan, '國'), (1, 0, 0));
    // Entries are keyed by the mapping-table version they were recorded on.
    expect(
      (back.toJson()['entries']! as Map).keys,
      everyElement(contains('/${ChineseTelegraphCode.unicodeVersion}/')),
    );
    expect(TelegraphRecallStats.isNewer({'v': 2}), isTrue);
    expect(TelegraphRecallStats.isNewer({'v': 1}), isFalse);
    expect(TelegraphRecallStats.fromJson({'v': 99}).answered(TelegraphCodebook.mainland), 0);
  });
}
