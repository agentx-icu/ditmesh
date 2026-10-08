import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'app_features.dart';
import 'fake_backend_factory.dart';
import 'real_backend_factory.dart';

/// `--dart-define=DITMESH_FAKE_BACKEND=true` forces the in-memory backend even
/// when the Tox-backed one is available. Handy for UI work without a node.
const bool kForceFakeBackend = bool.fromEnvironment('DITMESH_FAKE_BACKEND');

/// Builds the services the UI depends on. `main.dart` picks an implementation
/// through [resolveBackendFactory]; widget tests construct a
/// [FakeBackendFactory] directly.
abstract class BackendFactory {
  const BackendFactory();

  /// Short human-readable name, surfaced on the Me → About section so it is
  /// obvious when the app is running without a real Tox node.
  String get label;

  /// False before native preparation succeeds. An unavailable production
  /// backend blocks startup and is reported to the user.
  bool get isAvailable;

  /// Asynchronous setup that must finish before the synchronous factory
  /// methods are usable (directories, preferences, native library). The fake
  /// needs nothing; the real backend builds its Tox node here. Idempotent.
  Future<void> prepare() async {}

  /// Optional network configuration capability, available before an identity exists.
  NetworkBootstrapService? createNetworkBootstrapService() => null;

  IdentityService createIdentityService();

  /// The chat façade. Receives the identity service because the real backend
  /// shares one Tox node between the two.
  ChatService createChatService(IdentityService identity);

  /// Release everything [createIdentityService] / [createChatService] built.
  Future<void> disposeServices({
    required IdentityService identity,
    required ChatService chat,
  }) => chat.dispose();
}

/// The fake backend is available only through the explicit development
/// define. Production preparation failures reach the startup error screen.
/// [nativeFactory] lets hermetic tests exercise failed native preparation.
Future<BackendFactory> resolveBackendFactory(
  AppFeatures features, {
  BackendFactory? nativeFactory,
}) async {
  if (kForceFakeBackend) return FakeBackendFactory();
  final real = nativeFactory ?? RealBackendFactory();
  await real.prepare();
  if (real.isAvailable) return real;
  throw StateError('The native Tox backend is unavailable (${real.label})');
}
