import 'package:morse_core/morse_core.dart';

import 'morse_text.dart';

/// What one timeline element is.
enum RhythmElementKind { dit, dah, intraGap, charGap, wordGap }

/// Problems a single element can show (functional spec §7.2).
enum RhythmIssue {
  ditTooLong,
  dahTooShort,

  /// New in F04: dahs held far beyond three dits.
  dahTooLong,
  intraGapTooLong,
  charGapTooShort,
  wordGapTooShort,
}

/// Centralised thresholds, in units of the operator's own estimated dit.
final class RhythmThresholds {
  const RhythmThresholds({
    this.ditTooLong = 1.3,
    this.dahTooShort = 2.6,
    this.dahTooLong = 4.0,
    this.intraGapTooLong = 1.3,
    this.charGapTooShort = 2.5,
    this.wordGapTooShort = 6.0,
    this.charBoundary = 2.0,
    this.wordBoundary = 5.0,
  });

  final double ditTooLong;
  final double dahTooShort;
  final double dahTooLong;
  final double intraGapTooLong;
  final double charGapTooShort;
  final double wordGapTooShort;

  /// Unaligned gaps at or above these ratios split characters / words.
  final double charBoundary;
  final double wordBoundary;
}

/// One measured or standard element.
final class RhythmElement {
  const RhythmElement({
    required this.kind,
    required this.start,
    required this.duration,
    this.symbolIndex,
    this.issue,
    this.ratioToEstimate,
    this.ratioToTarget,
  });

  final RhythmElementKind kind;

  /// Offset from the first key-down (monotonic, relative).
  final Duration start;
  final Duration duration;

  /// Index into [SendTimeline.symbols]; null when it could not be placed.
  final int? symbolIndex;
  final RhythmIssue? issue;

  /// Length in the operator's own estimated dits (the diagnosis).
  final double? ratioToEstimate;

  /// Length relative to the same element at the target speed.
  final double? ratioToTarget;

  bool get isMark =>
      kind == RhythmElementKind.dit || kind == RhythmElementKind.dah;

  Duration get end => start + duration;
}

/// Per-symbol summary for cards and targeted practice.
final class SymbolRhythm {
  const SymbolRhythm({
    required this.index,
    required this.symbol,
    required this.issues,
    required this.located,
  });

  final int index;
  final String symbol;
  final Set<RhythmIssue> issues;

  /// False when the measured marks could not be pinned to this symbol.
  final bool located;
}

/// "My rhythm" versus "Standard rhythm" for one send attempt.
///
/// Standard timing comes from [MorseTiming] at the target speed (with
/// Farnsworth gaps when set). The diagnosis is normalised to the
/// operator's estimated dit, so a slow but even fist is not flagged; the
/// comparison with the target speed is reported separately. When the
/// marks cannot be matched to the target symbol by symbol, the timeline
/// says so ([aligned] false) instead of forcing marks onto wrong symbols.
final class SendTimeline {
  SendTimeline._({
    required this.target,
    required this.symbols,
    required this.mine,
    required this.standard,
    required this.perSymbol,
    required this.aligned,
    required this.estimatedDit,
  });

  /// Bumped whenever the rules change, stored with saved details.
  static const int diagnosticVersion = 1;

  factory SendTimeline.build({
    required String target,
    required List<Duration> marks,
    required List<Duration> gaps,
    required MorseTiming timing,
    required Duration estimatedDit,
    RhythmThresholds thresholds = const RhythmThresholds(),
  }) {
    final words = target
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final symbols = <String>[];
    final patterns = <String>[];
    final wordStart = <bool>[];
    for (final word in words) {
      var first = true;
      for (final token in MorseText.symbols(word)) {
        final pattern = token.startsWith('<')
            ? MorseAlphabet.encodeProsign(token)
            : MorseAlphabet.encodeChar(token);
        if (pattern == null) continue;
        symbols.add(token);
        patterns.add(pattern);
        wordStart.add(first);
        first = false;
      }
    }
    final standard = _standard(patterns, wordStart, timing);
    final ditUs = estimatedDit.inMicroseconds > 0
        ? estimatedDit.inMicroseconds
        : timing.dit.inMicroseconds;
    final expectedMarks = standard.where((e) => e.isMark).toList();
    final expectedGaps = standard.where((e) => !e.isMark).toList();
    // Equal counts are not enough (`IE` keyed for `EI` has three marks
    // too): every mark must have the expected class and every measured
    // character boundary must sit where the target has one.
    final aligned =
        marks.isNotEmpty &&
        marks.length == expectedMarks.length &&
        gaps.length >= marks.length - 1 &&
        _structureMatches(
          marks,
          gaps,
          expectedMarks,
          expectedGaps,
          ditUs,
          thresholds,
        );

    final mine = <RhythmElement>[];
    var at = Duration.zero;
    for (var i = 0; i < marks.length; i++) {
      final m = marks[i];
      final exp = aligned ? expectedMarks[i] : null;
      final r = m.inMicroseconds / ditUs;
      final kind =
          exp?.kind ?? (r < 2 ? RhythmElementKind.dit : RhythmElementKind.dah);
      mine.add(
        RhythmElement(
          kind: kind,
          start: at,
          duration: m,
          symbolIndex: exp?.symbolIndex,
          ratioToEstimate: r,
          ratioToTarget: exp == null
              ? null
              : m.inMicroseconds / exp.duration.inMicroseconds,
          issue: _markIssue(kind, r, thresholds),
        ),
      );
      at += m;
      if (i < gaps.length && i < marks.length - 1) {
        final g = gaps[i];
        final gr = g.inMicroseconds / ditUs;
        final expGap = aligned ? expectedGaps[i] : null;
        final gkind =
            expGap?.kind ??
            (gr < thresholds.charBoundary
                ? RhythmElementKind.intraGap
                : gr < thresholds.wordBoundary
                ? RhythmElementKind.charGap
                : RhythmElementKind.wordGap);
        mine.add(
          RhythmElement(
            kind: gkind,
            start: at,
            duration: g,
            symbolIndex: expGap?.symbolIndex,
            ratioToEstimate: gr,
            ratioToTarget: expGap == null
                ? null
                : g.inMicroseconds / expGap.duration.inMicroseconds,
            issue: _gapIssue(gkind, gr, thresholds),
          ),
        );
        at += g;
      }
    }

    final perSymbol = <SymbolRhythm>[
      for (var i = 0; i < symbols.length; i++)
        SymbolRhythm(
          index: i,
          symbol: symbols[i],
          located: aligned,
          issues: aligned
              ? mine
                    .where((e) => e.symbolIndex == i && e.issue != null)
                    .map((e) => e.issue!)
                    .toSet()
              : const <RhythmIssue>{},
        ),
    ];
    return SendTimeline._(
      target: target,
      symbols: symbols,
      mine: mine,
      standard: standard,
      perSymbol: perSymbol,
      aligned: aligned,
      estimatedDit: Duration(microseconds: ditUs),
    );
  }

  final String target;
  final List<String> symbols;
  final List<RhythmElement> mine;
  final List<RhythmElement> standard;
  final List<SymbolRhythm> perSymbol;
  final bool aligned;
  final Duration estimatedDit;

  /// Every issue found anywhere (also when not located to a symbol).
  Set<RhythmIssue> get issues =>
      mine.where((e) => e.issue != null).map((e) => e.issue!).toSet();

  /// Symbols with problems, worst (most issues) first.
  List<SymbolRhythm> get problemSymbols {
    final out = perSymbol.where((s) => s.issues.isNotEmpty).toList()
      ..sort((a, b) {
        final byCount = b.issues.length.compareTo(a.issues.length);
        return byCount != 0 ? byCount : a.index.compareTo(b.index);
      });
    return out;
  }

  Duration get mineDuration => mine.isEmpty ? Duration.zero : mine.last.end;

  Duration get standardDuration =>
      standard.isEmpty ? Duration.zero : standard.last.end;

  /// Elements of [mine] belonging to symbol [index] (marks plus their inner
  /// gaps), as a playable timeline with the measured durations.
  List<MorseElement> myElementsFor(int index) => _playable(
    mine.where(
      (e) =>
          e.symbolIndex == index &&
          e.kind != RhythmElementKind.charGap &&
          e.kind != RhythmElementKind.wordGap,
    ),
  );

  List<MorseElement> standardElementsFor(int index) => _playable(
    standard.where(
      (e) =>
          e.symbolIndex == index &&
          e.kind != RhythmElementKind.charGap &&
          e.kind != RhythmElementKind.wordGap,
    ),
  );

  /// The whole measured attempt, replayed with its own durations (repeated
  /// replays are identical).
  List<MorseElement> get myElements => _playable(mine);

  List<MorseElement> get standardElements => _playable(standard);

  static List<MorseElement> _playable(Iterable<RhythmElement> elements) => [
    for (final e in elements)
      MorseElement(switch (e.kind) {
        RhythmElementKind.dit => MorseElementKind.dit,
        RhythmElementKind.dah => MorseElementKind.dah,
        RhythmElementKind.intraGap => MorseElementKind.intraGap,
        RhythmElementKind.charGap => MorseElementKind.charGap,
        RhythmElementKind.wordGap => MorseElementKind.wordGap,
      }, e.duration),
  ];

  static List<RhythmElement> _standard(
    List<String> patterns,
    List<bool> wordStart,
    MorseTiming timing,
  ) {
    final out = <RhythmElement>[];
    var at = Duration.zero;
    void add(RhythmElementKind kind, Duration d, int symbol) {
      out.add(
        RhythmElement(kind: kind, start: at, duration: d, symbolIndex: symbol),
      );
      at += d;
    }

    for (var s = 0; s < patterns.length; s++) {
      if (s > 0) {
        if (wordStart[s]) {
          add(RhythmElementKind.wordGap, timing.wordGap, s);
        } else {
          add(RhythmElementKind.charGap, timing.charGap, s);
        }
      }
      final p = patterns[s];
      for (var i = 0; i < p.length; i++) {
        if (i > 0) add(RhythmElementKind.intraGap, timing.intraGap, s);
        add(
          p[i] == '-' ? RhythmElementKind.dah : RhythmElementKind.dit,
          p[i] == '-' ? timing.dah : timing.dit,
          s,
        );
      }
    }
    return out;
  }

  static bool _structureMatches(
    List<Duration> marks,
    List<Duration> gaps,
    List<RhythmElement> expectedMarks,
    List<RhythmElement> expectedGaps,
    int ditUs,
    RhythmThresholds t,
  ) {
    for (var i = 0; i < marks.length; i++) {
      final dah = marks[i].inMicroseconds / ditUs >= 2;
      if (dah != (expectedMarks[i].kind == RhythmElementKind.dah)) {
        return false;
      }
    }
    for (var i = 0; i < marks.length - 1; i++) {
      final boundary = gaps[i].inMicroseconds / ditUs >= t.charBoundary;
      final expected = expectedGaps[i].kind != RhythmElementKind.intraGap;
      if (boundary != expected) return false;
    }
    return true;
  }

  static RhythmIssue? _markIssue(
    RhythmElementKind kind,
    double r,
    RhythmThresholds t,
  ) => switch (kind) {
    RhythmElementKind.dit when r > t.ditTooLong => RhythmIssue.ditTooLong,
    RhythmElementKind.dah when r < t.dahTooShort => RhythmIssue.dahTooShort,
    RhythmElementKind.dah when r > t.dahTooLong => RhythmIssue.dahTooLong,
    _ => null,
  };

  /// Gaps are only ever flagged as too short (or too long inside a
  /// character): longer character and word gaps are valid, including
  /// Farnsworth spacing.
  static RhythmIssue? _gapIssue(
    RhythmElementKind kind,
    double r,
    RhythmThresholds t,
  ) => switch (kind) {
    RhythmElementKind.intraGap when r > t.intraGapTooLong =>
      RhythmIssue.intraGapTooLong,
    RhythmElementKind.charGap when r < t.charGapTooShort =>
      RhythmIssue.charGapTooShort,
    RhythmElementKind.wordGap when r < t.wordGapTooShort =>
      RhythmIssue.wordGapTooShort,
    _ => null,
  };
}
