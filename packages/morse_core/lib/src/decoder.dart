import 'dart:async';

import 'alphabet.dart';
import 'cluster.dart';

/// Streaming decoder for hand-keyed input.
///
/// Feed [MorseDecoder.keyDown] / [MorseDecoder.keyUp] with monotonic
/// timestamps (e.g. from a `Stopwatch`), call [MorseDecoder.tick]
/// periodically so pending gaps can resolve into character / word
/// boundaries, and read [MorseDecoder.text] or listen to
/// [MorseDecoder.events].
///
/// Algorithm contract (see plan §4.1):
/// * dit length is estimated by two-cluster split of observed mark durations
///   (mean of the short cluster), seeded by [DecoderConfig.initialDit];
///   NOT the overall median (dah-heavy text would bias it).
/// * decision thresholds sit at the midpoints: mark > 2 dit => dah;
///   gap > 2 dit => character boundary; gap > 5 dit => word boundary.
/// * under Farnsworth-style keying the char/word gap thresholds adapt to the
///   observed gap distribution instead of fixed multiples.
/// * tolerance: ±30 % jitter must decode correctly.
final class DecoderConfig {
  const DecoderConfig({
    this.initialDit = const Duration(milliseconds: 80),
    this.adaptive = true,
    this.ditDahThreshold = 2.0,
    this.charGapThreshold = 2.0,
    this.wordGapThreshold = 5.0,
  });

  final Duration initialDit;
  final bool adaptive;
  final double ditDahThreshold;
  final double charGapThreshold;
  final double wordGapThreshold;
}

enum DecodeEventKind { element, character, word, unknownPattern }

final class DecodeEvent {
  const DecodeEvent(this.kind, {this.text, this.pattern, this.confidence = 1});

  final DecodeEventKind kind;

  /// Decoded character (or space for [DecodeEventKind.word]).
  ///
  /// For [DecodeEventKind.unknownPattern] this is the bracketed raw pattern,
  /// e.g. `<..--.>`, which is also what gets appended to [MorseDecoder.text].
  final String? text;

  /// Raw `.`/`-` pattern for element and character events.
  final String? pattern;

  /// 0..1; lower when the mark/gap sat close to a threshold.
  final double confidence;

  @override
  String toString() =>
      'DecodeEvent(${kind.name}, text: $text, pattern: $pattern, '
      'confidence: ${confidence.toStringAsFixed(2)})';
}

final class MorseDecoder {
  MorseDecoder({this.config = const DecoderConfig()})
      : _ditUs = config.initialDit.inMicroseconds.toDouble();

  final DecoderConfig config;

  /// Number of recent mark durations kept for the dit estimate.
  static const int markWindow = 32;

  /// Number of recent gap durations kept for Farnsworth adaptation.
  static const int gapWindow = 64;

  /// Two mark clusters are considered distinct when the long cluster's mean
  /// is at least this many times the short cluster's mean (dah/dit is 3).
  static const double _markSeparation = 2.0;

  /// Two long-gap clusters (char vs word) are considered distinct when their
  /// means differ by at least this factor (word/char is 7/3 ≈ 2.33).
  static const double _gapSeparation = 1.8;

  /// A char-gap cluster is "clearly longer than 3 dit" (Farnsworth keying)
  /// above this many dits.
  static const double _farnsworthCharGapDits = 4.0;

  /// Synchronous so listeners observe an event within the same [keyUp] /
  /// [tick] call that produced it (matches [text] / [pendingPattern]).
  final StreamController<DecodeEvent> _events =
      StreamController<DecodeEvent>.broadcast(sync: true);
  final StringBuffer _text = StringBuffer();
  final StringBuffer _pending = StringBuffer();
  final List<double> _pendingConfidence = <double>[];
  final List<double> _marksUs = <double>[];
  final List<double> _gapsUs = <double>[];

  double _ditUs;
  double? _adaptedCharGapUs;
  double? _adaptedWordGapUs;

  bool _isDown = false;
  Duration _downAt = Duration.zero;
  Duration? _lastUpAt;
  bool _charCommitted = true;
  bool _wordCommitted = true;

  /// Current dit estimate.
  Duration get estimatedDit => Duration(microseconds: _ditUs.round());

  /// Decoded text so far (characters and spaces).
  String get text => _text.toString();

  /// Pattern of the character currently being keyed (not yet committed).
  String get pendingPattern => _pending.toString();

  Stream<DecodeEvent> get events => _events.stream;

  /// Whether the key is currently held down.
  bool get isKeyDown => _isDown;

  /// Effective mark threshold: at or above this a mark is a dah.
  Duration get ditDahThreshold =>
      Duration(microseconds: _ditDahThresholdUs.round());

  /// Effective gap threshold for a character boundary (adapts to Farnsworth).
  Duration get charGapThreshold =>
      Duration(microseconds: _charGapThresholdUs.round());

  /// Effective gap threshold for a word boundary (adapts to Farnsworth).
  Duration get wordGapThreshold =>
      Duration(microseconds: _wordGapThresholdUs.round());

  /// True while the gap thresholds are driven by an observed Farnsworth-style
  /// gap distribution rather than the configured multiples.
  bool get isFarnsworthAdapted => _adaptedCharGapUs != null;

  double get _ditDahThresholdUs => config.ditDahThreshold * _ditUs;
  double get _charGapThresholdUs =>
      _adaptedCharGapUs ?? config.charGapThreshold * _ditUs;
  double get _wordGapThresholdUs =>
      _adaptedWordGapUs ?? config.wordGapThreshold * _ditUs;

  void keyDown(Duration at) {
    if (_isDown) return;
    final Duration? lastUp = _lastUpAt;
    if (lastUp != null) {
      final double gapUs = (at - lastUp).inMicroseconds.toDouble();
      if (gapUs > 0) _recordGap(gapUs);
      _resolveGap(gapUs);
    }
    _isDown = true;
    _downAt = at;
  }

  void keyUp(Duration at) {
    if (!_isDown) return;
    _isDown = false;
    final double markUs = (at - _downAt).inMicroseconds.toDouble();
    if (markUs <= 0) return;

    _recordMark(markUs);
    final double threshold = _ditDahThresholdUs;
    final bool isDah = markUs >= threshold;
    final double confidence = _confidence(markUs, threshold);
    final String symbol = isDah ? '-' : '.';
    _pending.write(symbol);
    _pendingConfidence.add(confidence);
    _lastUpAt = at;
    _charCommitted = false;
    _wordCommitted = false;
    _emit(DecodeEvent(
      DecodeEventKind.element,
      pattern: symbol,
      confidence: confidence,
    ));
  }

  /// Resolve pending gaps as of [now]; call from a periodic timer.
  void tick(Duration now) {
    if (_isDown) return;
    final Duration? lastUp = _lastUpAt;
    if (lastUp == null) return;
    final double gapUs = (now - lastUp).inMicroseconds.toDouble();
    _resolveGap(gapUs);
  }

  /// Commit whatever is pending and return the final text.
  String flush() {
    _commitCharacter();
    return text;
  }

  /// Drop a mark that is still held without decoding it, e.g. when the input
  /// that pressed the key goes away before releasing it. The next [keyDown]
  /// starts a fresh mark; text and learned timing are kept.
  void cancelMark() {
    _isDown = false;
  }

  /// Forget the decoded text and any in-progress character (including a
  /// held mark) but keep the learned dit estimate and gap thresholds. Useful
  /// between exercises keyed by the same operator; [reset] forgets
  /// everything.
  void clearText() {
    _isDown = false;
    _text.clear();
    _pending.clear();
    _pendingConfidence.clear();
    _lastUpAt = null;
    _charCommitted = true;
    _wordCommitted = true;
  }

  void reset() {
    clearText();
    _marksUs.clear();
    _gapsUs.clear();
    _ditUs = config.initialDit.inMicroseconds.toDouble();
    _adaptedCharGapUs = null;
    _adaptedWordGapUs = null;
    _isDown = false;
    _downAt = Duration.zero;
  }

  /// Release the event stream. Call when the owning widget is disposed.
  void dispose() {
    unawaited(_events.close());
  }

  // ---------------------------------------------------------------------------
  // Gap resolution

  void _resolveGap(double gapUs) {
    if (!_charCommitted && gapUs >= _charGapThresholdUs) {
      _commitCharacter();
    }
    if (_charCommitted && !_wordCommitted && gapUs >= _wordGapThresholdUs) {
      _commitWord();
    }
  }

  void _commitCharacter() {
    if (_charCommitted) return;
    _charCommitted = true;
    if (_pending.isEmpty) return;

    // A character's confidence is the weakest of its element decisions. The
    // gap that closed it is still open when a tick() commits it, so the gap
    // length itself carries no information here.
    final String pattern = _pending.toString();
    final double confidence = _pendingConfidence.fold<double>(
        1, (double acc, double c) => c < acc ? c : acc);
    _pending.clear();
    _pendingConfidence.clear();

    final String? char = MorseAlphabet.decodePattern(pattern) ??
        _bracketed(MorseAlphabet.decodeProsignPattern(pattern));
    if (char != null) {
      _text.write(char);
      _emit(DecodeEvent(
        DecodeEventKind.character,
        text: char,
        pattern: pattern,
        confidence: confidence,
      ));
    } else {
      final String marker = '<$pattern>';
      _text.write(marker);
      _emit(DecodeEvent(
        DecodeEventKind.unknownPattern,
        text: marker,
        pattern: pattern,
        confidence: confidence,
      ));
    }
  }

  /// A word boundary is reported as soon as the silence crosses the word
  /// threshold. Since the silence is still running at that moment, the final
  /// gap length is unknown, so the event carries full confidence.
  void _commitWord() {
    if (_wordCommitted) return;
    _wordCommitted = true;
    if (_text.isEmpty) return;
    final String current = _text.toString();
    if (current.endsWith(' ')) return;
    _text.write(' ');
    _emit(const DecodeEvent(DecodeEventKind.word, text: ' '));
  }

  static String? _bracketed(String? prosign) =>
      prosign == null ? null : '<$prosign>';

  // ---------------------------------------------------------------------------
  // Adaptive timing

  void _recordMark(double markUs) {
    _marksUs.add(markUs);
    if (_marksUs.length > markWindow) _marksUs.removeAt(0);
    if (!config.adaptive) return;
    _ditUs = _estimateDit();
    _recomputeGapThresholds();
  }

  void _recordGap(double gapUs) {
    _gapsUs.add(gapUs);
    if (_gapsUs.length > gapWindow) _gapsUs.removeAt(0);
    if (!config.adaptive) return;
    _recomputeGapThresholds();
  }

  /// Two-cluster dit estimate over the recent marks (1-D k-means seeded at
  /// the current dit and dah lengths, see `splitTwoClusters`).
  ///
  /// When a short and a long cluster are both evident the dit is the mean of
  /// the short one. When the marks all look alike they are dits if they are
  /// shorter than the dah threshold derived from the *current* estimate,
  /// otherwise they are dahs (and the dit is a third of their mean). The
  /// overall median is deliberately never used.
  double _estimateDit() {
    final ClusterSplit? split = splitTwoClusters(
      _marksUs,
      seedLow: _ditUs,
      seedHigh: 3 * _ditUs,
    );
    if (split != null && split.separation >= _markSeparation) {
      return split.lowMean;
    }
    final double m = mean(_marksUs);
    return m < _ditDahThresholdUs ? m : m / 3;
  }

  /// Farnsworth adaptation over the recent gaps.
  ///
  /// Gaps shorter than the configured char-gap multiple are intra-character
  /// gaps. The rest are split into a char-gap and a word-gap cluster. When
  /// both clusters are evident and the char-gap cluster is clearly longer
  /// than 3 dit, the thresholds move to the midpoints between the observed
  /// clusters; otherwise the configured multiples apply.
  void _recomputeGapThresholds() {
    final double intraLimit = config.charGapThreshold * _ditUs;
    final List<double> intra = <double>[];
    final List<double> long = <double>[];
    for (final double g in _gapsUs) {
      (g < intraLimit ? intra : long).add(g);
    }

    _adaptedCharGapUs = null;
    _adaptedWordGapUs = null;

    final ClusterSplit? split = splitTwoClusters(
      long,
      seedLow: 3 * _ditUs,
      seedHigh: 7 * _ditUs,
    );
    if (split == null || split.separation < _gapSeparation) return;
    if (split.lowMean <= _farnsworthCharGapDits * _ditUs) return;

    final double intraMean = intra.isEmpty ? _ditUs : mean(intra);
    _adaptedCharGapUs = (intraMean + split.lowMean) / 2;
    _adaptedWordGapUs = (split.lowMean + split.highMean) / 2;
  }

  /// 1.0 when [value] is at least 50 % away from [threshold], falling
  /// linearly to 0.5 exactly at the threshold.
  static double _confidence(double value, double threshold) {
    if (threshold <= 0 || !value.isFinite) return 1;
    final double distance = (value - threshold).abs() / threshold;
    return (0.5 + distance).clamp(0.5, 1.0);
  }

  void _emit(DecodeEvent event) {
    if (!_events.isClosed) _events.add(event);
  }
}
