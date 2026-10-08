import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;

import '../l10n/generated/s.dart';
import 'key_value_store.dart';
import 'language_catalog.dart';
import 'locale_resolution.dart';

/// The user's language choice: follow the system, or force one of the
/// locales the app ships (`S.supportedLocales`, i.e. the ARB files).
///
/// Wire it above `MaterialApp`, pass [locale] to `MaterialApp.locale` (null
/// = follow the system) and [resolve] to `localeListResolutionCallback` so
/// the framework, this controller and [effectiveLocale] agree on the same
/// rules (toxee's scheme: script/region aware, the whole preferred-locale
/// list in order, English fallback). Persistence goes
/// through the injected [KeyValueStore] under [storageKey] as a
/// `language[_Script]` tag, so additional ARB files need no preference migration.
class LocaleController extends ChangeNotifier {
  /// Restores the saved choice synchronously from [store]; an unknown or
  /// unsupported saved value falls back to "follow the system".
  ///
  /// [systemLocales] is read live on every [effectiveLocale] call (defaults
  /// to the OS's preferred-locale list), so an OS language change needs no
  /// re-wiring.
  LocaleController(this._store, {List<Locale> Function()? systemLocales})
    : _systemLocales =
          systemLocales ?? (() => PlatformDispatcher.instance.locales),
      _override = _restore(_store.getString(storageKey)) {
    _savedOverride = _override;
  }

  final KeyValueStore _store;
  final List<Locale> Function() _systemLocales;

  /// Key under which the chosen locale is persisted (as a [localeName]).
  static const String storageKey = 'i18n.locale';

  /// Locales with an ARB file; the generated `S` class is the source of truth.
  static List<Locale> get supportedLocales => S.supportedLocales;

  /// The controller `AppScope` created for this app run, for code without a
  /// `BuildContext` (notifications, tray, background). Null in unit tests
  /// that never build the scope; `currentS()` then follows the platform.
  static LocaleController? active;

  Locale? _override;
  Locale? _savedOverride;
  int _revision = 0;
  bool _disposed = false;
  Future<void> _pending = Future<void>.value();
  Object? _saveError;
  StackTrace? _saveStack;

  /// The forced locale, or null to follow the system.
  Locale? get locale => _override;

  bool get followsSystem => _override == null;

  /// What the UI actually renders in right now: the override, or the
  /// system's preferred-locale list resolved against the shipped set.
  Locale get effectiveLocale =>
      _override ?? resolveSystemLocales(_systemLocales(), supportedLocales);

  /// `MaterialApp.localeListResolutionCallback`. Walks the whole preferred
  /// list (see [resolveSystemLocales]) and uses the shipped list the
  /// framework passes in, so it stays correct if a test provides fewer.
  static Locale resolve(List<Locale>? preferred, Iterable<Locale> supported) =>
      resolveSystemLocales(preferred, supported);

  /// Sets (and persists) the locale; null returns to the system default.
  /// A locale outside [supportedLocales] is mapped to the shipped locale for
  /// that language (script/region aware), or ignored when there is none.
  Future<void> setLocale(Locale? value) async {
    if (_disposed) throw StateError('locale controller disposed');
    final resolved = value == null
        ? null
        : supportedLocaleFor(value, supportedLocales);
    if (value != null && resolved == null) return;
    if (resolved == _override) return;
    final revision = ++_revision;
    _override = resolved;
    // Enqueue before notifying: a listener can select another language.
    final save = _pending.then((_) async {
      if (resolved == null) {
        await _store.remove(storageKey);
      } else {
        await _store.setString(storageKey, localeName(resolved));
      }
      _savedOverride = resolved;
    });
    _pending = save.then<void>(
      (_) {
        _saveError = null;
        _saveStack = null;
      },
      onError: (Object error, StackTrace stack) {
        _saveError = error;
        _saveStack = stack;
      },
    );
    notifyListeners();
    try {
      await save;
    } on Object {
      if (!_disposed && revision == _revision) {
        _override = _savedOverride;
        notifyListeners();
      }
      rethrow;
    }
  }

  /// Waits for the language choice before backgrounding or quitting.
  Future<void> flush() async {
    await _pending;
    final error = _saveError;
    if (error != null) Error.throwWithStackTrace(error, _saveStack!);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Canonical, persisted name of a locale: `en`, `zh`, `zh_Hant`.
  static String localeName(Locale locale) => localeTag(locale);

  /// Inverse of [localeName], mapped onto the shipped set; tolerant of
  /// `zh-Hans-CN`, `en_US`, legacy `zh_CN`… Null for empty/unsupported input.
  static Locale? parseLocaleName(String? name) {
    final parsed = parseLocaleTag(name);
    if (parsed == null) return null;
    return supportedLocaleFor(parsed, supportedLocales);
  }

  static Locale? _restore(String? saved) => parseLocaleName(saved);
}

/// Label for a language choice: the ARB string for "follow the system", the
/// language's own native name otherwise (never translated).
String localeDisplayName(S s, Locale? locale) {
  if (locale == null) return s.languageSystemDefault;
  return LanguageCatalog.nativeName(locale);
}
