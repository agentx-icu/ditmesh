import 'package:tim2tox_dart/ffi/tim2tox_ffi.dart';

/// Ambient instance leases never span an await. Read the current value each time.
class NativeInstanceScope {
  static T run<T>(Tim2ToxFfi library, int handle, T Function() action) {
    final previous = library.getCurrentInstanceId();
    if (library.setCurrentInstance(handle) != 1) {
      throw StateError('Native instance is unavailable');
    }
    try {
      return action();
    } finally {
      library.setCurrentInstance(previous);
    }
  }

  static bool destroy(Tim2ToxFfi library, int handle) {
    final previous = library.getCurrentInstanceId();
    try {
      library.setCurrentInstance(0);
      final result = library.destroyTestInstance(handle);
      return result != 0 || library.isInstanceInitialized(handle) != 1;
    } finally {
      library.setCurrentInstance(previous == handle ? 0 : previous);
    }
  }
}
