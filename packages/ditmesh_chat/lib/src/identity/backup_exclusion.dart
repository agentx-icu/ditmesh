import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../logging/chat_logger.dart';

/// Keeps the identity tree out of platform backups.
///
/// iOS backs up `Library/Application Support` to iCloud / Finder by default,
/// and the identity tree holds the Tox private key (plaintext when no
/// password is set). Only the encrypted in-app export should move an
/// identity, the same rule `android:allowBackup="false"` and the
/// data-extraction rules enforce on Android. macOS needs nothing: the
/// sandbox container is backed up only by the user's own Time Machine disk,
/// not a cloud service, so Linux / Windows / macOS / Android use
/// [NoBackupExclusion].
abstract interface class BackupExclusion {
  /// Marks the existing directory [path] (and so everything under it) as
  /// excluded from backup. Never throws: failure is logged and the caller
  /// carries on, since a missing flag must not block the identity.
  Future<void> exclude(String path);

  /// The implementation for the running platform.
  static BackupExclusion forPlatform({
    ChatLogger logger = const SilentChatLogger(),
  }) => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
      ? MethodChannelBackupExclusion(logger: logger)
      : const NoBackupExclusion();
}

/// Platforms (and tests) with nothing to mark.
final class NoBackupExclusion implements BackupExclusion {
  const NoBackupExclusion();

  @override
  Future<void> exclude(String path) async {}
}

/// iOS: `ios/Runner/AppDelegate.swift` sets
/// `URLResourceValues.isExcludedFromBackup` for [methodName] on
/// [channelName].
final class MethodChannelBackupExclusion implements BackupExclusion {
  MethodChannelBackupExclusion({
    MethodChannel? channel,
    ChatLogger logger = const SilentChatLogger(),
  }) : _channel = channel ?? const MethodChannel(channelName),
       _logger = logger;

  static const String channelName = 'icu.agentx.ditmesh/backup_exclusion';
  static const String methodName = 'excludeFromBackup';

  final MethodChannel _channel;
  final ChatLogger _logger;

  @override
  Future<void> exclude(String path) async {
    try {
      await _channel.invokeMethod<void>(methodName, path);
    } on Object catch (error, stack) {
      // MissingPluginException (an older native build) or the OS refusing:
      // the identity still works, it is just eligible for device backup.
      _logger.error('[Identity] could not exclude $path from backup', error, stack);
    }
  }
}
