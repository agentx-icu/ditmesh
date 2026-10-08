import 'dart:ui' show Locale;

import 'locale_resolution.dart';

/// Native display names for the language picker.
///
/// A language's own name is not translated (English is "English" in every UI
/// language, 简体中文 stays 简体中文), so this is a Dart table rather than ARB
/// keys. It is pre-populated well beyond what ships today: adding a language
/// is "drop in `app_<tag>.arb`, run `flutter gen-l10n`" — the picker picks it
/// up from `S.supportedLocales` and looks the name up here, falling back to
/// the BCP-47 tag for anything not listed.
abstract final class LanguageCatalog {
  static const Map<String, String> _names = <String, String>{
    'en': 'English',
    'en_GB': 'English (UK)',
    'en_US': 'English (US)',
    'zh': '简体中文',
    'zh_Hans': '简体中文',
    'zh_Hant': '繁體中文',
    'zh_CN': '简体中文',
    'zh_TW': '繁體中文（台灣）',
    'zh_HK': '繁體中文（香港）',
    'ja': '日本語',
    'ko': '한국어',
    'ar': 'العربية',
    'de': 'Deutsch',
    'fr': 'Français',
    'es': 'Español',
    'pt': 'Português',
    'pt_BR': 'Português (Brasil)',
    'it': 'Italiano',
    'nl': 'Nederlands',
    'ru': 'Русский',
    'uk': 'Українська',
    'pl': 'Polski',
    'tr': 'Türkçe',
    'vi': 'Tiếng Việt',
    'th': 'ไทย',
    'id': 'Bahasa Indonesia',
    'hi': 'हिन्दी',
    'sv': 'Svenska',
    'fi': 'Suomi',
    'nb': 'Norsk bokmål',
    'da': 'Dansk',
    'cs': 'Čeština',
    'el': 'Ελληνικά',
    'he': 'עברית',
  };

  /// Native name for [locale]; tries the full tag, then language + script,
  /// then language alone, then returns the tag itself.
  static String nativeName(Locale locale) {
    final tag = localeTag(locale);
    final direct = _names[tag];
    if (direct != null) return direct;
    final script = locale.scriptCode;
    if (script != null) {
      final byScript = _names['${locale.languageCode}_$script'];
      if (byScript != null) return byScript;
    }
    return _names[locale.languageCode] ?? locale.toLanguageTag();
  }

  /// Whether [locale] is written right-to-left (layout direction hint).
  static bool isRtl(Locale locale) =>
      const {'ar', 'he', 'fa', 'ur'}.contains(locale.languageCode);
}
