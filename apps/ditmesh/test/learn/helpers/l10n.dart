import 'package:flutter/material.dart';
import 'package:ditmesh/l10n/generated/s.dart';

/// English strings: the locale every widget test resolves to by default.
final S en = lookupS(const Locale('en'));

/// A [MaterialApp] wired the way `main.dart` is: delegates and supported
/// locales from `S`, so `context.s` works below [home].
MaterialApp l10nApp({required Widget home, ThemeData? theme, Locale? locale}) =>
    MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: locale,
      theme: theme,
      home: home,
    );
