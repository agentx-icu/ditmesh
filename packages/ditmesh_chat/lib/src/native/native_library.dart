import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_library_manager.dart';
import 'package:tim2tox_dart/ffi/tim2tox_ffi.dart';

/// Points the Tencent Cloud Chat SDK's `NativeLibraryManager` at
/// `libtim2tox_ffi` instead of `dart_native_imsdk`.
///
/// ditmesh installs neither `Tim2ToxSdkPlatform` nor the UIKit, but two
/// `FfiChatService` paths still go through the Tencent bindings
/// (`quitGroup` → `DartQuitGroup`; group invites and member listing →
/// `TIMGroupManager` / `DartGetGroupMemberList`). Those bindings load the
/// library by the name set here, so this must run before the first
/// `FfiChatService` is constructed — exactly as toxee's
/// `LoggingBootstrap.initialize()` does (`setNativeLibraryName('tim2tox_ffi')`).
///
/// `setNativeLibraryName` is added to the SDK by tim2tox patch 0001
/// (`native-library-name-override`); the vendored SDK must be the patched one.
class NativeLibrarySetup {
  NativeLibrarySetup._();

  static const String libraryName = 'tim2tox_ffi';
  static bool _configured = false;

  static bool get isConfigured => _configured;

  /// Idempotent. [libraryPathOverride] pins `Tim2ToxFfi` to an absolute path
  /// (desktop dev loops that keep the freshly built library outside the app
  /// bundle); it must be set before the library is first opened.
  static void ensure({String? libraryPathOverride}) {
    if (_configured) return;
    if (libraryPathOverride != null) {
      Tim2ToxFfi.setLibraryPathOverride(libraryPathOverride);
    }
    setNativeLibraryName(libraryName);
    _configured = true;
  }

  /// Whether `libtim2tox_ffi` can be loaded in this process. False in unit
  /// tests and on a dev machine that has not built the native library.
  static bool get isNativeLibraryLoadable {
    try {
      Tim2ToxFfi.open();
      return true;
    } catch (_) {
      return false;
    }
  }
}
