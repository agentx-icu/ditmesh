/// Stable device preference values for the available interface styles.
enum UiStyle {
  white,
  classic,
  radio,
  cartoon;

  /// Accepts styles from current settings and from older saved preferences.
  static UiStyle? fromStoredName(Object? name) {
    for (final style in values) {
      if (style.name == name) return style;
    }
    return switch (name) {
      'paper' => classic,
      'modern' => radio,
      _ => null,
    };
  }
}

/// First-run, invalid-preference and Restore Defaults appearance.
const UiStyle kDefaultUiStyle = UiStyle.white;
