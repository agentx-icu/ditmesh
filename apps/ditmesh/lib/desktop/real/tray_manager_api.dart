import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';

import '../tray_api.dart';

/// [TrayApi] on `tray_manager` (0.5.x, the method-channel lineage that
/// declares linux / macos / windows plugin classes).
///
/// `tray_manager.setIcon` takes a Flutter asset path: on Windows / Linux it
/// resolves `data/flutter_assets/<path>` next to the executable, on macOS it
/// loads the asset through `rootBundle` and ships it base64. So the generated
/// `assets/tray/*` files are used as-is, no temp files.
class TrayManagerApi implements TrayApi {
  _ListenerAdapter? _listener;

  @override
  Future<void> setIcon(String assetPath, {bool isTemplate = false}) =>
      trayManager.setIcon(assetPath, isTemplate: isTemplate);

  @override
  Future<void> setToolTip(String tooltip) => trayManager.setToolTip(tooltip);

  @override
  Future<void> setTitle(String title) => trayManager.setTitle(title);

  @override
  Future<void> setMenu(List<TrayMenuEntry> entries) =>
      trayManager.setContextMenu(Menu(items: entries.map(_toItem).toList()));

  static MenuItem _toItem(TrayMenuEntry entry) {
    if (entry.isSeparator) return MenuItem.separator();
    final checked = entry.checked;
    if (checked != null) {
      return MenuItem.checkbox(
        key: entry.key,
        label: entry.label,
        checked: checked,
      );
    }
    return MenuItem(key: entry.key, label: entry.label);
  }

  @override
  Future<void> destroy() => trayManager.destroy();

  @override
  void setEventHandler(TrayEventHandler? handler) {
    final old = _listener;
    if (old != null) {
      trayManager.removeListener(old);
      _listener = null;
    }
    if (handler == null) return;
    final next = _ListenerAdapter(handler);
    _listener = next;
    trayManager.addListener(next);
  }
}

class _ListenerAdapter with TrayListener {
  _ListenerAdapter(this.handler);

  final TrayEventHandler handler;

  @override
  void onTrayIconMouseDown() => handler.onTrayIconClicked();

  @override
  void onTrayIconRightMouseDown() {
    // macOS and Windows deliver the click and leave the menu to us; the
    // Linux AppIndicator shows the menu natively and never sends this.
    if (defaultTargetPlatform == TargetPlatform.linux) return;
    // Fire-and-forget: the pop-up only returns when the menu closes.
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) =>
      handler.onTrayMenuItem(menuItem.key ?? '');
}
