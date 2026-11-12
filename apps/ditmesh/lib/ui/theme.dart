import 'package:flutter/material.dart';

import 'appearance/style_tokens.dart';
import 'appearance/ui_style.dart';
import 'safe_sides_page_transitions.dart';

/// Dialogs stop at the Material 3 maximum width: an `AlertDialog` sizes to
/// its content, and one with a text field grew across a whole desktop window.
const DialogThemeData kDialogTheme = DialogThemeData(
  constraints: BoxConstraints(minWidth: 280, maxWidth: 560),
);

/// Helpers and errors under a field wrap instead of ending in an ellipsis
/// ("Tox ID must be exactly 76 hex characters" on a 320 px phone, German at
/// large text). Not hints: a wrapping hint grows a one-line field or search
/// bar, so long hints are handled where they are set. Labels scale down
/// (`FieldLabel`), as Material keeps a floating label on one line.
const int kFieldTextMaxLines = 3;

/// App-wide Material 3 themes; Minimal White is the default appearance.
abstract final class DitmeshTheme {
  static ThemeData light({UiStyle style = kDefaultUiStyle}) =>
      _build(Brightness.light, style);

  static ThemeData dark({UiStyle style = kDefaultUiStyle}) =>
      _build(Brightness.dark, style);

  static ThemeData _build(Brightness brightness, UiStyle style) {
    final dark = brightness == Brightness.dark;
    final (canvas, surface, primary, text) = switch ((style, dark)) {
      (UiStyle.white, false) => (
        0xFFFFFFFF,
        0xFFF5F6F8,
        0xFF273343,
        0xFF1D2632,
      ),
      (UiStyle.white, true) => (0xFF151719, 0xFF22252A, 0xFFDDE4EE, 0xFFF2F4F6),
      (UiStyle.classic, false) => (
        0xFFF6EEDD,
        0xFFFFF8E9,
        0xFF80531F,
        0xFF3F2B19,
      ),
      (UiStyle.classic, true) => (
        0xFF241C14,
        0xFF33271B,
        0xFFE7BB75,
        0xFFF8E9CC,
      ),
      (UiStyle.radio, false) => (
        0xFFE7EFFA,
        0xFFF6FAFF,
        0xFF234F92,
        0xFF192C48,
      ),
      (UiStyle.radio, true) => (0xFF0B1628, 0xFF14243B, 0xFF76CFFB, 0xFFE7F3FC),
      (UiStyle.cartoon, false) => (
        0xFFF7F3FF,
        0xFFFFFFFF,
        0xFF5C408F,
        0xFF31224B,
      ),
      (UiStyle.cartoon, true) => (
        0xFF221A33,
        0xFF302445,
        0xFFBFA5FA,
        0xFFF5ECFF,
      ),
    };
    final raisedSurface = style == UiStyle.cartoon
        ? Color(dark ? 0xFF193A37 : 0xFFDEFAF0)
        : Color.lerp(Color(surface), Color(text), 0.045);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: Color(primary),
          brightness: brightness,
        ).copyWith(
          primary: Color(primary),
          onPrimary: dark ? Color(canvas) : Colors.white,
          primaryContainer: Color.lerp(
            Color(surface),
            Color(primary),
            dark ? 0.22 : 0.13,
          ),
          onPrimaryContainer: Color(text),
          surface: Color(canvas),
          onSurface: Color(text),
          onSurfaceVariant: Color.lerp(
            Color(text),
            Color(surface),
            dark
                ? 0.25
                : style == UiStyle.cartoon
                ? 0.19
                : 0.27,
          ),
          surfaceContainerLowest: Color(canvas),
          surfaceContainerLow: Color(surface),
          surfaceContainer: Color(surface),
          surfaceContainerHigh: raisedSurface,
          surfaceContainerHighest: Color.lerp(
            Color(surface),
            Color(text),
            0.09,
          ),
          outline: Color.lerp(Color(surface), Color(text), 0.45),
          outlineVariant: Color.lerp(
            Color(surface),
            Color(text),
            dark ? 0.22 : 0.16,
          ),
        );
    final tokens = _tokens(style, scheme);
    final control = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.controlRadius),
    );
    var theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Color(canvas),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      extensions: [tokens],
      pageTransitionsTheme: kSafeSidesPageTransitions,
      dialogTheme: kDialogTheme,
      cardTheme: CardThemeData(
        color: Color(surface),
        surfaceTintColor: Colors.transparent,
        elevation: style == UiStyle.cartoon ? 1 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.panelRadius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: Color(canvas),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 48),
          shape: control,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 48),
          shape: control,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: control,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(shape: WidgetStatePropertyAll(control)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Color(surface),
        indicatorColor: scheme.primaryContainer,
        indicatorShape: control,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Color(surface),
        indicatorColor: scheme.primaryContainer,
        indicatorShape: control,
        labelType: NavigationRailLabelType.all,
      ),
      inputDecorationTheme: InputDecorationTheme(
        helperMaxLines: kFieldTextMaxLines,
        errorMaxLines: kFieldTextMaxLines,
        filled: true,
        fillColor: Color(surface),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.controlRadius),
        ),
      ),
      dividerColor: scheme.outlineVariant,
    );
    final textTheme = theme.textTheme;
    final heading = style == UiStyle.classic ? 'serif' : null;
    theme = theme.copyWith(
      textTheme: textTheme.copyWith(
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontFamily: heading,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontFamily: heading,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontFamily: heading,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return theme;
  }

  static StyleTokens _tokens(UiStyle style, ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    final (panel, control, bubble, chip) = switch (style) {
      UiStyle.classic => (4.0, 5.0, 6.0, 4.0),
      UiStyle.white => (12.0, 10.0, 14.0, 8.0),
      UiStyle.radio => (8.0, 6.0, 8.0, 6.0),
      UiStyle.cartoon => (24.0, 16.0, 22.0, 12.0),
    };
    final newest = switch (style) {
      UiStyle.classic => scheme.primary,
      UiStyle.radio => const Color(0xFFF1B662),
      UiStyle.cartoon =>
        dark ? const Color(0xFF5D4A29) : const Color(0xFFFFEAA2),
      _ => scheme.primaryContainer,
    };
    return StyleTokens(
      style: style,
      panelRadius: panel,
      controlRadius: control,
      bubbleRadius: bubble,
      chipRadius: chip,
      newest: newest,
      onNewest: style == UiStyle.classic
          ? scheme.onPrimary
          : style == UiStyle.radio
          ? const Color(0xFF302719)
          : scheme.onSurface,
      receiveSurface: style == UiStyle.cartoon
          ? scheme.surfaceContainerHigh
          : scheme.surfaceContainerLow,
      sendSurface: style == UiStyle.cartoon
          ? dark
                ? const Color(0xFF49345C)
                : const Color(0xFFEDE4FF)
          : scheme.surfaceContainerLow,
    );
  }
}
