import 'dart:ui';

/// Window events the shell reacts to. Implemented by the controller; the
/// real [WindowApi] translates `window_manager`'s `WindowListener` into it.
abstract interface class WindowEventHandler {
  /// The user asked to close the window (title-bar button, Cmd/Alt+F4, …).
  /// Only fires when `setPreventClose(true)` is active; the handler decides
  /// between hiding to the tray and quitting.
  void onCloseRequested();

  /// The window was moved, resized, maximised or restored.
  void onBoundsChanged();
}

/// The subset of `window_manager` the shell uses, behind an interface so the
/// controller never imports the plugin and tests use a fake.
///
/// Sizes and rectangles are logical pixels.
abstract interface class WindowApi {
  Future<void> ensureInitialized();

  /// Configures the (still hidden) window and waits until it can be shown.
  Future<void> waitUntilReadyToShow({
    required String title,
    required Size minimumSize,
    required Size size,
  });

  Future<void> setTitle(String title);

  Future<void> setMinimumSize(Size size);

  /// When true, a close request is delivered to
  /// [WindowEventHandler.onCloseRequested] instead of closing.
  Future<void> setPreventClose(bool prevent);

  Future<Rect> getBounds();

  Future<void> setBounds(Rect bounds);

  Future<bool> isMaximized();

  Future<void> maximize();

  Future<bool> isVisible();

  Future<void> show();

  Future<void> hide();

  Future<void> focus();

  /// Closes the window for real (bypassing prevent-close). On desktop the
  /// runner terminates after its last window closes, so this exits the app.
  Future<void> destroy();

  /// Installs (or with null removes) the shell's event handler.
  void setEventHandler(WindowEventHandler? handler);
}
