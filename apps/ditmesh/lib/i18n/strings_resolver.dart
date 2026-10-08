import 'package:flutter/widgets.dart';

import '../l10n/generated/s.dart';
import 'current_strings.dart';
import 'locale_controller.dart';

/// Listenable view of [currentS] for long-lived services that must react to
/// a language change (rebuild the tray menu, relabel a persistent
/// notification). Fires when the user changes the setting or, while
/// following the system, when the OS locale changes.
///
/// OS changes arrive through [WidgetsBindingObserver.didChangeLocales]
/// rather than by taking over `PlatformDispatcher.onLocaleChanged`, which
/// the binding itself owns: any number of resolvers can coexist and be
/// disposed in any order. Needs the widgets binding (created before
/// `AppScope`).
class StringsResolver extends ChangeNotifier with WidgetsBindingObserver {
  StringsResolver(this._controller) {
    _controller.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
  }

  final LocaleController _controller;
  bool _disposed = false;

  /// Strings in the current UI language (never cached: cheap lookup).
  S get s => lookupSFor(_controller.effectiveLocale);

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (_controller.followsSystem) _changed();
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
