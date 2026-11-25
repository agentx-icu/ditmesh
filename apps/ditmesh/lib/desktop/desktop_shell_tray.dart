part of 'desktop_shell_controller.dart';

/// Private tray registration and updates share the controller's lifetime.
extension _DesktopShellTray on DesktopShellController {
  bool _ownsTray(int generation, {bool restoringAfterQuit = false}) =>
      _active &&
      generation == _trayGeneration &&
      (restoringAfterQuit || !_closing);

  Future<void> _initTray({bool restoringAfterQuit = false}) {
    final generation = _trayGeneration;
    final registration = _trayQueue.then(
      (_) => _registerTray(generation, restoringAfterQuit: restoringAfterQuit),
    );
    _trayQueue = registration;
    return registration;
  }

  Future<void> _registerTray(
    int generation, {
    required bool restoringAfterQuit,
  }) async {
    bool current() =>
        _ownsTray(generation, restoringAfterQuit: restoringAfterQuit);
    if (!current() || _trayAvailable) return;
    final icon = TrayIconAssets.forPlatform(config.effectivePlatform);
    if (icon == null) return;
    try {
      if (!await _hasTrayHost() || !current()) return;
      _tray.setEventHandler(this);
      await _tray.setIcon(icon, isTemplate: config.isMacOS);
      if (!current()) {
        _tray.setEventHandler(null);
        await _tolerate('destroy stale tray', _tray.destroy);
        _trayAvailable = false;
        return;
      }
      _trayAvailable = true;
    } catch (e) {
      // A tray-less session (headless Linux, no SNI host) throws on the first
      // call. Disable the tray entirely: close-to-tray then falls back to a
      // real quit so the user can never lose the window.
      _trayAvailable = false;
      _tray.setEventHandler(null);
      config.logger(
        '[DesktopShell] tray unavailable, continuing without it: $e',
      );
      return;
    }
    await _applyTrayState(restoringAfterQuit: restoringAfterQuit);
  }

  Future<bool> _hasTrayHost() async {
    try {
      return await config.trayHostAvailable?.call() ?? true;
    } on Object catch (error) {
      config.logger('[DesktopShell] tray host unavailable: $error');
      return false;
    }
  }

  Future<void> _applyTrayState({bool restoringAfterQuit = false}) async {
    final generation = _trayGeneration;
    bool current() =>
        _ownsTray(generation, restoringAfterQuit: restoringAfterQuit);
    if (!_trayAvailable || !current()) return;
    await _tolerate('setToolTip', () => _tray.setToolTip(trayTooltip));
    if (!current()) return;
    if (config.isMacOS) {
      await _tolerate(
        'setTitle',
        () => _tray.setTitle(_unreadCount > 0 ? trayBadge : ''),
      );
    }
    if (!current()) return;
    try {
      await _tray.setMenu(trayMenu);
    } on Object catch (error) {
      config.logger('[DesktopShell] setMenu failed: $error');
      // AppIndicator on Linux only reopens through its menu; other platforms
      // retain a primary-click callback even when the menu is unavailable.
      if (config.isLinux && current()) {
        _trayAvailable = false;
        if (!_windowVisible) await _tolerate('show window', showWindow);
      }
    }
  }

  /// Tray updates are several async plugin calls; callers fire them without
  /// awaiting, so serialise them to keep an older state from landing last.
  void _enqueueTray(Future<void> Function() op) {
    _trayQueue = _trayQueue.then((_) => op());
  }

  void _watchHiddenTray() {
    if (config.trayHostAvailable != null && !_closing && _active) {
      _trayHostWatch.start();
    }
  }
}
