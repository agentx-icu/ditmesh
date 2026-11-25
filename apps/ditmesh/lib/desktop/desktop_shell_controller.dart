import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../i18n/current_strings.dart';
import '../l10n/generated/s.dart';
import 'desktop_platform.dart';
import 'screen_api.dart';
import 'tray_api.dart';
import 'tray_host_watch.dart';
import 'window_api.dart';
import 'window_bounds.dart';

part 'desktop_shell_tray.dart';

/// Keys of the tray context-menu rows (see [DesktopShellController.trayMenu]).
abstract final class TrayMenuKeys {
  static const String showHide = 'show_hide';
  static const String sound = 'sound';
  static const String quit = 'quit';
}

/// Desktop window + system-tray behaviour for the app shell.
///
/// Owns the window title (with unread count), the tray icon / tooltip / menu,
/// close-to-tray, and the persistence of window bounds through the injected
/// `KeyValueStore`. Every plugin call is gated on [DesktopShellConfig.isDesktop]
/// so on Android / iOS / web the controller is inert state: [initialize] and
/// the window/tray methods return immediately without touching the APIs.
///
/// The tray is cosmetic. Any tray failure (no StatusNotifier host on Linux,
/// a per-platform gap such as Linux tooltips) is logged and swallowed; it
/// never takes the app down and never blocks the first frame.
///
/// Language: menu labels, tooltip and title render from [strings]
/// ([currentS] at construction, i.e. the platform locale before the app's
/// `LocaleController` exists). `AppServices` calls [updateStrings] with the
/// user's choice once the scope is up and again on every language change;
/// the product name itself ([DesktopShellConfig.appName]) is never translated.
class DesktopShellController extends ChangeNotifier
    implements WindowEventHandler, TrayEventHandler {
  DesktopShellController({
    required this.config,
    required WindowApi window,
    required TrayApi tray,
    required ScreenApi screen,
    S? strings,
  }) : _window = window,
       _tray = tray,
       _screen = screen,
       _closeToTray = config.closeToTray,
       _soundEnabled = config.soundEnabled,
       _s = strings ?? currentS();

  static const String boundsKey = 'desktop.windowBounds';
  static const String closeToTrayKey = 'desktop.closeToTray';
  static const String soundEnabledKey = 'desktop.soundEnabled';

  final DesktopShellConfig config;
  final WindowApi _window;
  final TrayApi _tray;
  final ScreenApi _screen;

  bool _initialized = false;
  bool _active = false;
  bool _trayAvailable = false;
  bool _windowVisible = false;
  bool _closing = false;
  Rect? _normalBounds;
  bool _closeToTray;
  bool _soundEnabled;
  S _s;
  int _unreadCount = 0;
  Timer? _persistTimer;
  Future<void> _trayQueue = Future<void>.value();
  int _trayGeneration = 0;
  bool _trayGapWarned = false;
  final Set<Future<void> Function()> _beforeQuit = {};
  late final _trayHostWatch = TrayHostWatch(
    isAvailable: () async => _trayAvailable && await _hasTrayHost(),
    onLost: () async {
      _trayAvailable = false;
      await _tolerate('show window', showWindow);
    },
  );

  void addBeforeQuitListener(Future<void> Function() listener) =>
      _beforeQuit.add(listener);

  void removeBeforeQuitListener(Future<void> Function() listener) =>
      _beforeQuit.remove(listener);

  /// True once [initialize] ran on a desktop platform.
  bool get isActive => _active;

  /// True when the tray icon was created and can be relied on.
  bool get isTrayAvailable => _trayAvailable;

  bool get isWindowVisible => _windowVisible;

  bool get closeToTray => _closeToTray;

  bool get soundEnabled => _soundEnabled;

  int get unreadCount => _unreadCount;

  /// The strings the title, tooltip and menu currently render from.
  S get strings => _s;

  /// "(3) DitMesh" while there is unread traffic, else the plain app name.
  String get windowTitle => _unreadCount > 0
      ? _s.desktopWindowTitleUnread(trayBadge, config.appName)
      : config.appName;

  /// Tray tooltip: "DitMesh — 3 unread messages" or the plain app name.
  String get trayTooltip => _unreadCount > 0
      ? _s.desktopTrayTooltipUnread(config.appName, _unreadCount)
      : config.appName;

  /// Short count shown next to the macOS status item (and in the title).
  String get trayBadge => _unreadCount > 99 ? '99+' : '$_unreadCount';

  /// Current context-menu rows; labels follow visibility, sound state and
  /// language. Shortcut hints are not part of the tray menu (the OS renders
  /// accelerators itself); in-app labels come from `shortcutLabel`.
  List<TrayMenuEntry> get trayMenu => [
    TrayMenuEntry(
      key: TrayMenuKeys.showHide,
      label: _windowVisible
          ? _s.desktopTrayHide(config.appName)
          : _s.desktopTrayShow(config.appName),
    ),
    if (config.onToggleSound != null)
      TrayMenuEntry(
        key: TrayMenuKeys.sound,
        label: _soundEnabled ? _s.desktopTraySoundOn : _s.desktopTraySoundOff,
        checked: _soundEnabled,
      ),
    const TrayMenuEntry.separator(),
    TrayMenuEntry(
      key: TrayMenuKeys.quit,
      label: _s.desktopTrayQuit(config.appName),
    ),
  ];

  /// Switches the language of the title, tooltip and menu. A no-op for the
  /// locale already in use; otherwise the window title is re-set and the
  /// tray rebuilt (queued behind pending tray updates). Safe before
  /// [initialize] and on mobile (state only).
  void updateStrings(S strings) {
    if (strings.localeName == _s.localeName) return;
    _s = strings;
    notifyListeners();
    if (!_active) return;
    unawaited(_tolerate('setTitle', () => _window.setTitle(windowTitle)));
    _enqueueTray(_applyTrayState);
  }

  /// Creates the window (restoring persisted bounds, clamped to today's
  /// displays) and the tray. Idempotent; a no-op off desktop.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (!config.isDesktop) return;

    _closeToTray = await _readCloseToTray();
    final sound = await _read(soundEnabledKey);
    _soundEnabled = sound == 'false'
        ? false
        : sound == 'true'
        ? true
        : config.soundEnabled;
    await _window.ensureInitialized();
    final areas = await _workAreas();
    final primary = areas.isEmpty ? null : areas.first;
    final minSize = fitSizeToArea(config.minimumSize, primary);
    final saved = WindowBounds.decode(await _read(boundsKey));
    final target = (saved ?? WindowBounds.centered(config.defaultSize, primary))
        .fitTo(areas, minSize);

    _window.setEventHandler(this);
    // Always intercept close: even without close-to-tray we must persist the
    // bounds and run onBeforeQuit before the runner exits.
    await _window.setPreventClose(true);
    await _window.waitUntilReadyToShow(
      title: windowTitle,
      minimumSize: minSize,
      size: target.rect.size,
    );
    _normalBounds = target.rect;
    await _window.setBounds(target.rect);
    await _window.show();
    await _window.focus();
    if (target.maximized) await _window.maximize();
    _windowVisible = true;
    _active = true;
    await _initTray();
    if (_active) notifyListeners();
  }

  Future<List<Rect>> _workAreas() async {
    try {
      return await _screen.workAreas();
    } catch (e) {
      config.logger('[DesktopShell] display lookup failed: $e');
      return const [];
    }
  }

  /// Updates the window title, tray tooltip and macOS badge. Negative counts
  /// clamp to zero. Safe to call before [initialize] and on mobile (state
  /// only).
  void setUnreadCount(int count) {
    final next = count < 0 ? 0 : count;
    if (next == _unreadCount) return;
    _unreadCount = next;
    notifyListeners();
    if (!_active) return;
    unawaited(_tolerate('setTitle', () => _window.setTitle(windowTitle)));
    _enqueueTray(_applyTrayState);
  }

  /// Completes when every queued tray update has been applied (tests).
  Future<void> flushTrayUpdates() => _trayQueue;

  Future<void> showWindow() async {
    if (!_active) return;
    if (await _window.isMinimized()) await _window.restore();
    await _window.show();
    if (!_active) return;
    _setWindowVisible(true);
    await _window.focus();
  }

  /// Hides the window; the tray is the only way back, so this is refused
  /// when the tray is unavailable.
  Future<void> hideToTray() async {
    await _hideToTray();
  }

  Future<bool> _hideToTray() async {
    if (!_active || _closing) return false;
    if (_trayAvailable) {
      if (!await _hasTrayHost()) return false;
    } else if (config.trayHostAvailable != null) {
      await _initTray();
    }
    if (!_trayAvailable || _closing || !_active) return false;
    await persistWindowState();
    if (_closing || !_active) return false;
    await _window.hide();
    if (!_active) return false;
    _setWindowVisible(false);
    return true;
  }

  Future<void> toggleWindow() async {
    if (!_active) return;
    final visible = await _tolerateBool('isVisible', _window.isVisible);
    if (visible ?? _windowVisible) {
      await hideToTray();
    } else {
      await showWindow();
    }
  }

  void _setWindowVisible(bool visible) {
    if (visible) _trayHostWatch.stop();
    if (!visible) _watchHiddenTray();
    if (_windowVisible == visible) return;
    _windowVisible = visible;
    notifyListeners();
    _enqueueTray(_applyTrayState);
  }

  /// Reads the live bounds and maximised flag and stores them.
  Future<void> persistWindowState() async {
    if (!_active) return;
    try {
      final rect = await _window.getBounds();
      final maximized = await _window.isMaximized();
      if (!maximized &&
          !await _window.isFullScreen() &&
          !await _window.isMinimized()) {
        _normalBounds = rect;
      }
      await config.store.set(
        boundsKey,
        WindowBounds(
          rect: _normalBounds ?? rect,
          maximized: maximized,
        ).encode(),
      );
    } catch (e) {
      config.logger('[DesktopShell] could not persist window state: $e');
    }
  }

  Future<void> setCloseToTray(bool value) =>
      _trackPreference(_setCloseToTray(value));

  Future<void> _setCloseToTray(bool value) async {
    if (_closeToTray == value) return;
    final previous = _closeToTray;
    _closeToTray = value;
    notifyListeners();
    if (!config.isDesktop) return;
    try {
      await config.store.set(closeToTrayKey, value.toString());
    } catch (e) {
      if (_closeToTray == value) {
        _closeToTray = previous;
        notifyListeners();
      }
      config.logger('[DesktopShell] could not persist closeToTray: $e');
    }
  }

  Future<bool> _readCloseToTray() async {
    final raw = await _read(closeToTrayKey);
    return switch (raw) {
      'true' => true,
      'false' => false,
      _ => config.closeToTray,
    };
  }

  /// Placeholder for the sidetone owner: flips the tray checkbox and calls
  /// [DesktopShellConfig.onToggleSound].
  Future<void> setSoundEnabled(bool enabled) =>
      _trackPreference(_setSoundEnabled(enabled));

  Future<void> _setSoundEnabled(bool enabled) async {
    if (_soundEnabled == enabled) return;
    final previous = _soundEnabled;
    _soundEnabled = enabled;
    notifyListeners();
    try {
      if (config.isDesktop) {
        await config.store.set(soundEnabledKey, enabled.toString());
      }
    } catch (e) {
      if (_soundEnabled == enabled) {
        _soundEnabled = previous;
        notifyListeners();
      }
      config.logger('[DesktopShell] could not persist sound: $e');
      return;
    }
    try {
      await config.onToggleSound?.call(enabled);
    } catch (e) {
      config.logger('[DesktopShell] onToggleSound failed: $e');
    }
    if (_active) _enqueueTray(_applyTrayState);
  }

  /// Persists the window state, runs [DesktopShellConfig.onBeforeQuit] and
  /// closes the window for real. Idempotent.
  Future<void> quit() async {
    if (!_active || _closing) return;
    _closing = true;
    _trayGeneration++;
    _trayHostWatch.stop();
    _persistTimer?.cancel();
    await _pendingPreferences;
    await persistWindowState();
    try {
      for (final listener in _beforeQuit.toList()) {
        await listener();
      }
    } catch (e) {
      _closing = false;
      if (!_windowVisible) _watchHiddenTray();
      config.logger('[DesktopShell] could not save session before quit: $e');
      return;
    }
    try {
      await config.onBeforeQuit?.call();
    } catch (e) {
      config.logger('[DesktopShell] onBeforeQuit failed: $e');
    }
    await _trayQueue;
    await _tolerate('destroy tray', _tray.destroy);
    try {
      await _window.destroy();
    } on Object catch (error) {
      config.logger('[DesktopShell] destroy window failed: $error');
      if (_trayAvailable) {
        _trayAvailable = false;
        await _initTray(restoringAfterQuit: true);
      }
      if (!_trayAvailable && !_windowVisible) {
        await _tolerate('show window', showWindow);
      }
      _closing = false;
      if (!_windowVisible) _watchHiddenTray();
    }
  }

  @override
  void onCloseRequested() {
    unawaited(handleCloseRequested());
  }

  /// Close-to-tray hides (when the tray exists); otherwise this is the real
  /// exit path.
  Future<void> handleCloseRequested() async {
    if (!_active || _closing) return;
    if (_closeToTray && await _hideToTray()) return;
    await quit();
  }

  @override
  void onBoundsChanged() {
    if (!_active || _closing) return;
    _persistTimer?.cancel();
    _persistTimer = Timer(config.persistDebounce, () {
      _persistTimer = null;
      unawaited(persistWindowState());
    });
  }

  @override
  void onTrayIconClicked() {
    unawaited(toggleWindow());
  }

  @override
  void onTrayMenuItem(String key) {
    switch (key) {
      case TrayMenuKeys.showHide:
        unawaited(toggleWindow());
      case TrayMenuKeys.sound:
        unawaited(setSoundEnabled(!_soundEnabled));
      case TrayMenuKeys.quit:
        unawaited(quit());
    }
  }

  @override
  void dispose() {
    _trayGeneration++;
    _persistTimer?.cancel();
    _trayHostWatch.stop();
    if (_active) {
      _active = false;
      _window.setEventHandler(null);
      _tray.setEventHandler(null);
    }
    super.dispose();
  }

  Future<void> _pendingPreferences = Future<void>.value();

  Future<void> _trackPreference(Future<void> write) {
    _pendingPreferences = Future.wait<void>([
      _pendingPreferences,
      write,
    ]).then<void>((_) {});
    return write;
  }

  Future<String?> _read(String key) async {
    try {
      return await config.store.get(key);
    } catch (e) {
      config.logger('[DesktopShell] could not read $key: $e');
      return null;
    }
  }

  /// Runs one optional call, warning once about a per-platform gap (Linux
  /// tray_manager has no tooltip; some hosts reject titles).
  Future<void> _tolerate(String label, Future<void> Function() op) async {
    try {
      await op();
    } catch (e) {
      if (_trayGapWarned) return;
      _trayGapWarned = true;
      config.logger('[DesktopShell] $label unavailable on this platform: $e');
    }
  }

  Future<bool?> _tolerateBool(String label, Future<bool> Function() op) async {
    try {
      return await op();
    } catch (e) {
      config.logger('[DesktopShell] $label failed: $e');
      return null;
    }
  }
}
