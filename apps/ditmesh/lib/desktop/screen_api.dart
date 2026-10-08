import 'dart:ui';

/// Display geometry the shell needs to keep a restored window on screen.
abstract interface class ScreenApi {
  /// Work areas (screen minus taskbar / menu bar / dock) of every connected
  /// display in logical pixels, primary first. Empty when unknown (headless
  /// CI, exotic window managers) — callers then skip clamping.
  Future<List<Rect>> workAreas();
}
