import 'dart:async';

/// Minimal BehaviorSubject: a broadcast stream that hands every new listener
/// the current value first, then live updates. Pure Dart, no rxdart.
final class ReplaySubject<T> {
  ReplaySubject(this._value);

  final StreamController<T> _controller = StreamController<T>.broadcast();
  T _value;

  T get value => _value;

  bool get isClosed => _controller.isClosed;

  /// Publishes [value] to current listeners and remembers it for future ones.
  void add(T value) {
    _value = value;
    if (!_controller.isClosed) {
      _controller.add(value);
    }
  }

  Stream<T> get stream => Stream<T>.multi((MultiStreamController<T> listener) {
    listener.add(_value);
    if (_controller.isClosed) {
      unawaited(listener.close());
      return;
    }
    final StreamSubscription<T> sub = _controller.stream.listen(
      listener.add,
      onError: listener.addError,
      onDone: listener.close,
    );
    listener.onCancel = sub.cancel;
  }, isBroadcast: true);

  Future<void> close() => _controller.close();
}
