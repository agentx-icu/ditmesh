import 'package:flutter/foundation.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'backend_factory.dart';

/// Tox-backed services from `packages/ditmesh_chat`.
///
/// This file is the ONLY place in the app that imports `ditmesh_chat`
/// (everything else depends on the `ditmesh_chat_api` contract). Building the
/// backend is asynchronous (application-support directory, shared
/// preferences, native library lookup), so [prepare] runs in `main()` before
/// the widget tree exists; the synchronous factory methods then hand out the
/// services the backend already holds.
final class RealBackendFactory extends BackendFactory {
  RealBackendFactory({ChatLogger? logger})
    : _logger = logger ?? CallbackChatLogger(_debugPrintRecord);

  final ChatLogger _logger;
  DitmeshChatBackend? _backend;

  @override
  String get label => 'Tox (Tim2Tox)';

  @override
  bool get isAvailable => _backend != null;

  @override
  Future<void> prepare() async {
    if (_backend != null) return;
    try {
      _backend = await DitmeshChatBackend.create(logger: _logger);
    } catch (error, stack) {
      _logger.error('Tox backend unavailable', error, stack);
      rethrow;
    }
  }

  DitmeshChatBackend get _ready {
    final backend = _backend;
    if (backend == null) {
      throw StateError(
        'RealBackendFactory.prepare() has not completed successfully',
      );
    }
    return backend;
  }

  @override
  NetworkBootstrapService createNetworkBootstrapService() => _ready.bootstrap;

  @override
  IdentityService createIdentityService() => _ready.identity;

  @override
  ChatService createChatService(IdentityService identity) => _ready.chat;

  @override
  Future<void> disposeServices({
    required IdentityService identity,
    required ChatService chat,
  }) async {
    final backend = _backend;
    _backend = null;
    await backend?.dispose();
  }

  static void _debugPrintRecord(ChatLogRecord record) {
    if (!kDebugMode) return;
    final suffix = record.error == null ? '' : ' — ${record.error}';
    debugPrint('[chat/${record.level.name}] ${record.message}$suffix');
  }
}
