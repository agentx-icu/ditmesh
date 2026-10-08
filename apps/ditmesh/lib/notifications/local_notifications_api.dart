import 'package:flutter/foundation.dart';

/// Android notification channel (also used as the Darwin category / Linux
/// hint bucket) a request belongs to. One channel per social event so the
/// user can mute friend requests without losing group invites.
enum NotificationChannelKind { messages, friendRequests, groupInvites }

/// Platform-neutral description of one OS notification.
///
/// [id] is stable per logical target (see `stableNotificationId`), so posting
/// again with the same id replaces the previous banner instead of stacking a
/// new one. [lines] carries the per-conversation inbox history for Android's
/// `InboxStyleInformation`; Darwin stacks by [groupKey] on its own.
@immutable
final class NotificationRequest {
  const NotificationRequest({
    required this.id,
    required this.channel,
    required this.title,
    required this.body,
    required this.payload,
    this.groupKey,
    this.lines = const <String>[],
    this.summary,
    this.sound = true,
    this.silentUpdate = false,
  });

  final int id;
  final NotificationChannelKind channel;
  final String title;
  final String body;

  /// Round-trips through the OS; see `NotificationTapTarget`.
  final String payload;

  /// Android `groupKey` / Darwin `threadIdentifier`; null = no grouping.
  final String? groupKey;

  /// Inbox lines (oldest first) when more than one message is pending for
  /// the same target; empty for a single notification.
  final List<String> lines;

  /// Collapsed-state summary shown with [lines], e.g. "3 new messages".
  final String? summary;

  final bool sound;

  /// Replaces a notification already on screen without alerting again: no
  /// sound, vibration, banner or heads-up (Android `onlyAlertOnce` +
  /// `silent`, Darwin passive and list-only). Used when blocking someone
  /// takes their lines out of a stacked notification.
  final bool silentUpdate;
}

/// The only surface through which the app touches the local-notifications
/// plugin. `FlutterLocalNotificationsApi` is the production implementation;
/// `testing/fake_local_notifications_api.dart` records calls for tests.
///
/// Every method is best-effort: implementations swallow platform-channel
/// failures (missing plugin in unit tests, denied permission, unsupported
/// backend) and report them through `debugPrint` rather than throwing.
abstract interface class LocalNotificationsApi {
  /// Initialises the plugin. [onTap] receives the payload of a notification
  /// the user selected while the app was running. Returns false when the
  /// platform has no backend or initialisation failed; callers then skip
  /// [show] entirely.
  Future<bool> initialize({required ValueChanged<String> onTap});

  /// Payload of the notification that launched the app (cold start), or null.
  /// Consumed once.
  Future<String?> takeLaunchPayload();

  /// Requests the OS permission where one exists (Android 13+, iOS, macOS).
  /// Returns true where no permission concept exists (Linux, Windows).
  /// May show a system dialog, so only call it while the app is visible.
  Future<bool> requestPermission();

  /// Whether posting is currently allowed, WITHOUT prompting: safe from the
  /// background. True where no permission concept exists.
  Future<bool> isPermissionGranted();

  Future<void> show(NotificationRequest request);

  Future<void> cancel(int id);

  Future<void> cancelAll();

  /// Payloads of this app's notifications still on screen (posted by this
  /// or an earlier run). Empty where the platform cannot tell.
  Future<List<String>> activePayloads();

  /// Channels the user has turned off in the OS settings (Android: channel
  /// importance `none`), read WITHOUT prompting. The OS then drops every
  /// post to that channel while [isPermissionGranted] stays true. Empty
  /// where channels do not exist or cannot be read.
  Future<Set<NotificationChannelKind>> blockedChannels();

  /// Re-applies language-dependent OS metadata after a language change:
  /// on Android the channel names/descriptions shown in Settings (Android
  /// freezes importance and sound at creation but takes a new name on
  /// re-creation of the same id). No-op before [initialize] and elsewhere.
  Future<void> refreshStrings();
}
