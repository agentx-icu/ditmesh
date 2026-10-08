/// Minimal string key/value persistence the desktop shell needs.
///
/// Deliberately tiny so the orchestrator can back it with
/// `shared_preferences`, a file, or an in-memory map in tests without the
/// shell ever depending on a storage plugin.
abstract interface class KeyValueStore {
  Future<String?> get(String key);

  Future<void> set(String key, String value);
}
