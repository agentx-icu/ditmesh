import 'dart:ui';

import '../window_api.dart';

/// In-memory [WindowApi]. Records every call in [calls] and lets tests raise
/// window events through [simulateCloseRequested] / [simulateBoundsChanged].
class FakeWindowApi implements WindowApi {
  FakeWindowApi({
    this.bounds = const Rect.fromLTWH(0, 0, 1100, 760),
    this.maximized = false,
  });

  final List<String> calls = [];
  Rect bounds;
  bool maximized;
  bool visible = false;
  bool focused = false;
  bool destroyed = false;
  bool preventClose = false;
  bool initialized = false;
  String? title;
  Size? minimumSize;
  WindowEventHandler? handler;

  @override
  Future<void> ensureInitialized() async {
    initialized = true;
    calls.add('ensureInitialized');
  }

  @override
  Future<void> waitUntilReadyToShow({
    required String title,
    required Size minimumSize,
    required Size size,
  }) async {
    calls.add('waitUntilReadyToShow');
    this.title = title;
    this.minimumSize = minimumSize;
    bounds = Rect.fromLTWH(bounds.left, bounds.top, size.width, size.height);
  }

  @override
  Future<void> setTitle(String title) async {
    calls.add('setTitle');
    this.title = title;
  }

  @override
  Future<void> setMinimumSize(Size size) async {
    calls.add('setMinimumSize');
    minimumSize = size;
  }

  @override
  Future<void> setPreventClose(bool prevent) async {
    calls.add('setPreventClose');
    preventClose = prevent;
  }

  @override
  Future<Rect> getBounds() async {
    calls.add('getBounds');
    return bounds;
  }

  @override
  Future<void> setBounds(Rect bounds) async {
    calls.add('setBounds');
    this.bounds = bounds;
  }

  @override
  Future<bool> isMaximized() async {
    calls.add('isMaximized');
    return maximized;
  }

  @override
  Future<void> maximize() async {
    calls.add('maximize');
    maximized = true;
  }

  @override
  Future<bool> isVisible() async {
    calls.add('isVisible');
    return visible;
  }

  @override
  Future<void> show() async {
    calls.add('show');
    visible = true;
  }

  @override
  Future<void> hide() async {
    calls.add('hide');
    visible = false;
    focused = false;
  }

  @override
  Future<void> focus() async {
    calls.add('focus');
    focused = true;
  }

  @override
  Future<void> destroy() async {
    calls.add('destroy');
    destroyed = true;
    visible = false;
  }

  @override
  void setEventHandler(WindowEventHandler? handler) {
    calls.add('setEventHandler');
    this.handler = handler;
  }

  /// The user clicked the close button while prevent-close is on.
  void simulateCloseRequested() => handler?.onCloseRequested();

  /// The window finished a move / resize with [newBounds].
  void simulateBoundsChanged(Rect newBounds, {bool? maximized}) {
    bounds = newBounds;
    if (maximized != null) this.maximized = maximized;
    handler?.onBoundsChanged();
  }
}
