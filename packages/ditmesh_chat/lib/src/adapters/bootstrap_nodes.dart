import '../logging/chat_logger.dart';
import 'bootstrap_adapter.dart';
import 'key_value_store.dart';

/// Supplies DHT entry points for a fresh automatic session. A configured
/// manual session uses only its selected node, including an empty selection.
class BootstrapNodes {
  BootstrapNodes(this._store, {ChatLogger logger = const SilentChatLogger()})
    : _logger = logger;

  final KeyValueStore _store;
  final ChatLogger _logger;

  // Verified against https://nodes.tox.chat/json on 2026-10-08. Refresh from
  // that official list before releases. These nodes advertise both UDP and
  // TCP; native tryBootstrapNode also configures relays on 443 and 3389.
  // Numeric addresses avoid blocking hostname resolution during auto startup.
  static const seeds = <({String host, int port, String publicKey})>[
    (
      host: '144.217.167.73',
      port: 33445,
      publicKey:
          '7E5668E0EE09E19F320AD47902419331FFEE147BB3606769CFBE921A2A2FD34C',
    ),
    (
      host: '144.172.88.203',
      port: 33445,
      publicKey:
          '2016A0F2797EE3A8B004BA623F11AAFC8146F1B8F45107232A1A1AECCE856674',
    ),
    (
      host: '119.59.101.63',
      port: 33445,
      publicKey:
          '197F746696062FA3BD07BB3BC0656ABD6692B4DAA27DACF0F474754F2B09B060',
    ),
    (
      host: '172.104.215.182',
      port: 33445,
      publicKey:
          'DA2BD927E01CD05EBCC2574EBE5BEBB10FF59AE0B2105A7D1E2B40E49BB20239',
    ),
  ];

  bool get _automatic {
    final mode = _store.getString('bootstrap_node_mode');
    return mode == null || mode == 'auto';
  }

  /// Called before native init so its existing preferences/bootstrap adapter
  /// can apply a selected node immediately. Saves public network metadata only.
  Future<void> ensureConfigured() async {
    if (!_automatic) return;
    final selected = Tim2ToxBootstrapAdapter(_store);
    final host = await selected.getBootstrapHost();
    final key = await selected.getBootstrapPublicKey();
    if (host != null && host.isNotEmpty && key != null && key.isNotEmpty) {
      return;
    }
    final first = seeds.first;
    await selected.setBootstrapNode(
      host: first.host,
      port: first.port,
      publicKey: first.publicKey,
    );
  }

  /// Applies multiple entry points even if a previously selected auto node
  /// went offline. No HTTP request gates startup and no selection is replaced.
  /// Native acceptance queues a bootstrap attempt; it is not proof of online
  /// status. [isCurrent] prevents work reaching a subsequent native session.
  Future<void> applyAutoNodes(
    Future<bool> Function(String host, int port, String publicKey)
    tryBootstrap, {
    bool Function()? isCurrent,
  }) async {
    if (!_automatic) return;
    for (final node in seeds) {
      if (!(isCurrent?.call() ?? true)) return;
      try {
        if (!await tryBootstrap(node.host, node.port, node.publicKey)) {
          _logger.warn(
            '[BootstrapNodes] Node refused: ${node.host}:${node.port}',
          );
        }
      } catch (error) {
        _logger.warn(
          '[BootstrapNodes] Node unavailable: ${node.host}:${node.port}: $error',
        );
      }
    }
  }
}
