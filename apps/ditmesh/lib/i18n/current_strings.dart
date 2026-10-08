import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';

import '../l10n/generated/s.dart';
import 'locale_controller.dart';
import 'locale_resolution.dart';

/// App strings in the current UI language for code that has no
/// `BuildContext`: notifications, the desktop tray, lifecycle hints,
/// data-layer fallbacks. Widgets keep using `context.s` / `S.of(context)`.
///
/// Resolved on every call from [LocaleController.active] (or the platform
/// locale when no controller exists yet), so a language switch is picked up
/// by the very next notification without any re-wiring — same contract as
/// toxee's `currentAppL10n()`.
S currentS() => lookupSFor(currentLocale());

/// The locale [currentS] renders in.
Locale currentLocale() {
  final controller = LocaleController.active;
  if (controller != null) return controller.effectiveLocale;
  return resolveSystemLocales(
    PlatformDispatcher.instance.locales,
    S.supportedLocales,
  );
}

/// [lookupS] that survives a persisted locale this build no longer ships:
/// a stale preference must never take down a notification path.
S lookupSFor(Locale locale) {
  try {
    return lookupS(locale);
  } on FlutterError {
    return lookupS(const Locale('en'));
  }
}
