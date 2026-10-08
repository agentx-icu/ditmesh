import 'package:tim2tox_dart/interfaces/bootstrap_service.dart';

import 'key_value_store.dart';

/// Tim2Tox [BootstrapService] over a [KeyValueStore].
///
/// Holds the DHT bootstrap node the user (or Tim2Tox's auto mode) last
/// selected. Global, not per identity: bootstrap nodes are network
/// infrastructure, not account state. Same keys as toxee's
/// `BootstrapNodesAdapter` so the two apps behave identically here.
class Tim2ToxBootstrapAdapter implements BootstrapService {
  Tim2ToxBootstrapAdapter(this._store);

  final KeyValueStore _store;

  static const _kHost = 'current_bootstrap_host';
  static const _kPort = 'current_bootstrap_port';
  static const _kPubkey = 'current_bootstrap_pubkey';

  @override
  Future<String?> getBootstrapHost() async => _store.getString(_kHost);

  @override
  Future<int?> getBootstrapPort() async => _store.getInt(_kPort);

  @override
  Future<String?> getBootstrapPublicKey() async => _store.getString(_kPubkey);

  @override
  Future<void> setBootstrapNode({
    required String host,
    required int port,
    required String publicKey,
  }) async {
    await _store.setString(_kHost, host);
    await _store.setInt(_kPort, port);
    await _store.setString(_kPubkey, publicKey);
  }
}
