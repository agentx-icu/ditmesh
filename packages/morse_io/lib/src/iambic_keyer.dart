import 'dart:async';

import 'package:morse_core/morse_core.dart';

import 'clock.dart';
import 'key_event.dart';
import 'keyer_timing.dart';
import 'sink.dart';

/// Curtis keyer modes.
enum IambicMode {
  /// Releasing both paddles finishes the current element and stops.
  a,

  /// Releasing both paddles during an element (or its gap) also sends the
  /// opposite element that was latched while squeezing.
  b,
}

/// Two-paddle input surface implemented by [IambicKeyer].
abstract interface class PaddleInput {
  void ditPaddle(bool down, Duration at);
  void dahPaddle(bool down, Duration at);
}

enum _Phase { idle, mark, gap }

/// Iambic (squeeze) keyer, driven entirely by an injectable [Clock].
///
/// State machine:
/// * `idle` – a paddle press starts its element immediately.
/// * `mark` – key down for `dit`/`dah`; ends with a timer at the exact
///   absolute time, then `gap`.
/// * `gap` – key up for one inter-element gap; at its end the next element
///   is chosen from paddle state plus *memory*:
///   both wanted → alternate; one wanted → that one; none → `idle`.
///
/// Memory: a paddle pressed while an element or gap is in progress is
/// remembered until the next decision, so quick taps are never lost. The
/// opposite paddle being held when an element *starts* is remembered too;
/// that latch is what makes mode B emit one extra element after a squeeze
/// is released. Mode A clears all memory when a squeeze is fully released.
///
/// Timestamps in emitted events are the *scheduled* boundary times, not the
/// (possibly late) callback times, so the decoder sees exact PARIS spacing.
final class IambicKeyer implements PaddleInput {
  IambicKeyer({
    required this.timing,
    KeyTarget? target,
    MorseSink? sink,
    Clock? clock,
    this.mode = IambicMode.b,
  })  : _target = target,
        _sink = sink,
        _clock = clock ?? SystemClock.shared;

  final IambicMode mode;
  final KeyTarget? _target;
  final MorseSink? _sink;
  final Clock _clock;
  final StreamController<MorseKeyEvent> _events =
      StreamController<MorseKeyEvent>.broadcast(sync: true);

  /// Speed may change between elements; the element in flight keeps its
  /// original length.
  KeyerTiming timing;

  _Phase _phase = _Phase.idle;
  MorseElementKind? _current;
  Duration _markEnd = Duration.zero;
  MorseElementKind _last = MorseElementKind.dah;
  Timer? _timer;
  bool _ditDown = false;
  bool _dahDown = false;
  bool _ditMemory = false;
  bool _dahMemory = false;
  bool _squeezed = false;

  Stream<MorseKeyEvent> get events => _events.stream;

  /// True while an element or its trailing gap is in progress.
  bool get isKeying => _phase != _Phase.idle;

  /// Element currently sounding (null during gaps and when idle).
  MorseElementKind? get currentElement =>
      _phase == _Phase.mark ? _current : null;

  bool get ditPaddleDown => _ditDown;
  bool get dahPaddleDown => _dahDown;

  @override
  void ditPaddle(bool down, Duration at) =>
      _paddle(MorseElementKind.dit, down, at);

  @override
  void dahPaddle(bool down, Duration at) =>
      _paddle(MorseElementKind.dah, down, at);

  /// Cancels any element in flight (sink off, decoder key-up at [at]).
  void reset(Duration at) {
    _timer?.cancel();
    _timer = null;
    if (_phase == _Phase.mark) {
      _key(false, at);
    }
    _phase = _Phase.idle;
    _current = null;
    _ditDown = _dahDown = false;
    _ditMemory = _dahMemory = false;
    _squeezed = false;
  }

  /// Ends the keying now without cutting the element in flight short: a
  /// sounding mark is reported to the target as ending at its full length
  /// (so a dah stays a dah for the decoder), and nothing further is keyed
  /// (paddle memory and held paddles are dropped). Use before acting on what
  /// was keyed, e.g. sending it.
  void finish() {
    _timer?.cancel();
    _timer = null;
    if (_phase == _Phase.mark) _key(false, _markEnd);
    _phase = _Phase.idle;
    _current = null;
    _ditDown = _dahDown = false;
    _ditMemory = _dahMemory = false;
    _squeezed = false;
  }

  Future<void> dispose() async {
    reset(_clock.now());
    await _events.close();
  }

  void _paddle(MorseElementKind paddle, bool down, Duration at) {
    final isDit = paddle == MorseElementKind.dit;
    if ((isDit ? _ditDown : _dahDown) == down) {
      return;
    }
    if (isDit) {
      _ditDown = down;
    } else {
      _dahDown = down;
    }
    if (down) {
      if (_ditDown && _dahDown) {
        _squeezed = true;
      }
      if (_phase == _Phase.idle) {
        _startMark(paddle, at);
      } else if (isDit) {
        _ditMemory = true;
      } else {
        _dahMemory = true;
      }
      return;
    }
    if (mode == IambicMode.a && _squeezed && !_ditDown && !_dahDown) {
      _ditMemory = _dahMemory = false;
      _squeezed = false;
    }
  }

  void _startMark(MorseElementKind kind, Duration at) {
    _phase = _Phase.mark;
    _current = kind;
    _last = kind;
    _squeezed = _ditDown && _dahDown;
    // Latch the opposite paddle if it is already held: mode B's extra element.
    if (kind == MorseElementKind.dit && _dahDown) {
      _dahMemory = true;
    } else if (kind == MorseElementKind.dah && _ditDown) {
      _ditMemory = true;
    }
    _key(true, at);
    final end = at + timing.durationOf(kind);
    _markEnd = end;
    _scheduleAt(end, () => _endMark(end));
  }

  void _endMark(Duration at) {
    _phase = _Phase.gap;
    _current = null;
    _key(false, at);
    final end = at + timing.gap;
    _scheduleAt(end, () => _endGap(end));
  }

  void _endGap(Duration at) {
    final wantDit = _ditDown || _ditMemory;
    final wantDah = _dahDown || _dahMemory;
    _ditMemory = _dahMemory = false;
    final MorseElementKind? next;
    if (wantDit && wantDah) {
      next = _last == MorseElementKind.dit
          ? MorseElementKind.dah
          : MorseElementKind.dit;
    } else if (wantDit) {
      next = MorseElementKind.dit;
    } else if (wantDah) {
      next = MorseElementKind.dah;
    } else {
      next = null;
    }
    if (next == null) {
      _phase = _Phase.idle;
      _timer = null;
      _squeezed = false;
      return;
    }
    _startMark(next, at);
  }

  void _key(bool on, Duration at) {
    if (on) {
      _sink?.on();
      _target?.keyDown(at);
    } else {
      _sink?.off();
      _target?.keyUp(at);
    }
    if (!_events.isClosed) {
      _events.add(MorseKeyEvent(on: on, at: at));
    }
  }

  void _scheduleAt(Duration absolute, void Function() callback) {
    _timer?.cancel();
    final delay = absolute - _clock.now();
    _timer = _clock.schedule(delay.isNegative ? Duration.zero : delay, callback);
  }
}
