import 'dart:async';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../desktop/desktop_shell_controller.dart';
import '../diagnostics/connection_diagnostics.dart';
import '../i18n/locale_controller.dart';
import '../i18n/strings_resolver.dart';
import '../lifecycle/app_lifecycle_coordinator.dart';
import '../lifecycle/background_task_api.dart';
import '../notifications/badge_api.dart';
import '../notifications/connection_banner_policy.dart';
import '../notifications/local_notifications_api.dart';
import '../notifications/notification_center.dart';
import '../notifications/notification_prefs.dart';

/// The two plugin-backed APIs the notification centre needs. `main()` passes
/// the real ones; widget tests pass nothing, so no notification code that
/// touches platform channels runs under `flutter test`.
final class NotificationApis {
  const NotificationApis({required this.notifications, required this.badge});

  final LocalNotificationsApi notifications;
  final BadgeApi badge;
}

/// Cross-cutting services that live for the whole app session and hang off
/// the identity / chat services: lifecycle tracking, the offline banner,
/// OS notifications and the desktop shell's unread count.
///
/// Built by `AppScope`; everything here is plugin-free unless
/// [NotificationApis] or a [DesktopShellController] is supplied.
///
/// Language for the context-free surfaces: [strings] is a [StringsResolver]
/// on the scope's [LocaleController]. Notifications read it at post time;
/// the desktop shell is re-labelled through
/// [DesktopShellController.updateStrings] on [start] and on every change.
final class AppServices {
  AppServices({
    required IdentityService identity,
    required ChatService chat,
    required LocaleController locale,
    NotificationApis? notificationApis,
    NotificationPrefs? notificationPrefs,
    Future<void> Function()? onBackground,
    BackgroundTaskApi? backgroundTasks,
    Future<Object?> Function()? reconnect,
    this.desktopShell,
    this.chatEnabled = true,
  }) : lifecycle = AppLifecycleCoordinator(
         identity: identity,
         onBackground: () => _flushDurable(identity, onBackground),
         // Null in widget tests: no platform channel is touched there.
         backgroundTasks: chatEnabled && backgroundTasks != null
             ? backgroundTasks
             : const NoopBackgroundTaskApi(),
       ),
       banner = ConnectionBannerPolicy(identity: identity),
       notificationPrefs = notificationPrefs ?? NotificationPrefs(),
       _ownsNotificationPrefs = notificationPrefs == null,
       strings = StringsResolver(locale),
       _chat = chat,
       _identity = identity,
       _onBackground = onBackground {
    diagnostics = ConnectionDiagnostics(
      identity: identity,
      chat: chat,
      lifecycleHints: lifecycle.hints,
      reconnect: reconnect,
    );
    // Isolated service tests can disable OS-facing chat services.
    final apis = chatEnabled ? notificationApis : null;
    notifications = apis == null
        ? null
        : NotificationCenter(
            chat: chat,
            notifications: apis.notifications,
            badge: apis.badge,
            prefs: this.notificationPrefs,
            isForeground: lifecycle.isForeground,
            identity: identity,
            strings: () => strings.s,
          );
  }

  final ChatService _chat;
  final IdentityService _identity;
  final Future<void> Function()? _onBackground;
  final AppLifecycleCoordinator lifecycle;
  final ConnectionBannerPolicy banner;

  /// Per-identity connection observations for the diagnostics page (F09).
  late final ConnectionDiagnostics diagnostics;
  final NotificationPrefs notificationPrefs;
  final bool _ownsNotificationPrefs;
  final DesktopShellController? desktopShell;

  /// Optional switch for isolated service tests; production enables chat.
  final bool chatEnabled;

  /// Current-language strings for code without a `BuildContext`; fires on a
  /// language change (setting or, while following the system, OS locale).
  final StringsResolver strings;

  late final NotificationCenter? notifications;

  StreamSubscription<List<Conversation>>? _unreadSub;
  bool _started = false;

  /// Idempotent. Safe to call before the identity exists: every piece reacts
  /// to streams, nothing here blocks on the network.
  void start() {
    if (_started) return;
    _started = true;
    // Before attach(): a launch straight into the background emits its
    // `background` hint synchronously, and diagnostics must see it.
    if (chatEnabled) diagnostics.start();
    lifecycle.attach();
    if (chatEnabled) banner.start();
    final center = notifications;
    if (center != null) unawaited(center.start());
    // Language changes reach the tray (desktop) and the Android channel
    // names; both are re-applied from the current strings.
    strings.addListener(_onStringsChanged);
    final shell = desktopShell;
    if (shell != null) {
      shell.addBeforeQuitListener(_beforeQuit);
      // The shell was built in main() before the LocaleController existed:
      // apply the persisted language now, then follow changes.
      shell.updateStrings(strings.s);
      shell.setUnreadCount(_totalUnread(_chat.conversations));
      _unreadSub = _chat.conversationChanges.listen(
        (list) => shell.setUnreadCount(_totalUnread(list)),
      );
    }
  }

  Future<void> _beforeQuit() async {
    final identity = _identity;
    await _flushDurable(identity, _onBackground);
    await identity.disconnect();
  }

  static Future<void> _flushDurable(
    IdentityService identity,
    Future<void> Function()? settings,
  ) async {
    await Future.wait<void>([
      if (identity is PersistentIdentityService)
        Future<void>.sync(identity.persist),
      if (settings != null) Future<void>.sync(settings),
    ]);
  }

  void _onStringsChanged() {
    desktopShell?.updateStrings(strings.s);
    final center = notifications;
    if (center != null) unawaited(center.refreshStrings());
  }

  static int _totalUnread(List<Conversation> list) =>
      list.fold<int>(0, (sum, c) => sum + c.unreadCount);

  /// Tears everything down. Every child's `dispose()` is STARTED before the
  /// first `await`: `AppScope.dispose()` (a synchronous Flutter `dispose`)
  /// cannot wait for us, so the synchronous prefix of each child - stream
  /// cancellation, timer cancellation - must run right now. A serial
  /// `await a(); await b();` would leave `b`'s timers ticking for as many
  /// microtask hops as `a` takes, and the widget tree would already be gone
  /// (`flutter test` flags exactly that as a pending timer).
  Future<void> dispose() async {
    // The scope disposes its LocaleController right after calling us and
    // the resolver must have let go of it by then.
    strings.removeListener(_onStringsChanged);
    strings.dispose();
    desktopShell?.removeBeforeQuitListener(_beforeQuit);
    final pending = <Future<void>>[
      ?_unreadSub?.cancel(),
      ?notifications?.dispose(),
      banner.dispose(),
      lifecycle.dispose(),
    ];
    diagnostics.dispose();
    if (_ownsNotificationPrefs) notificationPrefs.dispose();
    await Future.wait(pending);
  }
}
