import 'dart:async';

import 'key_event.dart';
import 'sink.dart';

/// Anything a [StraightKeyButton] (or a keyboard) can press and release.
abstract interface class StraightKeyInput {
  void press(Duration at);
  void release(Duration at);
}

/// A hand key: the operator controls every mark and gap directly.
///
/// [press] / [release] toggle the [sink] *first* (real-time feedback wins) and
/// then forward the timestamp to the [target] decoder. Redundant transitions
/// (two presses in a row) are ignored so multi-touch and keyboard auto-repeat
/// cannot desynchronise sink and decoder.
final class StraightKey implements StraightKeyInput {
  StraightKey({required KeyTarget target, MorseSink? sink})
      : _target = target,
        _sink = sink;

  final KeyTarget _target;
  final MorseSink? _sink;
  final StreamController<MorseKeyEvent> _events =
      StreamController<MorseKeyEvent>.broadcast(sync: true);
  bool _down = false;

  bool get isDown => _down;

  /// Every accepted transition, in order.
  Stream<MorseKeyEvent> get events => _events.stream;

  @override
  void press(Duration at) {
    if (_down) {
      return;
    }
    _down = true;
    _sink?.on();
    _target.keyDown(at);
    _emit(MorseKeyEvent.down(at));
  }

  @override
  void release(Duration at) {
    if (!_down) {
      return;
    }
    _down = false;
    _sink?.off();
    _target.keyUp(at);
    _emit(MorseKeyEvent.up(at));
  }

  /// Silences the sink if the key is still down and closes [events].
  Future<void> dispose() async {
    if (_down) {
      _down = false;
      _sink?.off();
    }
    await _events.close();
  }

  void _emit(MorseKeyEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }
}
