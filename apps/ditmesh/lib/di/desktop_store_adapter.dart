import '../desktop/key_value_store.dart' as desktop;
import '../i18n/key_value_store.dart' as i18n;

/// Lets the desktop shell persist window bounds in the same settings file the
/// locale controller uses (`<application support>/settings.json`), so the app
/// has exactly one small key-value file instead of one per feature.
final class DesktopStoreAdapter implements desktop.KeyValueStore {
  const DesktopStoreAdapter(this._inner);

  final i18n.KeyValueStore _inner;

  @override
  Future<String?> get(String key) async => _inner.getString(key);

  @override
  Future<void> set(String key, String value) => _inner.setString(key, value);
}
