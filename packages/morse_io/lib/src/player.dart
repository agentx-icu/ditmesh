import 'dart:async';

import 'package:morse_core/morse_core.dart';

import 'clock.dart';
import 'sink.dart';

/// Lifecycle notifications from [MorsePlayer].
sealed class PlayerEvent {
  const PlayerEvent();
}

/// Element [index] of the current timeline just started sounding (or its
/// gap just began).
final class PlayerElementStarted extends PlayerEvent {
  const PlayerElementStarted(this.index, this.element);

  final int index;
  final MorseElement element;

  @override
  String toString() => 'PlayerElementStarted($index, $element)';
}

/// The whole timeline played to the end.
final class PlayerCompleted extends PlayerEvent {
  const PlayerCompleted();
}

/// Playback was cut short by stop, restart, or an opted-in output failure.
final class PlayerStopped extends PlayerEvent {
  const PlayerStopped({this.error, this.stackTrace, this.cleanupError});

  /// Null for an explicit stop; otherwise the original output failure.
  final Object? error;
  final StackTrace? stackTrace;
  final Object? cleanupError;
}

/// Plays a `List<MorseElement>` through a [MorseSink] with drift-free timing.
///
/// Every element boundary is scheduled at an *absolute* time
/// (`startAt + cumulativeOffset`) computed from the clock when the boundary
/// before it fires, so a late timer callback delays only itself and the
/// following boundaries snap back onto the grid instead of accumulating the
/// error the way chained relative delays would.
///
/// Pause remembers how long it lasted and shifts `startAt` by that amount
/// on resume; the element that was interrupted is re-keyed for its remaining
/// time.
final class MorsePlayer {
  MorsePlayer({
    required MorseSink sink,
    Clock? clock,
    this.reportOutputFailures = false,
  }) : _sink = sink,
       _clock = clock ?? SystemClock.shared;

  final MorseSink _sink;
  final Clock _clock;

  /// Opt-in for sound assessments: turn synchronous and timer output errors
  /// into a diagnostic stopped event and cancel the failed timeline. The
  /// default preserves existing live-keying/error behavior.
  final bool reportOutputFailures;
  final StreamController<PlayerEvent> _events =
      StreamController<PlayerEvent>.broadcast(sync: true);

  List<MorseElement> _elements = const <MorseElement>[];

  /// `_offsets[i]` is the start of element `i` relative to `_startAt`;
  /// `_offsets[length]` is the total duration.
  List<Duration> _offsets = const <Duration>[];
  Duration _startAt = Duration.zero;
  Duration _pausedAt = Duration.zero;
  int _current = -1;
  Timer? _timer;
  bool _playing = false;
  bool _paused = false;
  bool _sinkOn = false;

  Stream<PlayerEvent> get events => _events.stream;

  /// True from [play] until completion or [stop], including while paused.
  bool get isPlaying => _playing;

  bool get isPaused => _paused;

  /// Index of the element currently sounding, or -1 when idle.
  int get currentIndex => _current;

  /// Total length of the timeline being played (zero when idle).
  Duration get totalDuration =>
      _offsets.isEmpty ? Duration.zero : _offsets.last;

  /// Elapsed timeline time, frozen while paused and bounded by its length.
  Duration get elapsed {
    if (!_playing) return Duration.zero;
    final value = (_paused ? _pausedAt : _clock.now()) - _startAt;
    return value < Duration.zero
        ? Duration.zero
        : value > totalDuration
        ? totalDuration
        : value;
  }

  /// Starts [elements] from the beginning. A running timeline is stopped
  /// first (emitting [PlayerStopped]). An empty list completes immediately.
  /// With [paused] the timeline is loaded but stays silent, with no timer,
  /// until [resume].
  void play(List<MorseElement> elements, {bool paused = false}) {
    if (!_stop()) return;
    if (elements.isEmpty) {
      _emit(const PlayerCompleted());
      return;
    }
    _elements = List<MorseElement>.unmodifiable(elements);
    final offsets = List<Duration>.filled(elements.length + 1, Duration.zero);
    for (var i = 0; i < elements.length; i++) {
      offsets[i + 1] = offsets[i] + elements[i].duration;
    }
    _offsets = offsets;
    _playing = true;
    _paused = paused;
    _startAt = _clock.now();
    if (paused) _pausedAt = _startAt;
    _startElement(0);
  }

  void pause() {
    if (!_playing || _paused) {
      return;
    }
    _paused = true;
    _pausedAt = _clock.now();
    _timer?.cancel();
    _timer = null;
    _setSink(false);
  }

  void resume() {
    if (!_playing || !_paused) {
      return;
    }
    _paused = false;
    _startAt += _clock.now() - _pausedAt;
    if (!_setSink(_elements[_current].on)) return;
    _scheduleBoundaryAfter(_current);
  }

  void stop() => _stop();

  bool _stop() {
    if (!_playing) {
      return true;
    }
    _timer?.cancel();
    _timer = null;
    if (!_setSink(false)) return false;
    _playing = false;
    _paused = false;
    _current = -1;
    _emit(const PlayerStopped());
    return true;
  }

  Future<void> dispose() async {
    stop();
    await _events.close();
  }

  void _startElement(int index) {
    _current = index;
    final element = _elements[index];
    // Started paused: the first element waits for resume().
    if (!_paused && !_setSink(element.on)) return;
    _emit(PlayerElementStarted(index, element));
    if (!_paused) _scheduleBoundaryAfter(index);
  }

  void _scheduleBoundaryAfter(int index) {
    final next = index + 1;
    final at = _startAt + _offsets[next];
    if (next < _elements.length) {
      _scheduleAt(at, () => _startElement(next));
    } else {
      _scheduleAt(at, _complete);
    }
  }

  void _complete() {
    _timer = null;
    if (!_setSink(false)) return;
    _playing = false;
    _current = -1;
    _emit(const PlayerCompleted());
  }

  void _scheduleAt(Duration absolute, void Function() callback) {
    _timer?.cancel();
    final delay = absolute - _clock.now();
    _timer = _clock.schedule(
      delay.isNegative ? Duration.zero : delay,
      callback,
    );
  }

  bool _setSink(bool on) {
    if (on == _sinkOn) return true;
    _sinkOn = on;
    try {
      if (on) {
        _sink.on();
      } else {
        _sink.off();
      }
      return true;
    } on Object catch (error, stackTrace) {
      if (!reportOutputFailures) rethrow;
      _failOutput(error, stackTrace);
      return false;
    }
  }

  void _failOutput(Object error, StackTrace stackTrace) {
    _timer?.cancel();
    _timer = null;
    _playing = false;
    _paused = false;
    _current = -1;
    _sinkOn = false;
    Object? cleanupError;
    try {
      _sink.off();
    } on Object catch (failure) {
      cleanupError = failure;
    }
    _emit(
      PlayerStopped(
        error: error,
        stackTrace: stackTrace,
        cleanupError: cleanupError,
      ),
    );
  }

  void _emit(PlayerEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }
}
