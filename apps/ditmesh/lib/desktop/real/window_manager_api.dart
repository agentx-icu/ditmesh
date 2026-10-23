import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../window_api.dart';

/// [WindowApi] on `window_manager`.
///
/// The plugin singleton is only touched inside methods, never in the
/// constructor, so constructing this on a mobile build (where the controller
/// never calls it) opens no channel.
class WindowManagerApi implements WindowApi {
  _ListenerAdapter? _listener;

  @override
  Future<void> ensureInitialized() => windowManager.ensureInitialized();

  @override
  Future<void> waitUntilReadyToShow({
    required String title,
    required Size minimumSize,
    required Size size,
  }) => windowManager.waitUntilReadyToShow(
    WindowOptions(title: title, minimumSize: minimumSize, size: size),
  );

  @override
  Future<void> setTitle(String title) => windowManager.setTitle(title);

  @override
  Future<void> setMinimumSize(Size size) => windowManager.setMinimumSize(size);

  @override
  Future<void> setPreventClose(bool prevent) =>
      windowManager.setPreventClose(prevent);

  @override
  Future<Rect> getBounds() => windowManager.getBounds();

  @override
  Future<void> setBounds(Rect bounds) => windowManager.setBounds(bounds);

  @override
  Future<bool> isMaximized() => windowManager.isMaximized();

  @override
  Future<bool> isFullScreen() => windowManager.isFullScreen();

  @override
  Future<bool> isMinimized() => windowManager.isMinimized();

  @override
  Future<void> maximize() => windowManager.maximize();

  @override
  Future<void> restore() => windowManager.restore();

  @override
  Future<bool> isVisible() => windowManager.isVisible();

  @override
  Future<void> show() => windowManager.show();

  @override
  Future<void> hide() => windowManager.hide();

  @override
  Future<void> focus() => windowManager.focus();

  @override
  Future<void> destroy() {
    if (defaultTargetPlatform == TargetPlatform.linux) {
      // Preferences, session saves and cleanup have already completed.
      // window_manager 0.5.x destroys GTK/GL before the engine is finished;
      // Flutter's platform exit preserves GApplication's shutdown ordering.
      return SystemNavigator.pop();
    }
    return windowManager.destroy();
  }

  @override
  void setEventHandler(WindowEventHandler? handler) {
    final old = _listener;
    if (old != null) {
      windowManager.removeListener(old);
      _listener = null;
    }
    if (handler == null) return;
    final next = _ListenerAdapter(handler);
    _listener = next;
    windowManager.addListener(next);
  }
}

class _ListenerAdapter with WindowListener {
  _ListenerAdapter(this.handler);

  final WindowEventHandler handler;

  @override
  void onWindowClose() => handler.onCloseRequested();

  // The plugin also emits the continuous `onWindowResize` / `onWindowMove`
  // streams; the *ed variants fire once per gesture, which is all the
  // debounced persistence needs.
  @override
  void onWindowResized() => handler.onBoundsChanged();

  @override
  void onWindowMoved() => handler.onBoundsChanged();

  @override
  void onWindowMaximize() => handler.onBoundsChanged();

  @override
  void onWindowUnmaximize() => handler.onBoundsChanged();
}
