import 'dart:async';

import '../clock.dart';

/// Deterministic [Clock] for tests: time only moves when you [advance] it.
///
/// Timers fire in due-time order (creation order on ties) while time is
/// advanced, and callbacks observe [now] equal to their due time. Timers a
/// callback schedules inside the advanced window fire in the same call.
///
/// [timerLatency] simulates a late event loop: every timer runs that much
/// after its due time (and sees the late [now]). Use it to prove a component
/// schedules from absolute times instead of chaining relative delays.
final class FakeClock implements Clock {
  FakeClock({Duration start = Duration.zero, this.timerLatency = Duration.zero})
      : _now = start;

  final Duration timerLatency;
  Duration _now;
  int _sequence = 0;
  final List<_FakeTimer> _timers = <_FakeTimer>[];

  /// Number of timers still waiting to fire.
  int get pendingTimers => _timers.length;

  @override
  Duration now() => _now;

  @override
  Timer schedule(Duration delay, void Function() callback) {
    final effective = delay.isNegative ? Duration.zero : delay;
    final timer = _FakeTimer(this, _now + effective, _sequence++, callback);
    _timers.add(timer);
    return timer;
  }

  /// Moves time forward by [by], firing everything that falls due.
  void advance(Duration by) => elapseTo(_now + by);

  /// Moves time forward to [target] (no-op if it is in the past).
  void elapseTo(Duration target) {
    if (target < _now) {
      return;
    }
    while (true) {
      _FakeTimer? next;
      for (final timer in _timers) {
        if (next == null ||
            timer.due < next.due ||
            (timer.due == next.due && timer.sequence < next.sequence)) {
          next = timer;
        }
      }
      if (next == null || next.due + timerLatency > target) {
        break;
      }
      _timers.remove(next);
      next.active = false;
      _now = next.due + timerLatency;
      next.callback();
    }
    _now = target;
  }

  void _cancel(_FakeTimer timer) {
    _timers.remove(timer);
  }
}

final class _FakeTimer implements Timer {
  _FakeTimer(this._clock, this.due, this.sequence, this.callback);

  final FakeClock _clock;
  final Duration due;
  final int sequence;
  final void Function() callback;
  bool active = true;

  @override
  void cancel() {
    if (active) {
      active = false;
      _clock._cancel(this);
    }
  }

  @override
  bool get isActive => active;

  @override
  int get tick => active ? 0 : 1;
}
