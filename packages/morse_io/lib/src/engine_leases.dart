/// Reference-counted ownership of one shared audio engine.
///
/// `flutter_soloud` has a single engine per isolate, but every
/// [SidetoneSink] (drill, send practice, chat playback, reference player)
/// initialises and later shuts it down on its own. Without coordination the
/// first sink to be disposed deinitialises the engine under the others, and
/// two overlapping `init` calls make the engine rebuild itself, stopping
/// every running voice.
///
/// Each holder calls [acquire] once and [release] once. The engine is started
/// by the first acquire that finds it stopped and shut down only when the
/// last lease is released -- and only if a lease started it, so an engine
/// someone else started is never torn down. All operations run one at a
/// time in call order, so an acquire never overlaps an in-flight init or
/// deinit.
///
/// Pure Dart: the engine is reached only through the two callbacks and the
/// init function passed to [acquire], so tests drive it without native code.
final class EngineLeases {
  EngineLeases({
    required bool Function() isInitialized,
    required void Function() deinit,
  }) : _isInitialized = isInitialized,
       _deinit = deinit;

  final bool Function() _isInitialized;
  final void Function() _deinit;

  int _count = 0;
  bool _startedEngine = false;
  Future<void> _tail = Future<void>.value();

  /// Leases currently held.
  int get count => _count;

  /// Takes a lease, running [init] first when the engine is not running.
  /// When [init] throws, no lease is taken and the error is rethrown.
  Future<void> acquire(Future<void> Function() init) => _serial(() async {
    if (!_isInitialized()) {
      await init();
      _startedEngine = true;
    }
    _count++;
  });

  /// Returns a lease; the last one shuts down an engine a lease started.
  /// Extra releases are ignored.
  Future<void> release() => _serial(() async {
    if (_count == 0) {
      return;
    }
    _count--;
    if (_count == 0 && _startedEngine) {
      _startedEngine = false;
      if (_isInitialized()) {
        _deinit();
      }
    }
  });

  Future<void> _serial(Future<void> Function() op) {
    final next = _tail.then((_) => op());
    // A failed op must not poison the queue for the next caller; the caller
    // still sees the error through `next`.
    _tail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}
