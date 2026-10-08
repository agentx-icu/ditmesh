import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small secret store used for the password verifier.
///
/// Production: [FlutterSecureStore] (Keychain on iOS/macOS, Keystore-backed
/// EncryptedSharedPreferences on Android, libsecret on Linux, DPAPI on
/// Windows). Tests: [MemorySecureStore].
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// [SecureStore] over `flutter_secure_storage` (defaults: Keychain with
/// device-unlocked accessibility on Apple platforms, Keystore-wrapped
/// EncryptedSharedPreferences on Android — the plugin's 10.x+ default).
class FlutterSecureStore implements SecureStore {
  FlutterSecureStore([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // The app ships outside the Mac App Store without a provisioning
            // profile. The legacy Keychain supports that distribution; the data
            // protection Keychain would require Keychain Sharing/provisioning.
            mOptions: MacOsOptions(usesDataProtectionKeychain: false),
          );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// In-memory [SecureStore] for tests.
class MemorySecureStore implements SecureStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
