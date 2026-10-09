import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../desktop/desktop_shell_controller.dart';
import '../diagnostics/connection_diagnostics.dart';
import '../i18n/key_value_store.dart';
import '../i18n/locale_controller.dart';
import '../keying/key_profiles.dart';
import '../lifecycle/app_lifecycle_coordinator.dart';
import '../lifecycle/background_task_api.dart';
import '../lifecycle/network_change_rebootstrapper.dart';
import '../notifications/connection_banner_policy.dart';
import '../notifications/notification_center.dart';
import '../notifications/notification_prefs.dart';
import '../startup/startup_controller.dart';
import '../training/guest_profile.dart';
import '../training/training_controller_host.dart';
import '../ui/chat/search/message_bookmarks.dart';
import '../ui/account/backup_file_gateway.dart';
import '../ui/chat/morse_playback_settings.dart';
import '../ui/chat/conversation_playback_preferences.dart';
import '../ui/chat/first_chat_progress.dart';
import '../ui/listen/listen_preferences.dart';
import '../ui/reference/reference_playback_settings.dart';
import 'app_features.dart';
import 'app_preferences.dart';
import 'app_services.dart';
import 'app_settings.dart';
import 'backend_factory.dart';

/// Builds the backend services once from a [BackendFactory] and exposes them
/// to the whole widget tree — including routes pushed on the root navigator,
/// which is why this sits ABOVE `MaterialApp` rather than inside the shell.
///
/// Provided: [IdentityService], [ChatService], [BackupFileGateway],
/// [AppSettings], [StartupController], [LocaleController],
/// [MorsePlaybackSettings], [AppLifecycleCoordinator],
/// [ConnectionBannerPolicy], [ConnectionDiagnostics], [NotificationPrefs],
/// and — when `main()` supplies them — [NotificationCenter] and
/// [DesktopShellController] (nullable).
class AppScope extends StatefulWidget {
  const AppScope({
    super.key,
    required this.factory,
    required this.child,
    this.backupFiles,
    this.guestStore,
    this.localeStore,
    this.notificationApis,
    this.desktopShell,
    this.backgroundTasks,
    this.networkSnapshots,
    this.features = AppFeatures.fromEnvironment,
  });

  final BackendFactory factory;

  /// Optional context for isolated secondary learning-surface tests.
  final AppFeatures features;
  final Widget child;

  /// Override for the file save/pick gateway; tests pass a fake.
  final BackupFileGateway? backupFiles;

  /// Where guest learning data lives; defaults to app support storage.
  final GuestStore? guestStore;

  /// Where the language choice persists; defaults to memory (tests, fake
  /// backend). `main()` passes a file-backed store.
  final KeyValueStore? localeStore;

  /// Real notification plugins from `main()`; null disables OS notifications
  /// (tests, or platforms without support).
  final NotificationApis? notificationApis;

  /// Initialised desktop shell from `main()`; null on mobile and in tests.
  final DesktopShellController? desktopShell;

  /// OS background-task bridge from `main()` (iOS grace time while the
  /// durability flush runs); null means none (tests).
  final BackgroundTaskApi? backgroundTasks;

  /// Explicit platform stream from main; tests leave platform channels untouched.
  final Stream<NetworkPathSnapshot>? networkSnapshots;

  @override
  State<AppScope> createState() => _AppScopeState();
}

class _AppScopeState extends State<AppScope> {
  late final NetworkBootstrapService? _network = widget.factory
      .createNetworkBootstrapService();
  late final IdentityService _identity = widget.factory.createIdentityService();
  late final ChatService _chat = widget.factory.createChatService(_identity);
  late final KeyValueStore _store =
      widget.localeStore ?? InMemoryKeyValueStore();
  late final AppPreferences _preferences = AppPreferences(
    _store,
    backendLabel: widget.factory.label,
    identity: _identity,
  );
  AppSettings get _settings => _preferences.settings;
  late final GuestStore _guest = widget.guestStore ?? GuestStore();
  late final StartupController _startup = StartupController(_identity);
  late final BackupFileGateway _backupFiles =
      widget.backupFiles ?? const PlatformBackupFileGateway();
  late final LocaleController _locale = LocaleController(_store);

  /// Device-local key bindings for every keying surface (F12).
  late final KeyProfiles _keyProfiles = KeyProfiles(_store);
  MorsePlaybackSettings get _playback => _preferences.playback;
  late final AppServices _services = AppServices(
    identity: _identity,
    chat: _chat,
    locale: _locale,
    notificationApis: widget.notificationApis,
    notificationPrefs: _preferences.notifications,
    onBackground: _flushSettings,
    backgroundTasks: widget.backgroundTasks,
    networkBootstrap: _network,
    networkSnapshots: widget.networkSnapshots,
    // The startup controller owns connect(): its error is the chip's too.
    reconnect: () async {
      await _startup.reconnect();
      return _startup.connectionError;
    },
    desktopShell: widget.desktopShell,
    chatEnabled: true,
  );

  late final TrainingControllerHost _training = TrainingControllerHost(
    _identity,
    guestMode: _startup.guestMode,
    guestFactory: _guest.openController,
  );

  /// Everything local that must reach disk before the app is suspended or
  /// quits, including settings for chat-assisted Morse practice.
  Future<void> _flushSettings() async {
    await Future.wait([
      _preferences.flush(),
      _locale.flush(),
      _keyProfiles.flush(),
      _training.flush(),
    ]);
  }

  @override
  void initState() {
    super.initState();
    _bookmarkBarrier = MessageBookmarksBarrier(_identity);
    // Context-free code (notifications, tray) reads strings through
    // currentS() / the services' StringsResolver, both following this
    // controller. Set before start(): the resolver is built from _locale, and
    // start() pushes the persisted language into the desktop shell.
    LocaleController.active = _locale;
    _services.start();
  }

  /// Flushes / retires chat bookmarks around identity replacement.
  late final MessageBookmarksBarrier _bookmarkBarrier;

  @override
  void dispose() {
    if (LocaleController.active == _locale) LocaleController.active = null;
    _training.dispose().ignore();
    _bookmarkBarrier.dispose();
    _services.dispose().ignore();
    _preferences.dispose();
    _locale.dispose();
    _keyProfiles.dispose();
    _startup.dispose();
    // Fire-and-forget: the scope is going away and there is nobody left to
    // report to; the fake and the real backend both log internally.
    widget.factory.disposeServices(identity: _identity, chat: _chat).ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppFeatures>.value(value: widget.features),
        Provider<IdentityService>.value(value: _identity),
        Provider<NetworkBootstrapService?>.value(value: _network),
        Provider<ChatService>.value(value: _chat),
        Provider<BackupFileGateway>.value(value: _backupFiles),
        Provider<AppPreferences>.value(value: _preferences),
        ChangeNotifierProvider<FirstChatProgress>.value(
          value: _preferences.firstChat,
        ),
        ChangeNotifierProvider<AppSettings>.value(value: _settings),
        ChangeNotifierProvider<StartupController>.value(value: _startup),
        ChangeNotifierProvider<LocaleController>.value(value: _locale),
        ChangeNotifierProvider<KeyProfiles?>.value(value: _keyProfiles),
        ChangeNotifierProvider<MorsePlaybackSettings>.value(value: _playback),
        ChangeNotifierProvider<ConversationPlaybackPreferences>.value(
          value: _preferences.conversations,
        ),
        ChangeNotifierProvider<ReferencePlaybackSettings>.value(
          value: _preferences.reference,
        ),
        ChangeNotifierProvider<ListenPreferences>.value(
          value: _preferences.listen,
        ),
        Provider<AppLifecycleCoordinator>.value(value: _services.lifecycle),
        Provider<ConnectionBannerPolicy>.value(value: _services.banner),
        ChangeNotifierProvider<ConnectionDiagnostics>.value(
          value: _services.diagnostics,
        ),
        ChangeNotifierProvider<NotificationPrefs>.value(
          value: _services.notificationPrefs,
        ),
        Provider<NotificationCenter?>.value(value: _services.notifications),
        // A ChangeNotifier must go through a listenable provider: a plain
        // Provider fails provider's debug type check, which crashed every
        // debug launch on desktop (caught by integration_test/app_launch_test).
        ChangeNotifierProvider<DesktopShellController?>.value(
          value: widget.desktopShell,
        ),
        Provider<TrainingControllerHost?>.value(value: _training),
        Provider<GuestStore?>.value(value: _guest),
        Provider<BookmarksResolver?>.value(
          value: () async => MessageBookmarks.forProfile(
            await _identity.dataDirectory(),
            _identity.current?.publicKey ?? '',
          ),
        ),
      ],
      child: widget.child,
    );
  }
}
