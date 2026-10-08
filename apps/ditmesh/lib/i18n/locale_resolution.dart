import 'dart:ui' show Locale;

/// Locale resolution shared by `MaterialApp.localeListResolutionCallback`,
/// the `LocaleController` and the context-free `currentS()` (all through
/// [resolveSystemLocales]).
///
/// Ported from toxee (`lib/util/locale_controller.dart`) and generalised so
/// the supported set is data: whatever ARB files ship (`S.supportedLocales`).
/// Adding a language therefore needs no change here.
///
/// Rules, in order:
/// 1. A language nobody ships → [fallback] (English).
/// 2. Chinese: Traditional when the script is `Hant` **or** the region is
///    TW / HK / MO with no script (Android reports `zh-TW` without a script,
///    iOS reports `zh-Hant-TW`) — if a `zh_Hant` ARB exists; otherwise the
///    Simplified file (`zh_Hans` if shipped, else plain `zh`).
/// 3. Any other language: exact script match if shipped, else language only.
Locale resolveSystemLocale(
  Locale system,
  Iterable<Locale> supported, {
  Locale fallback = const Locale('en'),
}) {
  final candidates = supported
      .where((l) => l.languageCode == system.languageCode)
      .toList(growable: false);
  if (candidates.isEmpty) return fallback;
  if (candidates.length == 1) return candidates.single;

  if (system.languageCode == 'zh') {
    const hantRegions = {'TW', 'HK', 'MO'};
    final wantsHant =
        system.scriptCode == 'Hant' ||
        (system.scriptCode == null && hantRegions.contains(system.countryCode));
    final preferred = wantsHant ? 'Hant' : 'Hans';
    return _withScript(candidates, preferred) ??
        _withScript(candidates, null) ??
        candidates.first;
  }

  return _withScript(candidates, system.scriptCode) ??
      _withScript(candidates, null) ??
      candidates.first;
}

Locale? _withScript(List<Locale> candidates, String? script) {
  for (final locale in candidates) {
    if (locale.scriptCode == script) return locale;
  }
  return null;
}

/// Persisted / radio-button tag for a locale: `en`, `zh`, `zh_Hant`, `pt_BR`.
/// Script wins over region (toxee convention); region only when no script.
String localeTag(Locale locale) {
  final script = locale.scriptCode;
  if (script != null && script.isNotEmpty) {
    return '${locale.languageCode}_$script';
  }
  final country = locale.countryCode;
  if (country != null && country.isNotEmpty) {
    return '${locale.languageCode}_$country';
  }
  return locale.languageCode;
}

/// Inverse of [localeTag]; tolerant of `-` separators, case and BCP-47 input
/// such as `zh-Hans-CN` or `en_US`. Returns null for empty input.
Locale? parseLocaleTag(String? tag) {
  if (tag == null || tag.trim().isEmpty) return null;
  final parts = tag.trim().split(RegExp('[-_]'));
  final language = parts.first.toLowerCase();
  String? script;
  String? country;
  for (final part in parts.skip(1)) {
    if (part.length == 4) {
      script = '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
    } else if (part.length == 2 || part.length == 3) {
      country = part.toUpperCase();
    }
  }
  return Locale.fromSubtags(
    languageCode: language,
    scriptCode: script,
    countryCode: country,
  );
}

/// The shipped locale a user choice maps to, or null when nothing ships that
/// language. Uses the same rules as [resolveSystemLocale] but never falls
/// back to another language (the caller decides what "unsupported" means).
Locale? supportedLocaleFor(Locale candidate, Iterable<Locale> supported) {
  final resolved = resolveSystemLocale(
    candidate,
    supported,
    fallback: const Locale('und'),
  );
  return resolved.languageCode == 'und' ? null : resolved;
}

/// Resolves the OS's whole preferred-locale list (most preferred first)
/// against [supported]: the first preference that maps to a shipped locale
/// (by [supportedLocaleFor]'s script/region rules) wins, so a user who lists
/// `[fr-FR, zh-CN]` gets Chinese rather than English. Only when no entry
/// matches — or the list is null/empty — does [fallback] apply.
///
/// The single entry for `MaterialApp.localeListResolutionCallback`,
/// `LocaleController.effectiveLocale` and `currentLocale()`, so all three
/// agree.
Locale resolveSystemLocales(
  List<Locale>? preferred,
  Iterable<Locale> supported, {
  Locale fallback = const Locale('en'),
}) {
  if (preferred != null) {
    for (final locale in preferred) {
      final match = supportedLocaleFor(locale, supported);
      if (match != null) return match;
    }
  }
  return fallback;
}
