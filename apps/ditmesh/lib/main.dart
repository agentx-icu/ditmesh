import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'desktop/desktop_platform.dart';
import 'desktop/desktop_shell_controller.dart';
import 'desktop/init_desktop_shell.dart';
import 'di/app_features.dart';
import 'di/app_scope.dart';
import 'di/app_services.dart';
import 'di/app_settings.dart';
import 'di/backend_factory.dart';
import 'di/desktop_store_adapter.dart';
import 'i18n/current_strings.dart';
import 'i18n/key_value_store.dart';
import 'i18n/l10n_extension.dart';
import 'i18n/locale_controller.dart';
import 'lifecycle/background_task_api.dart';
import 'notifications/app_badge_plus_api.dart';
import 'notifications/flutter_local_notifications_api.dart';
import 'startup/startup_gate.dart';
import 'startup/native_backend_startup.dart';
import 'ui/account/account_routes.dart';
import 'ui/account/backup_file_gateway.dart';
import 'ui/learn/settings/training_settings_entry.dart';
import 'ui/shell/app_shell.dart';
import 'ui/theme.dart';
import 'training/guest_profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // One settings file for app-wide choices (language, theme, playback,
  // notifications and window bounds). Learning data lives per identity.
  final KeyValueStore settingsStore = await _openSettingsStore();

  // Desktop only: window bounds, close-to-tray, tray menu. No-op elsewhere.
  DesktopShellController? desktopShell;
  if (isDesktopTarget(defaultTargetPlatform)) {
    desktopShell = await initDesktopShell(
      DesktopShellConfig(
        store: DesktopStoreAdapter(settingsStore),
        // Product name, never translated; resolved through S so the desktop
        // shell has no English literal of its own.
        appName: currentS().appName,
        log: kDebugMode ? debugPrint : null,
      ),
    );
  }

  runApp(
    NativeBackendStartup(
      prepare: () => resolveBackendFactory(AppFeatures.fromEnvironment),
      store: settingsStore,
      ready: (backend) => DitmeshApp(
        backend: backend,
        localeStore: settingsStore,
        desktopShell: desktopShell,
        notifications: NotificationApis(
          notifications: FlutterLocalNotificationsApi(),
          badge: AppBadgePlusApi(),
        ),
        backgroundTasks: BackgroundTaskApi.forPlatform(),
      ),
    ),
  );
}

/// `<application support>/settings.json`; falls back to memory if the
/// directory cannot be created (the app still runs, preferences just do not
/// survive a restart).
Future<KeyValueStore> _openSettingsStore() async {
  try {
    final dir = await getApplicationSupportDirectory();
    return await JsonFileKeyValueStore.open(
      File(p.join(dir.path, 'settings.json')),
    );
  } on Object catch (error) {
    debugPrint('settings store unavailable, using memory: $error');
    return InMemoryKeyValueStore();
  }
}

/// Root widget: services from [backend] via [AppScope], then Material 3 with
/// light/dark following the system setting, and the [StartupGate] guarding
/// the responsive [AppShell].
class DitmeshApp extends StatelessWidget {
  const DitmeshApp({
    super.key,
    required this.backend,
    this.backupFiles,
    this.guestStore,
    this.localeStore,
    this.desktopShell,
    this.notifications,
    this.backgroundTasks,
    this.features = AppFeatures.fromEnvironment,
  });

  final BackendFactory backend;

  /// Optional context for isolated learning-surface tests; chat stays enabled.
  final AppFeatures features;

  /// Test hook: replaces the native save/pick dialogs.
  final BackupFileGateway? backupFiles;

  /// Guest learning storage; defaults to app support storage.
  final GuestStore? guestStore;

  /// Persistence for app preferences; memory when null.
  final KeyValueStore? localeStore;

  /// Initialised desktop shell (window + tray); null on mobile and in tests.
  final DesktopShellController? desktopShell;

  /// Real notification plugins; null disables OS notifications (tests).
  final NotificationApis? notifications;

  /// OS background-task bridge (iOS); null in tests.
  final BackgroundTaskApi? backgroundTasks;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      factory: backend,
      backupFiles: backupFiles,
      guestStore: guestStore,
      localeStore: localeStore,
      desktopShell: desktopShell,
      notificationApis: notifications,
      backgroundTasks: backgroundTasks,
      features: features,
      child: Builder(
        builder: (context) {
          final appearance = context.watch<AppSettings>();
          final locale = context.watch<LocaleController>().locale;
          return MaterialApp(
            // onGenerateTitle supersedes `title`; the window/task title is
            // the (untranslated) product name from the ARB.
            onGenerateTitle: (context) => S.of(context).appName,
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            locale: locale,
            // Same rules as LocaleController.effectiveLocale and currentS():
            // the whole preferred list in order, script/region aware
            // (zh-TW/HK/MO -> Traditional when shipped), unknown -> English.
            localeListResolutionCallback: LocaleController.resolve,
            debugShowCheckedModeBanner: false,
            theme: DitmeshTheme.light(style: appearance.style),
            darkTheme: DitmeshTheme.dark(style: appearance.style),
            themeMode: appearance.themeMode,
            themeAnimationDuration: Duration.zero,
            home: const StartupGate(child: AppShell()),
            routes: {
              kTrainingSettingsRoute: (_) => const TrainingSettingsEntry(),
            },
          );
        },
      ),
    );
  }
}
