import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart' as pkgffi;

typedef _ChmodNative = ffi.Int32 Function(ffi.Pointer<pkgffi.Utf8>, ffi.Uint32);
typedef _Chmod = int Function(ffi.Pointer<pkgffi.Utf8>, int);

/// Owner-only permissions for identity data on POSIX systems (macOS, Linux,
/// iOS, Android): Dart's `File` / `Directory` APIs create with the umask's
/// defaults and cannot set a mode, so `chmod(2)` is called through FFI.
/// A no-op on Windows, where the per-user profile directory already keeps
/// other accounts out.
abstract final class PosixPermissions {
  /// Directories: rwx for the owner only.
  static const int privateDirectory = 0x1C0; // 0700

  /// Files: rw for the owner only.
  static const int privateFile = 0x180; // 0600

  static final _Chmod? _chmod = _lookup();

  static _Chmod? _lookup() {
    if (Platform.isWindows) return null;
    return ffi.DynamicLibrary.process()
        .lookupFunction<_ChmodNative, _Chmod>('chmod');
  }

  /// Sets [mode] on [path]. Throws [FileSystemException] when it fails, so a
  /// secret is never written somewhere that could not be made private.
  static void set(String path, int mode) {
    final chmod = _chmod;
    if (chmod == null) return;
    final native = path.toNativeUtf8();
    try {
      if (chmod(native, mode) != 0) {
        throw FileSystemException('chmod failed', path);
      }
    } finally {
      pkgffi.malloc.free(native);
    }
  }

  /// Creates [path] (and missing parents) and makes it owner-only.
  static Future<void> createPrivateDirectory(String path) async {
    await Directory(path).create(recursive: true);
    set(path, privateDirectory);
  }
}
