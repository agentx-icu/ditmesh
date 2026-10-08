import 'dart:async';

/// A broadcast stream that replays its current value to every new listener
/// (BehaviorSubject semantics), plus a synchronous [value] getter.
///
/// The contract in `ditmesh_chat_api` exposes every list as "a broadcast
/// stream that replays the current value" next to a synchronous getter; this
/// is the single implementation behind all of them.
class ValueStream<T> {
  ValueStream(this._value);

  final StreamController<T> _controller = StreamController<T>.broadcast();
  T _value;
  bool _closed = false;

  T get value => _value;

  bool get isClosed => _closed;

  /// Replays [value] first, then live updates. Each listener gets its own
  /// subscription to the underlying broadcast controller.
  Stream<T> get stream => Stream<T>.multi((emitter) {
        if (_closed) {
          emitter.close();
          return;
        }
        emitter.add(_value);
        final sub = _controller.stream.listen(
          emitter.add,
          onError: emitter.addError,
          onDone: emitter.close,
        );
        emitter.onCancel = sub.cancel;
      });

  /// Publishes [next] when it differs from the current value (by `==`).
  /// Returns whether anything was published.
  bool add(T next) {
    if (_closed) return false;
    if (_value == next) return false;
    _value = next;
    _controller.add(next);
    return true;
  }

  /// Publishes [next] even when it equals the current value.
  void force(T next) {
    if (_closed) return;
    _value = next;
    _controller.add(next);
  }

  Future<void> close() {
    if (_closed) return Future<void>.value();
    _closed = true;
    return _controller.close();
  }
}

/// Structural list equality, used by the derivation layers to publish a new
/// list only when its contents changed.
bool listEqualsBy<T>(List<T> a, List<T> b, bool Function(T, T) same) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!same(a[i], b[i])) return false;
  }
  return true;
}
