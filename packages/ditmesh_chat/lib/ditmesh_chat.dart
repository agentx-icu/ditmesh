/// Tim2Tox-backed implementation of `package:ditmesh_chat_api`.
///
/// Entry point: [DitmeshChatBackend.create]. The app depends on the contract
/// package for types and on this package only to construct the backend.
library;

export 'src/adapters/key_value_store.dart'
    show KeyValueStore, MemoryKeyValueStore, SharedPreferencesStore;
export 'src/backend.dart';
export 'src/chat/tim2tox_chat_service.dart' show Tim2ToxChatService;
export 'src/engine/chat_engine.dart' show ChatEngine, EngineSessionConfig, Tim2ToxEngine;
export 'src/identity/backup_container.dart' show BackupContainer;
export 'src/identity/backup_exclusion.dart';
export 'src/identity/identity_paths.dart';
export 'src/identity/password_verifier.dart' show PasswordVerifier;
export 'src/identity/profile_crypto.dart' show ProfileCrypto, Tim2ToxProfileCrypto;
export 'src/identity/secure_store.dart';
export 'src/identity/tim2tox_identity_service.dart';
export 'src/logging/chat_logger.dart';
export 'src/native/native_library.dart';
