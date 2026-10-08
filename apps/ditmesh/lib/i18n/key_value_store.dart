import 'dart:io';

import '../training/atomic_json_file.dart';

/// Minimal string key/value persistence that [LocaleController] is written
/// against, so the language choice can be stored without the app committing
/// to a preferences plugin. Production wires a real store (a JSON file via
/// [JsonFileKeyValueStore], or an adapter over `shared_preferences`); tests
/// use [InMemoryKeyValueStore].
abstract interface class KeyValueStore {
  /// The stored value for [key], or null when nothing was saved.
  String? getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);
}

/// Map-backed store for tests and for the fake backend.
final class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, String>? initial])
    : _values = {...?initial};

  final Map<String, String> _values;

  /// Snapshot of the current contents (for assertions).
  Map<String, String> get values => Map.unmodifiable(_values);

  @override
  String? getString(String key) => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}

/// Store persisted as one small JSON object (`{"key": "value"}`) in [file].
///
/// The whole file is read once in [open] and rewritten on every change via a
/// temporary file + rename and a previous-save backup. Operations share the
/// file's queue, so rapid preference changes cannot overwrite its staging file.
/// Malformed content falls back to the backup, then an empty store.
final class JsonFileKeyValueStore implements KeyValueStore {
  JsonFileKeyValueStore._(this.file, this._values)
    : _json = AtomicJsonFile(file);

  /// Reads [file] (if it exists) and returns a ready store.
  static Future<JsonFileKeyValueStore> open(File file) async {
    final values = <String, String>{};
    final decoded = await AtomicJsonFile(file).read();
    if (decoded != null) {
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is String) values[entry.key] = value;
      }
    }
    return JsonFileKeyValueStore._(file, values);
  }

  final File file;
  final AtomicJsonFile _json;
  final Map<String, String> _values;
  Future<void> _pending = Future<void>.value();

  @override
  String? getString(String key) => _values[key];

  @override
  Future<void> setString(String key, String value) =>
      _mutate((values) => values[key] = value);

  @override
  Future<void> remove(String key) => _mutate((values) => values.remove(key));

  Future<void> _mutate(void Function(Map<String, String> values) change) {
    final result = _pending.then((_) async {
      final next = Map<String, String>.of(_values);
      change(next);
      await _json.write(next);
      // A failed mutation must not be included in another key's later save.
      _values
        ..clear()
        ..addAll(next);
    });
    _pending = result.then<void>((_) {}, onError: (Object error) {});
    return result;
  }
}
