import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:morse_core/morse_core.dart';

import 'audio_morse_decoder.dart';
import 'wav_pcm_reader.dart';

/// Lets the caller stop a running decode; once cancelled no further
/// progress or result is reported.
final class DecodeCancelToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

enum SegmentEventKind { character, unknownPattern }

/// One decoded symbol positioned on the recording's sample clock.
final class SegmentEvent {
  const SegmentEvent({
    required this.kind,
    required this.text,
    required this.pattern,
    required this.startFrame,
    required this.endFrame,
    required this.start,
    required this.end,
    this.wordBreakBefore = false,
    this.cutAtStart = false,
    this.cutAtEnd = false,
  });

  final SegmentEventKind kind;

  /// The character, or the bracketed raw pattern for an unknown one.
  final String text;
  final String pattern;
  final int startFrame;
  final int endFrame;

  /// From the start of the recording (sample clock, not wall clock).
  final Duration start;
  final Duration end;

  /// A word gap preceded this symbol.
  final bool wordBreakBefore;

  /// The selection boundary cuts this symbol: it may be incomplete.
  final bool cutAtStart;
  final bool cutAtEnd;

  bool get isEdge => cutAtStart || cutAtEnd;
}

/// Result of decoding one selection.
final class SegmentDecodeResult {
  const SegmentDecodeResult({
    required this.events,
    required this.toneHz,
    required this.toneLocked,
    required this.estimatedWpm,
  });

  final List<SegmentEvent> events;
  final double toneHz;

  /// Tone lock is a tuning state, not a confidence probability.
  final bool toneLocked;
  final double estimatedWpm;

  /// Decoded text; unknown patterns stay bracketed (`<..--.>`).
  String get text {
    final StringBuffer out = StringBuffer();
    for (final SegmentEvent e in events) {
      if (e.wordBreakBefore && out.isNotEmpty) out.write(' ');
      out.write(e.text);
    }
    return out.toString();
  }

  List<SegmentEvent> get unknownPatterns =>
      events.where((e) => e.kind == SegmentEventKind.unknownPattern).toList();

  bool get edgeAtStart => events.isNotEmpty && events.first.cutAtStart;
  bool get edgeAtEnd => events.isNotEmpty && events.last.cutAtEnd;
}

/// Decodes `[selectionStart, selectionEnd)` of a recording fed as mono
/// samples starting at [feedStartFrame] (up to [contextBefore] earlier, so
/// the gate and tone finder settle). Only symbols overlapping the
/// selection are reported; symbols the boundary cuts are flagged.
///
/// Feeding is chunk invariant: the same samples give the same result for
/// any chunk sizes (the underlying decoder runs on the sample clock).
final class SegmentDecoder {
  SegmentDecoder({
    required this.sampleRate,
    required this.selectionStart,
    required this.selectionEnd,
    required this.feedStartFrame,
    bool autoTune = true,
    double manualToneHz = AudioMorseDecoder.defaultFrequencyHz,
  }) : assert(selectionEnd > selectionStart, 'empty selection'),
       assert(feedStartFrame <= selectionStart, 'feed starts too late'),
       _decoder = AudioMorseDecoder(
         sampleRate: sampleRate,
         autoTune: autoTune,
         manualFrequencyHz: manualToneHz,
       ) {
    if (!autoTune) _decoder.manualFrequencyHz = manualToneHz;
    _decoder.onKeyTransition = _onTransition;
    _sub = _decoder.events.listen(_onEvent);
  }

  final int sampleRate;
  final int selectionStart;
  final int selectionEnd;
  final int feedStartFrame;

  final AudioMorseDecoder _decoder;
  late final StreamSubscription<DecodeEvent> _sub;
  final List<(int, int)> _marks = <(int, int)>[];
  final List<SegmentEvent> _events = <SegmentEvent>[];
  int? _downFrame;
  bool _wordPending = false;
  bool _finished = false;

  /// The audio ended while a key was down: the last symbol is incomplete.
  bool _cutAtEof = false;

  int _frameOf(Duration at) =>
      feedStartFrame +
      (at.inMicroseconds * sampleRate / Duration.microsecondsPerSecond).round();

  Duration _timeOf(int frame) => Duration(
    microseconds: frame * Duration.microsecondsPerSecond ~/ sampleRate,
  );

  void _onTransition(bool isOn, Duration at) {
    final int frame = _frameOf(at);
    if (isOn) {
      _downFrame = frame;
    } else if (_downFrame != null) {
      _marks.add((_downFrame!, frame));
      _downFrame = null;
    }
  }

  void _onEvent(DecodeEvent e) {
    switch (e.kind) {
      case DecodeEventKind.word:
        _wordPending = true;
      case DecodeEventKind.character:
      case DecodeEventKind.unknownPattern:
        if (_marks.isEmpty) return;
        final int start = _marks.first.$1;
        final int end = _marks.last.$2;
        _marks.clear();
        final bool word = _wordPending;
        _wordPending = false;
        // Context before or after the selection is never reported.
        if (end <= selectionStart || start >= selectionEnd) return;
        _events.add(
          SegmentEvent(
            kind: e.kind == DecodeEventKind.character
                ? SegmentEventKind.character
                : SegmentEventKind.unknownPattern,
            text: e.text ?? '',
            pattern: e.pattern ?? '',
            startFrame: start,
            endFrame: end,
            start: _timeOf(start),
            end: _timeOf(end),
            wordBreakBefore: word && _events.isNotEmpty,
            cutAtStart: start < selectionStart,
            cutAtEnd: end > selectionEnd || (_cutAtEof && _finished),
          ),
        );
      case DecodeEventKind.element:
        break;
    }
  }

  /// Feeds the next mono samples (consecutive from [feedStartFrame]).
  void feed(Float64List mono) {
    if (_finished) throw StateError('segment decoder finished');
    _decoder.feedFloat(mono);
  }

  /// Commits the last symbol and returns the result. A tone still keyed at
  /// the end of the fed audio closes there and is flagged as cut.
  SegmentDecodeResult finish() {
    if (!_finished) {
      _finished = true;
      // Release the underlying key at the last sample (not only our own
      // bookkeeping), so the final mark is decoded; it is flagged as cut.
      _cutAtEof = _decoder.endOfInput();
      if (_downFrame != null) {
        _marks.add((_downFrame!, math.max(_downFrame! + 1, selectionEnd + 1)));
        _downFrame = null;
      }
      _decoder.commitPending();
    }
    return SegmentDecodeResult(
      events: List<SegmentEvent>.unmodifiable(_events),
      toneHz: _decoder.detectedFrequency,
      toneLocked: _decoder.isToneLocked,
      estimatedWpm: _decoder.estimatedWpm,
    );
  }

  void dispose() {
    unawaited(_sub.cancel());
    _decoder.dispose();
  }
}

/// Decodes a selection of [reader] in chunks, reading up to [context] of
/// audio before and after it. Returns null when [cancel] fires; after that
/// no progress is reported.
Future<SegmentDecodeResult?> decodeSegment(
  WavPcmReader reader, {
  required int startFrame,
  required int endFrame,
  bool autoTune = true,
  double manualToneHz = AudioMorseDecoder.defaultFrequencyHz,
  Duration context = const Duration(seconds: 1),
  int chunkFrames = 4096,
  DecodeCancelToken? cancel,
  void Function(double progress)? onProgress,
}) async {
  final WavInfo info = reader.info;
  final int start = startFrame.clamp(0, info.frameCount);
  final int end = endFrame.clamp(start, info.frameCount);
  if (end <= start) throw ArgumentError('empty selection');
  final int pad = info.frameAt(context);
  final int feedStart = math.max(0, start - pad);
  final int feedEnd = math.min(info.frameCount, end + pad);
  final SegmentDecoder decoder = SegmentDecoder(
    sampleRate: info.sampleRate,
    selectionStart: start,
    selectionEnd: end,
    feedStartFrame: feedStart,
    autoTune: autoTune,
    manualToneHz: manualToneHz,
  );
  try {
    int done = 0;
    await for (final Float64List chunk in reader.chunks(
      feedStart,
      feedEnd,
      chunkFrames: chunkFrames,
    )) {
      if (cancel?.isCancelled ?? false) return null;
      decoder.feed(chunk);
      done += chunk.length;
      onProgress?.call(done / (feedEnd - feedStart));
      // Yield so the UI stays responsive between chunks.
      await Future<void>.delayed(Duration.zero);
    }
    if (cancel?.isCancelled ?? false) return null;
    return decoder.finish();
  } finally {
    decoder.dispose();
  }
}
