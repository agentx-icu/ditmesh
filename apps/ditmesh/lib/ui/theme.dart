import 'package:flutter/material.dart';

import 'appearance/style_tokens.dart';
import 'appearance/ui_style.dart';
import 'safe_sides_page_transitions.dart';

/// Telegraph-brass amber: the colour of a polished straight key.
const Color kDitmeshSeedColor = Color(0xFFB8860B);

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

/// App-wide Material 3 themes; Modern Calm is the default appearance.
abstract final class DitmeshTheme {
  static ThemeData light({UiStyle style = kDefaultUiStyle}) =>
      _build(Brightness.light, style);

  static ThemeData dark({UiStyle style = kDefaultUiStyle}) =>
      _build(Brightness.dark, style);

  static ThemeData _build(Brightness brightness, UiStyle style) {
    if (style != UiStyle.classic) return _styled(brightness, style);
    final scheme = ColorScheme.fromSeed(
      seedColor: kDitmeshSeedColor,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [_tokens(style, scheme)],
      pageTransitionsTheme: kSafeSidesPageTransitions,
      dialogTheme: kDialogTheme,
      inputDecorationTheme: const InputDecorationThemeData(
        helperMaxLines: kFieldTextMaxLines,
        errorMaxLines: kFieldTextMaxLines,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.primaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        indicatorColor: scheme.primaryContainer,
        labelType: NavigationRailLabelType.all,
      ),
    );
  }

  static ThemeData _styled(Brightness brightness, UiStyle style) {
    final dark = brightness == Brightness.dark;
    final (canvas, surface, primary, text) = switch ((style, dark)) {
      (UiStyle.modern, false) => (
        0xFFF6F9F8,
        0xFFFFFFFF,
        0xFF147D68,
        0xFF17352F,
      ),
      (UiStyle.modern, true) => (
        0xFF12241F,
        0xFF1B3029,
        0xFF88D6BC,
        0xFFE6F3EC,
      ),
      (UiStyle.radio, false) => (
        0xFFEFF4F7,
        0xFFFFFFFF,
        0xFF19695F,
        0xFF172B35,
      ),
      (UiStyle.radio, true) => (0xFF121A22, 0xFF1B2732, 0xFF58D6BE, 0xFFE8EFF3),
      (UiStyle.paper, false) => (
        0xFFF3F0E7,
        0xFFFFFCF5,
        0xFFA74631,
        0xFF302E27,
      ),
      (UiStyle.paper, true) => (0xFF211F1A, 0xFF2D2923, 0xFFE6A184, 0xFFF0E7D6),
      (UiStyle.cartoon, false) => (
        0xFFEDF8F1,
        0xFFFFFDF6,
        0xFF24714D,
        0xFF20473C,
      ),
      (UiStyle.cartoon, true) => (
        0xFF12281F,
        0xFF1D372B,
        0xFF8FD3AB,
        0xFFEAF6ED,
      ),
      _ => throw ArgumentError.value(style),
    };
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
          surfaceContainerHigh: Color.lerp(Color(surface), Color(text), 0.045),
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
    final heading = style == UiStyle.paper ? 'serif' : null;
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
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return theme;
  }

  static StyleTokens _tokens(UiStyle style, ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    final (panel, control, bubble, chip) = switch (style) {
      UiStyle.classic => (12.0, 16.0, 16.0, 8.0),
      UiStyle.modern => (16.0, 10.0, 16.0, 8.0),
      UiStyle.radio => (8.0, 6.0, 8.0, 6.0),
      UiStyle.paper => (3.0, 3.0, 3.0, 3.0),
      UiStyle.cartoon => (22.0, 12.0, 20.0, 12.0),
    };
    final newest = switch (style) {
      UiStyle.classic => scheme.primary,
      UiStyle.radio => const Color(0xFFF1B662),
      UiStyle.cartoon =>
        dark ? const Color(0xFF5B5130) : const Color(0xFFF9E8A3),
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
          ? dark
                ? const Color(0xFF213D49)
                : const Color(0xFFDCEFFA)
          : scheme.surfaceContainerLow,
      sendSurface: style == UiStyle.cartoon
          ? dark
                ? const Color(0xFF49372F)
                : const Color(0xFFF5DCD2)
          : scheme.surfaceContainerLow,
    );
  }
}
