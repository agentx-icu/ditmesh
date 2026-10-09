import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:morse_io/morse_io.dart';

/// One decoded token and the actual completed transitions that produced it.
class KeyedChunk {
  const KeyedChunk(this.text, this.spans, this.startMs, this.endMs, this.clock);
  final String text;
  final List<int> spans;
  final int startMs;
  final int endMs;
  final Object clock;
}

/// Live-only timing owned by the shared draft writer. Disk drafts contain text
/// alone; any unrecorded edit makes the original unavailable until cleared.
class KeyedDraftRecording {
  String _text = '';
  final List<KeyedChunk> _chunks = [];
  bool _unavailable = false;

  void append(String before, KeyedChunk chunk) {
    reconcile(before);
    final covered = _chunks.map((c) => c.text).join() == before;
    _text = before + chunk.text;
    if (_unavailable) return;
    _chunks.add(chunk);
    if (!covered ||
        _recording() == null && _chunks.any((c) => c.text.trim().isNotEmpty)) {
      _chunks.clear();
      _unavailable = true;
    }
  }

  void reconcile(String text) {
    if (text.isEmpty) {
      _text = '';
      _chunks.clear();
      _unavailable = false;
      return;
    }
    if (text == _text) return;
    if (_text.startsWith(text)) {
      while (_chunks.isNotEmpty && _text.length > text.length) {
        final last = _chunks.removeLast();
        _text = _text.substring(0, _text.length - last.text.length);
      }
      if (_text == text) return;
    }
    _text = text;
    _chunks.clear();
    _unavailable = true;
  }

  KeyedRecording? forText(String text) {
    if (_unavailable ||
        _text.trim() != text.trim() ||
        _chunks.map((c) => c.text).join().trim() != text.trim()) {
      return null;
    }
    return _recording();
  }

  KeyedRecording? _recording() {
    if (_chunks.any((c) => c.text.trim().isNotEmpty && c.spans.isEmpty)) {
      return null;
    }
    final marks = _chunks.where((c) => c.spans.isNotEmpty).toList();
    if (marks.isEmpty) return null;
    final spans = <int>[];
    KeyedChunk? previous;
    for (final chunk in marks) {
      if (!identical(chunk.clock, marks.first.clock)) return null;
      if (previous != null) spans.add(chunk.startMs - previous.endMs);
      spans.addAll(chunk.spans);
      previous = chunk;
    }
    try {
      return KeyedRecording(durationsMs: spans);
    } on ArgumentError {
      return null;
    }
  }
}

/// Captures the target transitions before decoding, independently of sidetone.
class RecordingKeyTarget implements KeyTarget {
  RecordingKeyTarget(this.target, this.clock);
  final KeyTarget target;
  final Object clock;
  final List<int> _spans = [];
  int? _down;
  int? _start;
  int? _up;
  bool _invalid = false;

  void _add(int value) {
    if (_invalid) return;
    if (value <= 0 ||
        value > KeyedRecording.maxTotalDurationMs ||
        _spans.length >= KeyedRecording.maxSpans) {
      _invalid = true;
      _spans.clear();
      return;
    }
    _spans.add(value);
    if (_spans.fold<int>(0, (sum, span) => sum + span) >
        KeyedRecording.maxTotalDurationMs) {
      _invalid = true;
      _spans.clear();
    }
  }

  @override
  void keyDown(Duration at) {
    // Gap resolution may synchronously commit the previous character. Let
    // that commit consume its marks before opening the new character.
    target.keyDown(at);
    final now = at.inMilliseconds;
    _start ??= now;
    if (_up != null && _spans.isNotEmpty) _add(now - _up!);
    _down = now;
  }

  @override
  void keyUp(Duration at) {
    final now = at.inMilliseconds;
    final down = _down;
    if (down != null) {
      _add(now - down);
      _up = now;
      _down = null;
    }
    target.keyUp(at);
  }

  /// A cancelled held mark must not become the start of a later token.
  void cancelMark() {
    _down = null;
    if (_spans.isEmpty) _start = null;
  }

  KeyedChunk consume(String text) {
    if (text.trim().isEmpty) return KeyedChunk(text, const [], 0, 0, clock);
    final chunk = KeyedChunk(
      text,
      _invalid ? const [] : List.unmodifiable(_spans),
      _start ?? 0,
      _up ?? 0,
      clock,
    );
    _spans.clear();
    _start = _up = null;
    _invalid = false;
    return chunk;
  }
}
