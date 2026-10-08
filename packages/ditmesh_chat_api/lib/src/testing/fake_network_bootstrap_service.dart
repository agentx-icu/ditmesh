import 'dart:async';

import '../models.dart';
import '../network_bootstrap.dart';

/// Explicit in-memory network settings for UI tests and fake-backend scenes.
class FakeNetworkBootstrapService implements NetworkBootstrapService {
  FakeNetworkBootstrapService({bool supportsLan = true})
    : _configuration = BootstrapConfiguration(supportsLan: supportsLan);
  BootstrapConfiguration _configuration;
  final _changes = StreamController<BootstrapConfiguration>.broadcast(
    sync: true,
  );
  final List<BootstrapNode> probed = [];
  final List<BootstrapNode> selected = [];
  BootstrapProbeVerdict verdict = BootstrapProbeVerdict.reachable;
  bool failSelection = false;
  BootstrapCatalogue catalogue = const BootstrapCatalogue(
    nodes: [
      BootstrapNode(
        host: '144.217.167.73',
        port: 33445,
        publicKey:
            '7E5668E0EE09E19F320AD47902419331FFEE147BB3606769CFBE921A2A2FD34C',
        udpOnline: true,
        tcpOnline: true,
        maintainer: 'velusip',
        location: 'CA',
      ),
    ],
    fromFallback: false,
  );
  @override
  BootstrapConfiguration get configuration => _configuration;
  @override
  Stream<BootstrapConfiguration> get changes => _changes.stream;
  void _set(BootstrapConfiguration value) {
    _configuration = value;
    if (!_changes.isClosed) _changes.add(value);
  }

  @override
  Future<BootstrapCatalogue> loadNodes() async => catalogue;
  @override
  Future<BootstrapProbeVerdict> probe(BootstrapNode node) async {
    probed.add(node);
    return verdict;
  }

  @override
  Future<void> selectNode(
    BootstrapNode node, {
    bool requireProbe = false,
  }) async {
    if (failSelection) {
      throw const ChatException(
        'bootstrap_apply_failed',
        'Node application failed',
      );
    }
    selected.add(node);
    _set(
      BootstrapConfiguration(
        mode: _configuration.mode,
        current: node,
        lanNode: _configuration.lanNode,
        supportsLan: _configuration.supportsLan,
      ),
    );
  }

  @override
  Future<void> setMode(BootstrapMode mode) async {
    _set(
      BootstrapConfiguration(
        mode: mode,
        current: _configuration.current,
        supportsLan: _configuration.supportsLan,
        lanNode: _configuration.lanNode,
      ),
    );
  }

  @override
  Future<void> startLan(int port) async {
    final node = BootstrapNode(
      host: '192.168.1.5',
      port: port,
      publicKey:
          '2016A0F2797EE3A8B004BA623F11AAFC8146F1B8F45107232A1A1AECCE856674',
    );
    _set(
      BootstrapConfiguration(
        mode: BootstrapMode.lan,
        current: node,
        lanNode: node,
        lanPort: port,
        supportsLan: _configuration.supportsLan,
      ),
    );
  }

  @override
  Future<void> stopLan() async {
    _set(
      BootstrapConfiguration(
        mode: _configuration.mode,
        supportsLan: _configuration.supportsLan,
      ),
    );
  }

  @override
  Future<void> rebootstrap({
    bool onlyIfDisconnected = false,
    bool Function()? isCurrent,
  }) async {}
  @override
  Future<void> dispose() async {
    if (!_changes.isClosed) await _changes.close();
  }
}
