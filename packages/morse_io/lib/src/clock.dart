import 'dart:async';

/// Monotonic time source plus one-shot scheduling.
///
/// Every time-dependent component in `morse_io` (the player, the iambic
/// keyer, the key widgets) takes a [Clock] so tests can drive it with a
/// deterministic fake and so all of them share one timeline. Timestamps
/// handed to a `MorseDecoder` must come from the *same* clock instance that
/// drives its `tick`, otherwise gap detection drifts.
abstract interface class Clock {
  /// Elapsed time since this clock started. Monotonic, never wall-clock.
  Duration now();

  /// Runs [callback] once after [delay]. Negative delays fire as soon as
  /// possible.
  Timer schedule(Duration delay, void Function() callback);
}

/// Production [Clock] backed by a [Stopwatch] and `dart:async` timers.
final class SystemClock implements Clock {
  SystemClock() {
    _stopwatch.start();
  }

  /// Process-wide instance used as the default by widgets and keyers so
  /// that, unless a caller says otherwise, everything shares one timeline.
  static final SystemClock shared = SystemClock();

  final Stopwatch _stopwatch = Stopwatch();

  @override
  Duration now() => _stopwatch.elapsed;

  @override
  Timer schedule(Duration delay, void Function() callback) =>
      Timer(delay.isNegative ? Duration.zero : delay, callback);
}
