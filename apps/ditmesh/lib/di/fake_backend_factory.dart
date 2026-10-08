import 'package:flutter/foundation.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';

import 'backend_factory.dart';

/// In-memory services from `package:ditmesh_chat_api/testing.dart`. No Tox
/// node, no disk: every launch starts from [IdentityState.none] unless a
/// pre-seeded [identityService] is passed (widget tests do that).
final class FakeBackendFactory extends BackendFactory {
  FakeBackendFactory({
    FakeIdentityService? identityService,
    NetworkBootstrapService? networkBootstrapService,
    ChatService Function(IdentityService identity)? chatService,
    String label = 'In-memory fake (no network)',
  }) : _identityService = identityService,
       _chatService = chatService,
       _network =
           networkBootstrapService ??
           FakeNetworkBootstrapService(
             supportsLan:
                 defaultTargetPlatform != TargetPlatform.android &&
                 defaultTargetPlatform != TargetPlatform.iOS,
           ),
       _label = label;

  final String _label;
  final NetworkBootstrapService _network;

  final FakeIdentityService? _identityService;
  final ChatService Function(IdentityService identity)? _chatService;

  @override
  String get label => _label;

  @override
  bool get isAvailable => true;

  @override
  NetworkBootstrapService createNetworkBootstrapService() => _network;

  @override
  IdentityService createIdentityService() =>
      _identityService ?? FakeIdentityService();

  @override
  ChatService createChatService(IdentityService identity) =>
      _chatService?.call(identity) ??
      // Follows the identity (first-run creation included) for the own key
      // and the note-to-self conversation.
      FakeChatService(identity: identity);

  @override
  Future<void> disposeServices({
    required IdentityService identity,
    required ChatService chat,
  }) async {
    // Start both teardowns before awaiting either: the identity fake owns a
    // connect timer that must be cancelled synchronously (AppScope.dispose
    // cannot wait for us), and a broadcast close may hand back a root-zone
    // future that FakeAsync never resumes.
    await Future.wait(<Future<void>>[
      chat.dispose(),
      _network.dispose(),
      if (identity is FakeIdentityService) identity.dispose(),
    ]);
  }
}
