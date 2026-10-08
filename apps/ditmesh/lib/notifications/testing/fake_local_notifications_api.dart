import 'dart:async';

import 'package:flutter/foundation.dart';

import '../local_notifications_api.dart';
import '../notification_payload.dart';

/// Recording [LocalNotificationsApi] for tests. Never touches a platform
/// channel; exposes everything the production plugin would have been told.
final class FakeLocalNotificationsApi implements LocalNotificationsApi {
  FakeLocalNotificationsApi({
    this.permissionGranted = true,
    this.initializeResult = true,
    this.launchPayload,
  });

  /// The OS permission state: what [isPermissionGranted] reports and what
  /// [requestPermission] answers (unless [grantOnRequest] changes it first).
  bool permissionGranted;

  /// When non-null, the user's answer to the next prompt: [requestPermission]
  /// stores it in [permissionGranted] before answering.
  bool? grantOnRequest;

  /// When non-null, the prompt stays on screen until this completes; its
  /// value is the user's answer (overrides [grantOnRequest]).
  Future<bool>? promptAnswer;

  /// When non-null, the silent permission check ([isPermissionGranted]) is
  /// still running until this completes; its value is the OS answer.
  Future<bool>? permissionCheckAnswer;

  /// What [initialize] answers (false simulates a plugin failure).
  bool initializeResult;

  /// Returned once by [takeLaunchPayload] (cold-start tap).
  String? launchPayload;

  /// Every [show] call, in order (including replacements of the same id).
  final List<NotificationRequest> shown = <NotificationRequest>[];
  final List<int> cancelled = <int>[];
  int cancelAllCalls = 0;
  int refreshStringsCalls = 0;
  int permissionRequests = 0;
  int permissionChecks = 0;
  bool initialized = false;

  final Map<int, NotificationRequest> _active = <int, NotificationRequest>{};
  ValueChanged<String>? _onTap;

  /// Notifications currently on screen (shown and not cancelled), by id.
  List<NotificationRequest> get active =>
      List<NotificationRequest>.unmodifiable(_active.values);

  NotificationRequest? get last => shown.isEmpty ? null : shown.last;

  /// Simulates the user tapping a notification with this payload.
  void tap(String payload) => _onTap?.call(payload);

  void tapTarget(NotificationTapTarget target) => tap(target.encode());

  /// Runs while [initialize] is in progress (after the tap callback is
  /// registered), e.g. to simulate a tap during plugin start-up.
  void Function()? onInitialize;

  @override
  Future<bool> initialize({required ValueChanged<String> onTap}) async {
    _onTap = onTap;
    onInitialize?.call();
    initialized = initializeResult;
    return initializeResult;
  }

  /// Runs while [takeLaunchPayload] is being answered (simulates a tap
  /// that arrives during that await).
  void Function()? onTakeLaunchPayload;

  @override
  Future<String?> takeLaunchPayload() async {
    final String? payload = launchPayload;
    launchPayload = null;
    // A microtask, not a timer: usable inside testWidgets without a pump.
    await Future<void>.microtask(() {});
    onTakeLaunchPayload?.call();
    return payload;
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    final Future<bool>? held = promptAnswer;
    if (held != null) {
      permissionGranted = await held;
      return permissionGranted;
    }
    final bool? answer = grantOnRequest;
    if (answer != null) permissionGranted = answer;
    return permissionGranted;
  }

  @override
  Future<bool> isPermissionGranted() async {
    permissionChecks++;
    final Future<bool>? held = permissionCheckAnswer;
    if (held != null) return held;
    return permissionGranted;
  }

  @override
  Future<void> show(NotificationRequest request) async {
    shown.add(request);
    _active[request.id] = request;
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    _active.remove(id);
  }

  @override
  Future<void> refreshStrings() async {
    refreshStringsCalls++;
  }

  /// When set, [activePayloads] waits for it before answering.
  Completer<void>? holdActivePayloads;

  @override
  Future<List<String>> activePayloads() async {
    await holdActivePayloads?.future;
    return [for (final NotificationRequest n in _active.values) n.payload];
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    _active.clear();
  }

  /// Channels the OS reports as turned off by the user.
  Set<NotificationChannelKind> blocked = <NotificationChannelKind>{};
  int blockedChannelChecks = 0;

  @override
  Future<Set<NotificationChannelKind>> blockedChannels() async {
    blockedChannelChecks++;
    return Set<NotificationChannelKind>.of(blocked);
  }
}
