import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Asks the OS for extra running time after the app leaves the foreground.
///
/// iOS suspends an app a few seconds after `applicationDidEnterBackground`
/// unless it holds a `UIApplication.beginBackgroundTask` assertion, which
/// stretches that to roughly 30 s. `AppLifecycleCoordinator` holds one for
/// the background budget so the durability flush (Tox savedata, history,
/// offline queue, learning data, settings) and an in-flight send can finish
/// before the process freezes. Android keeps a backgrounded process running
/// until Doze / the OEM freezes it, and desktop never suspends, so every
/// other platform uses [NoopBackgroundTaskApi].
abstract interface class BackgroundTaskApi {
  /// Starts a background task; returns an opaque token, or null when the OS
  /// refused (or the platform has no such concept).
  Future<int?> begin();

  /// Ends the task [token] identifies. Ending one that already expired is a
  /// no-op on the native side.
  Future<void> end(int token);

  /// The implementation for the running platform.
  static BackgroundTaskApi forPlatform() =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
      ? MethodChannelBackgroundTaskApi()
      : const NoopBackgroundTaskApi();
}

/// Platforms without a suspension grace period: nothing to ask for.
final class NoopBackgroundTaskApi implements BackgroundTaskApi {
  const NoopBackgroundTaskApi();

  @override
  Future<int?> begin() async => null;

  @override
  Future<void> end(int token) async {}
}

/// iOS: `ios/Runner/AppDelegate.swift` answers on [channelName].
final class MethodChannelBackgroundTaskApi implements BackgroundTaskApi {
  MethodChannelBackgroundTaskApi({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'icu.agentx.ditmesh/background_task';

  final MethodChannel _channel;

  @override
  Future<int?> begin() async {
    try {
      return await _channel.invokeMethod<int>('begin');
    } on Object catch (error) {
      // MissingPluginException (tests, an older native build) or the OS
      // refusing: the app still works, it just gets the default grace time.
      debugPrint('[BackgroundTaskApi] begin failed: $error');
      return null;
    }
  }

  @override
  Future<void> end(int token) async {
    try {
      await _channel.invokeMethod<void>('end', token);
    } on Object catch (error) {
      debugPrint('[BackgroundTaskApi] end failed: $error');
    }
  }
}
