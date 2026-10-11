import 'package:tim2tox_dart/interfaces/bootstrap_service.dart';

import '../bootstrap/address_family_order.dart';
import 'key_value_store.dart';

/// Tim2Tox [BootstrapService] over a [KeyValueStore].
///
/// Holds the DHT bootstrap node the user (or Tim2Tox's auto mode) last
/// selected. Global, not per identity: bootstrap nodes are network
/// infrastructure, not account state. Same keys as toxee's
/// `BootstrapNodesAdapter` so the two apps behave identically here.
class Tim2ToxBootstrapAdapter implements BootstrapService {
  Tim2ToxBootstrapAdapter(
    this._store, {
    this.resolveHost,
    PreferIpv6 preferIpv6 = deviceIsIpv6Only,
  }) : _preferIpv6 = preferIpv6;

  final KeyValueStore _store;
  final Future<String?> Function(String)? resolveHost;
  final PreferIpv6 _preferIpv6;

  static const _kHost = 'current_bootstrap_host';
  static const _kPort = 'current_bootstrap_port';
  static const _kPubkey = 'current_bootstrap_pubkey';

  @override
  Future<String?> getBootstrapHost() async {
    final saved = _store.getString(_kHost);
    final key = _store.getString(_kPubkey);
    // Tim2Tox submits this one host at native start; take the saved node's
    // address family the device can reach so it does not claim the key.
    final host = saved == null || key == null
        ? saved
        : await preferredSavedHost(_store, saved, key, _preferIpv6);
    if (host == null || resolveHost == null) return host;
    return resolveHost!(host);
  }

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
