import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'adapters/key_value_store.dart';
import 'chat/tim2tox_chat_service.dart';
import 'engine/chat_engine.dart';
import 'identity/identity_paths.dart';
import 'identity/password_verifier.dart';
import 'identity/profile_crypto.dart';
import 'identity/secure_store.dart';
import 'identity/tim2tox_identity_service.dart';
import 'logging/chat_logger.dart';
import 'native/native_library.dart';
import 'bootstrap/network_bootstrap_service.dart';
import 'bootstrap/tim2tox_bootstrap_runtime.dart';
import 'package:path/path.dart' as p;

/// Builds the Tim2Tox-backed [IdentityService] + [ChatService] pair that
/// share one engine (one `FfiChatService` per connected session).
///
/// ```dart
/// final backend = await DitmeshChatBackend.create(logger: myLogger);
/// switch (await backend.identity.inspect()) { ... }
/// await backend.identity.connect();
/// backend.chat.conversationChanges.listen(...);
/// ```
///
/// `create()` calls `setNativeLibraryName('tim2tox_ffi')` so the two Tim2Tox
/// paths that still use the Tencent bindings (`quitGroup`, group invites /
/// member lists) load `libtim2tox_ffi`. It does not touch the network: that
/// happens in `identity.connect()`.
class DitmeshChatBackend {
  DitmeshChatBackend._({
    required this.identity,
    required this.chat,
    required this.bootstrap,
    required ChatEngine engine,
    required Tim2ToxIdentityService identityImpl,
  }) : _engine = engine,
       _identityImpl = identityImpl;

  final IdentityService identity;
  final ChatService chat;
  final NetworkBootstrapService bootstrap;
  final ChatEngine _engine;
  final Tim2ToxIdentityService _identityImpl;

  /// Where this identity lives on disk (diagnostics, "reveal in Finder").
  IdentityPaths get paths => _identityImpl.paths;

  /// Production wiring. Every collaborator is injectable so a host (or a
  /// test) can substitute one piece without rebuilding the rest.
  static Future<DitmeshChatBackend> create({
    ChatLogger logger = const SilentChatLogger(),
    IdentityPaths? paths,
    KeyValueStore? store,
    SecureStore? secureStore,
    ProfileCrypto? crypto,
    ChatEngine? engine,
    String? nativeLibraryPathOverride,
    Duration pollInterval = const Duration(seconds: 3),
  }) async {
    NativeLibrarySetup.ensure(libraryPathOverride: nativeLibraryPathOverride);
    // Fail before the first native call so startup can report missing native
    // libraries or an unsupported ABI. An injected test engine needs no library.
    if (engine == null && !NativeLibrarySetup.isNativeLibraryLoadable) {
      throw const ChatException(
        'native_library_missing',
        'libtim2tox_ffi cannot be loaded in this process',
      );
    }
    final resolvedPaths =
        paths ?? await IdentityPaths.forApplicationSupport(logger: logger);
    final kv = store ?? await SharedPreferencesStore.open();
    late Tim2ToxNetworkBootstrapService bootstrap;
    final eng =
        engine ??
        Tim2ToxEngine(
          store: kv,
          logger: logger,
          libraryPathOverride: nativeLibraryPathOverride,
          onBootstrapStart: () => bootstrap.sessionStarted(),
          onBootstrapStop: () => bootstrap.sessionStopped(),
        );
    bootstrap = Tim2ToxNetworkBootstrapService(
      store: kv,
      logger: logger,
      runtime: Tim2ToxBootstrapRuntime(
        session: () => eng.service,
        profileRoot: p.join(p.dirname(resolvedPaths.root), 'network'),
        logger: logger,
      ),
    );
    await bootstrap.initialize();
    final identity = Tim2ToxIdentityService(
      paths: resolvedPaths,
      engine: eng,
      crypto: crypto ?? Tim2ToxProfileCrypto(),
      verifier: PasswordVerifier(secureStore ?? FlutterSecureStore()),
      store: kv,
      logger: logger,
    );
    final chat = Tim2ToxChatService(
      engine: eng,
      identity: identity,
      store: kv,
      logger: logger,
      pollInterval: pollInterval,
    );
    return DitmeshChatBackend._(
      identity: identity,
      chat: chat,
      bootstrap: bootstrap,
      engine: eng,
      identityImpl: identity,
    );
  }

  /// Stops networking (re-encrypting the profile if needed) and releases
  /// every stream. The backend cannot be reused afterwards.
  Future<void> dispose() async {
    await bootstrap.dispose();
    await chat.dispose();
    await identity.disconnect();
    await _identityImpl.dispose();
    await _engine.dispose();
  }
}
