import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

/// Native/network boundary. The service owns persistence and transactional policy.
abstract interface class BootstrapRuntime {
  bool get supportsLan;
  bool get hasSession;
  bool get isConnected;
  Future<bool> apply(BootstrapNode node, {bool Function()? isCurrent});
  Future<BootstrapProbeVerdict> probe(BootstrapNode node);
  Future<BootstrapNode?> startLan(int port);
  Future<bool> stopLan();
  Future<void> dispose();
}
