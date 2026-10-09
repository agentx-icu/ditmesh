import 'package:meta/meta.dart';

/// Actual key-down/key-up timings, in milliseconds, beginning and ending
/// with a mark. Odd spans are gaps. No synthesized Morse timing belongs here.
@immutable
final class KeyedRecording {
  KeyedRecording({required Iterable<int> durationsMs})
    : durationsMs = List<int>.unmodifiable(durationsMs) {
    if (this.durationsMs.isEmpty ||
        this.durationsMs.length.isEven ||
        this.durationsMs.length > maxSpans ||
        this.durationsMs.any(
          (value) => value <= 0 || value > maxTotalDurationMs,
        ) ||
        this.durationsMs.fold(0, (total, value) => total + value) >
            maxTotalDurationMs) {
      throw ArgumentError.value(
        durationsMs,
        'durationsMs',
        'Invalid recording',
      );
    }
  }

  static const maxSpans = 511;
  static const maxTotalDurationMs = 120000;
  final List<int> durationsMs;

  Duration get totalDuration => Duration(
    milliseconds: durationsMs.fold(0, (total, value) => total + value),
  );

  Map<String, Object> toJson() => {'version': 1, 'durationsMs': durationsMs};

  /// Unsupported or malformed untrusted metadata is optional: the text stays.
  static KeyedRecording? fromJson(Object? value) {
    if (value is! Map || value['version'] != 1) return null;
    final spans = value['durationsMs'];
    if (spans is! List ||
        spans.length > maxSpans ||
        spans.any((v) => v is! int)) {
      return null;
    }
    try {
      return KeyedRecording(durationsMs: spans.cast<int>());
    } on ArgumentError {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is KeyedRecording &&
      other.durationsMs.length == durationsMs.length &&
      List.generate(
        durationsMs.length,
        (i) => i,
      ).every((i) => other.durationsMs[i] == durationsMs[i]);

  @override
  int get hashCode => Object.hashAll(durationsMs);
}
