import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import '../adapters/key_value_store.dart';

/// Public network metadata shared by every identity in this installation.
class BootstrapSettings {
  BootstrapSettings(this.store);
  final KeyValueStore store;
  BootstrapMode get mode => BootstrapMode.values.firstWhere(
    (mode) => mode.name == store.getString('bootstrap_node_mode'),
    orElse: () => BootstrapMode.auto,
  );
  BootstrapNode? _read(String prefix) {
    final host = store.getString('${prefix}_host');
    final port = store.getInt('${prefix}_port');
    final key = store.getString('${prefix}_pubkey');
    if (host == null || port == null || key == null) return null;
    final node = BootstrapNode(host: host, port: port, publicKey: key);
    return node.isValid ? node : null;
  }

  BootstrapNode? get current => _read('current_bootstrap');
  BootstrapNode? get preLan => _read('pre_lan_bootstrap');
  bool get lanRunning =>
      store.getBool('lan_bootstrap_service_running') ?? false;
  bool get lanPending =>
      store.getBool('lan_bootstrap_transition_pending') ?? false;
  int get lanPort => store.getInt('lan_bootstrap_port') ?? 33445;
  Future<void> setMode(BootstrapMode mode) =>
      store.setString('bootstrap_node_mode', mode.name);
  Future<void> setPort(int port) => store.setInt('lan_bootstrap_port', port);
  Future<void> _write(String prefix, BootstrapNode? node) async {
    if (node == null) {
      for (final suffix in ['host', 'port', 'pubkey']) {
        await store.remove('${prefix}_$suffix');
      }
    } else {
      await store.setString('${prefix}_host', node.host);
      await store.setInt('${prefix}_port', node.port);
      await store.setString('${prefix}_pubkey', node.publicKey);
    }
  }

  Future<void> setCurrent(BootstrapNode? node) async {
    final prior = current;
    try {
      await _write('current_bootstrap', node);
    } on Object {
      try {
        await _write('current_bootstrap', prior);
      } on Object {
        /* Caller retains recovery state. */
      }
      rethrow;
    }
  }

  Future<void> stageLan() async {
    if (!lanPending && !lanRunning) await _write('pre_lan_bootstrap', current);
    await store.setBool('lan_bootstrap_transition_pending', true);
  }

  Future<void> setLanRunning(bool running) =>
      store.setBool('lan_bootstrap_service_running', running);
  Future<void> clearLanJournal() async {
    await setLanRunning(false);
    await store.remove('lan_bootstrap_transition_pending');
    // A failed flag write leaves the complete snapshot available for retry.
    await _write('pre_lan_bootstrap', null);
  }

  Future<void> recoverLan() async {
    if (!lanRunning && !lanPending) return;
    await setCurrent(preLan);
    await clearLanJournal();
  }
}
