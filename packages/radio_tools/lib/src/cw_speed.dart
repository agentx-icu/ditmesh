import 'package:morse_core/morse_core.dart';

/// What a CW speed means in milliseconds, on the PARIS standard.
///
/// Wraps [MorseTiming] so the numbers shown in the speed tool are exactly the
/// ones the trainer and the chat play at.
final class CwSpeed {
  CwSpeed({required double wpm, double? farnsworthWpm})
    : timing = MorseTiming(wpm: wpm, farnsworthWpm: farnsworthWpm);

  /// Speed whose dit lasts [ditMs] milliseconds (`wpm = 1200 / dit`).
  factory CwSpeed.fromDitMs(double ditMs) {
    if (!ditMs.isFinite || ditMs <= 0) {
      throw ArgumentError.value(ditMs, 'ditMs', 'must be positive');
    }
    return CwSpeed(wpm: 1200 / ditMs);
  }

  final MorseTiming timing;

  double get wpm => timing.wpm;

  /// Overall speed: the Farnsworth speed when stretching applies.
  double get effectiveWpm =>
      timing.isFarnsworth ? timing.farnsworthWpm! : timing.wpm;

  /// Characters per minute at the overall speed (PARIS = 5 characters).
  double get charsPerMinute => effectiveWpm * 5;

  double get ditMs => _ms(timing.dit);
  double get dahMs => _ms(timing.dah);
  double get charGapMs => _ms(timing.charGap);
  double get wordGapMs => _ms(timing.wordGap);

  /// Seconds one PARIS word (with its word gap) takes: `60 / effectiveWpm`.
  double get parisSeconds => 60 / effectiveWpm;

  static double _ms(Duration d) => d.inMicroseconds / 1000;
}
