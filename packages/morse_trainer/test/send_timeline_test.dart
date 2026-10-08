import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

/// Marks and gaps of [text] keyed perfectly at [timing], optionally
/// stretched by [markScale] for dahs.
(List<Duration>, List<Duration>) keyed(
  String text,
  MorseTiming timing, {
  double dahScale = 1,
}) {
  final marks = <Duration>[];
  final gaps = <Duration>[];
  for (final e in MorseEncoder.encode(text, timing)) {
    if (e.on) {
      marks.add(
        e.kind == MorseElementKind.dah ? e.duration * dahScale : e.duration,
      );
    } else {
      gaps.add(e.duration);
    }
  }
  return (marks, gaps);
}

void main() {
  const t20 = MorseTiming(wpm: 20);
  const dit = Duration(milliseconds: 60);

  test('clean sending is not misdiagnosed', () {
    final (m, g) = keyed('PARIS PARIS', t20);
    final tl = SendTimeline.build(
      target: 'PARIS PARIS',
      marks: m,
      gaps: g,
      timing: t20,
      estimatedDit: dit,
    );
    expect(tl.aligned, isTrue);
    expect(tl.issues, isEmpty);
    expect(tl.symbols, hasLength(10));
    expect(tl.problemSymbols, isEmpty);
  });

  test('a deliberately long dah is identified on its symbol', () {
    final (m, g) = keyed('KM', t20);
    // Stretch the first dah of M only (index 3 overall: K = -.-, M = --).
    m[3] = dit * 5;
    final tl = SendTimeline.build(
      target: 'KM',
      marks: m,
      gaps: g,
      timing: t20,
      estimatedDit: dit,
    );
    expect(tl.perSymbol[1].issues, {RhythmIssue.dahTooLong});
    expect(tl.perSymbol[0].issues, isEmpty);
    expect(tl.problemSymbols.single.symbol, 'M');
  });

  test('valid Farnsworth gaps are not flagged', () {
    const farns = MorseTiming(wpm: 20, farnsworthWpm: 8);
    final (m, g) = keyed('CQ DE K', farns);
    final tl = SendTimeline.build(
      target: 'CQ DE K',
      marks: m,
      gaps: g,
      timing: farns,
      estimatedDit: dit,
    );
    expect(tl.aligned, isTrue);
    expect(tl.issues, isEmpty);
    // Gaps are classified by the target's structure, not ratio guesses.
    expect(
      tl.mine.where((e) => e.kind == RhythmElementKind.wordGap),
      hasLength(2),
    );
  });

  test('crowded characters are flagged as too-short gaps', () {
    final (m, g) = keyed('KM', t20);
    // The char gap between K and M (after K's 3 marks: gap index 2):
    // still a boundary (>= 2 dits) but shorter than 2.5 dits.
    g[2] = dit * 2.2;
    final tl = SendTimeline.build(
      target: 'KM',
      marks: m,
      gaps: g,
      timing: t20,
      estimatedDit: dit,
    );
    expect(tl.perSymbol[1].issues, contains(RhythmIssue.charGapTooShort));
  });

  test('replay keeps exact order and durations, repeatably', () {
    final (m, g) = keyed('KM', t20, dahScale: 1.1);
    final tl = SendTimeline.build(
      target: 'KM',
      marks: m,
      gaps: g,
      timing: t20,
      estimatedDit: dit,
    );
    final a = tl.myElements;
    final b = tl.myElements;
    expect(a, b);
    expect(a.where((e) => e.on).map((e) => e.duration), m);
    expect(a.where((e) => !e.on).map((e) => e.duration), g);
    final k = tl.myElementsFor(0);
    expect(k.where((e) => e.on), hasLength(3));
    expect(tl.standardElementsFor(1).map((e) => e.kind), [
      MorseElementKind.dah,
      MorseElementKind.intraGap,
      MorseElementKind.dah,
    ]);
  });

  test('unmatched marks report failed localisation instead of guessing', () {
    final (m, g) = keyed('KM', t20);
    m.removeLast();
    g.removeLast();
    final tl = SendTimeline.build(
      target: 'KM',
      marks: m,
      gaps: g,
      timing: t20,
      estimatedDit: dit,
    );
    expect(tl.aligned, isFalse);
    expect(tl.perSymbol.every((s) => !s.located && s.issues.isEmpty), isTrue);
  });

  test('prosigns are one symbol in the timeline', () {
    final (m, g) = keyed('<AR>', t20);
    final tl = SendTimeline.build(
      target: '<AR>',
      marks: m,
      gaps: g,
      timing: t20,
      estimatedDit: dit,
    );
    expect(tl.symbols, ['<AR>']);
    expect(tl.aligned, isTrue);
  });

  test('send diagnostics also report long dahs now', () {
    final d = SendAttempt(
      target: 'T',
      decoded: 'T',
      marks: [dit * 6],
      gaps: const [],
      estimatedDit: dit,
    ).evaluate();
    expect(d.hasIssue(SendIssueKind.dahTooLong), isTrue);
  });

  test('a merged character gap cannot be pinned to symbols', () {
    final (m, g) = keyed('KM', t20);
    g[2] = dit;
    final tl = SendTimeline.build(
      target: 'KM',
      marks: m,
      gaps: g,
      timing: t20,
      estimatedDit: dit,
    );
    expect(tl.aligned, isFalse);
  });

  test('equal mark counts with another structure are not aligned', () {
    // IE keyed for EI: three dits either way, boundaries differ.
    final (m, g) = keyed('IE', t20);
    final tl = SendTimeline.build(
      target: 'EI',
      marks: m,
      gaps: g,
      timing: t20,
      estimatedDit: dit,
    );
    expect(tl.aligned, isFalse);
    expect(tl.issues, isEmpty);
  });
}
