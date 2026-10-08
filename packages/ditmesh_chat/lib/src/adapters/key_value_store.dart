import 'package:shared_preferences/shared_preferences.dart';

/// Minimal key/value persistence the adapters are written against.
///
/// Production uses [SharedPreferencesStore]; tests use [MemoryKeyValueStore].
/// Keeping the surface this small is what lets the preferences adapter be
/// unit-tested without the Flutter plugin channel.
abstract interface class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  bool? getBool(String key);
  Future<void> setBool(String key, bool value);
  int? getInt(String key);
  Future<void> setInt(String key, int value);
  List<String>? getStringList(String key);
  Future<void> setStringList(String key, List<String> value);
  Future<void> remove(String key);
  Set<String> keys();
}

/// [KeyValueStore] over `shared_preferences`.
class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<SharedPreferencesStore> open() async =>
      SharedPreferencesStore(await SharedPreferences.getInstance());

  Future<void> _persist(Future<bool> operation) async {
    try {
      if (!await operation) throw StateError('Could not persist preferences');
    } catch (_) {
      // The plugin updates its cache before the platform write completes.
      // Reload so a failed write cannot masquerade as durable application data.
      try {
        await _prefs.reload();
      } catch (_) {
        // Preserve the write error when the platform also refuses the reload.
      }
      rethrow;
    }
  }

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _persist(_prefs.setString(key, value));

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, bool value) =>
      _persist(_prefs.setBool(key, value));

  @override
  int? getInt(String key) => _prefs.getInt(key);

  @override
  Future<void> setInt(String key, int value) =>
      _persist(_prefs.setInt(key, value));

  @override
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  @override
  Future<void> setStringList(String key, List<String> value) =>
      _persist(_prefs.setStringList(key, value));

  @override
  Future<void> remove(String key) => _persist(_prefs.remove(key));

  @override
  Set<String> keys() => _prefs.getKeys();
}

/// In-memory [KeyValueStore] for tests.
class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, Object> _data = <String, Object>{};

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  Future<void> setString(String key, String value) async => _data[key] = value;

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => _data[key] = value;

  @override
  int? getInt(String key) => _data[key] as int?;

  @override
  Future<void> setInt(String key, int value) async => _data[key] = value;

  @override
  List<String>? getStringList(String key) =>
      (_data[key] as List<String>?)?.toList();

  @override
  Future<void> setStringList(String key, List<String> value) async =>
      _data[key] = List<String>.of(value);

  @override
  Future<void> remove(String key) async => _data.remove(key);

  @override
  Set<String> keys() => _data.keys.toSet();
}

/// A host write barrier: reads retain the backing store's immediate cache
/// semantics, while replacement waits for every already-submitted write.
class PendingKeyValueStore implements KeyValueStore {
  PendingKeyValueStore(this._store);

  final KeyValueStore _store;
  final Set<Future<void>> _pending = {};

  Future<void> _track(Future<void> operation) {
    late final Future<void> settled;
    settled = operation.then<void>(
      (_) => _pending.remove(settled),
      onError: (Object _, StackTrace _) => _pending.remove(settled),
    );
    _pending.add(settled);
    return operation;
  }

  Future<void> flush() async {
    while (_pending.isNotEmpty) {
      await Future.wait(_pending.toList());
    }
  }

  @override
  String? getString(String key) => _store.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _track(_store.setString(key, value));

  @override
  bool? getBool(String key) => _store.getBool(key);

  @override
  Future<void> setBool(String key, bool value) =>
      _track(_store.setBool(key, value));

  @override
  int? getInt(String key) => _store.getInt(key);

  @override
  Future<void> setInt(String key, int value) =>
      _track(_store.setInt(key, value));

  @override
  List<String>? getStringList(String key) => _store.getStringList(key);

  @override
  Future<void> setStringList(String key, List<String> value) =>
      _track(_store.setStringList(key, value));

  @override
  Future<void> remove(String key) => _track(_store.remove(key));

  @override
  Set<String> keys() => _store.keys();
}
