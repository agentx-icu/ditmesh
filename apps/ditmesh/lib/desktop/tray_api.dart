/// One row of the tray's context menu. Plugin-agnostic so fakes and tests
/// never see `menu_base` types.
class TrayMenuEntry {
  const TrayMenuEntry({required this.key, required this.label, this.checked});

  const TrayMenuEntry.separator() : key = '', label = '', checked = null;

  /// Stable identifier reported back through
  /// [TrayEventHandler.onTrayMenuItem].
  final String key;

  final String label;

  /// Non-null renders a checkbox item.
  final bool? checked;

  bool get isSeparator => key.isEmpty && label.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is TrayMenuEntry &&
      other.key == key &&
      other.label == label &&
      other.checked == checked;

  @override
  int get hashCode => Object.hash(key, label, checked);

  @override
  String toString() => isSeparator
      ? 'TrayMenuEntry.separator'
      : 'TrayMenuEntry($key, "$label", checked: $checked)';
}

/// Tray events the shell reacts to.
abstract interface class TrayEventHandler {
  /// Primary (left) click on the icon. Not delivered by every host: Linux
  /// AppIndicator only offers the menu.
  void onTrayIconClicked();

  /// A context-menu row with [key] (see [TrayMenuEntry.key]) was activated.
  void onTrayMenuItem(String key);
}

/// The subset of `tray_manager` the shell uses.
///
/// Any method may throw on a platform that lacks it (Linux has no tooltip;
/// a tray-less session throws on the first call). The controller treats the
/// tray as cosmetic and tolerates that.
abstract interface class TrayApi {
  /// [assetPath] is a Flutter asset (see `TrayIconAssets`). [isTemplate]
  /// marks a macOS template image.
  Future<void> setIcon(String assetPath, {bool isTemplate = false});

  Future<void> setToolTip(String tooltip);

  /// Text next to the icon; only macOS status items render it.
  Future<void> setTitle(String title);

  Future<void> setMenu(List<TrayMenuEntry> entries);

  Future<void> destroy();

  void setEventHandler(TrayEventHandler? handler);
}
