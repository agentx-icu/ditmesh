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

/// Playback was cut short by [MorsePlayer.stop] (or a new [MorsePlayer.play]).
final class PlayerStopped extends PlayerEvent {
  const PlayerStopped();
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
  MorsePlayer({required MorseSink sink, Clock? clock})
      : _sink = sink,
        _clock = clock ?? SystemClock.shared;

  final MorseSink _sink;
  final Clock _clock;
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
  Duration get totalDuration => _offsets.isEmpty ? Duration.zero : _offsets.last;

  /// Starts [elements] from the beginning. A running timeline is stopped
  /// first (emitting [PlayerStopped]). An empty list completes immediately.
  void play(List<MorseElement> elements) {
    stop();
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
    _paused = false;
    _startAt = _clock.now();
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
    _setSink(_elements[_current].on);
    _scheduleBoundaryAfter(_current);
  }

  void stop() {
    if (!_playing) {
      return;
    }
    _timer?.cancel();
    _timer = null;
    _setSink(false);
    _playing = false;
    _paused = false;
    _current = -1;
    _emit(const PlayerStopped());
  }

  Future<void> dispose() async {
    stop();
    await _events.close();
  }

  void _startElement(int index) {
    _current = index;
    final element = _elements[index];
    _setSink(element.on);
    _emit(PlayerElementStarted(index, element));
    _scheduleBoundaryAfter(index);
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
    _setSink(false);
    _playing = false;
    _current = -1;
    _emit(const PlayerCompleted());
  }

  void _scheduleAt(Duration absolute, void Function() callback) {
    _timer?.cancel();
    final delay = absolute - _clock.now();
    _timer = _clock.schedule(delay.isNegative ? Duration.zero : delay, callback);
  }

  void _setSink(bool on) {
    if (on == _sinkOn) {
      return;
    }
    _sinkOn = on;
    if (on) {
      _sink.on();
    } else {
      _sink.off();
    }
  }

  void _emit(PlayerEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }
}
