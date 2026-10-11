import 'dart:async';
import 'dart:io';

import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/bootstrap_nodes.dart';
import 'package:ditmesh_chat/src/bootstrap/network_bootstrap_service.dart';
import 'package:ditmesh_chat/src/bootstrap/node_catalogue.dart';
import 'package:ditmesh_chat/src/bootstrap/tim2tox_bootstrap_runtime.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import 'helpers/fakes.dart';

/// Records what would reach native tox_bootstrap / tox_add_tcp_relay.
class _RecordingService extends FfiChatService {
  _RecordingService(Directory root)
    : super(historyDirectory: root.path, ffiForTesting: FakeTim2ToxFfi());
  final calls = <(String, int, String)>[];
  @override
  Future<bool> tryBootstrapNode(String host, int port, String key) async {
    calls.add((host, port, key));
    return true;
  }
}

/// Canonical IPv6 address/key pairs from https://nodes.tox.chat/json
/// (2026-10-10), written out rather than derived from the seed table so a
/// wrong edit there fails here.
const _ipv6Seeds = {
  '2602:fa59:16:111::1':
      '2016A0F2797EE3A8B004BA623F11AAFC8146F1B8F45107232A1A1AECCE856674',
  '2600:3c03::f03c:93ff:fe7f:6096':
      'DA2BD927E01CD05EBCC2574EBE5BEBB10FF59AE0B2105A7D1E2B40E49BB20239',
};

/// Every bundled seed as (IPv4, IPv6 alternates, key), in table order.
const _seeds = [
  (
    '144.217.167.73',
    <String>[],
    '7E5668E0EE09E19F320AD47902419331FFEE147BB3606769CFBE921A2A2FD34C',
  ),
  (
    '144.172.88.203',
    ['2602:fa59:16:111::1'],
    '2016A0F2797EE3A8B004BA623F11AAFC8146F1B8F45107232A1A1AECCE856674',
  ),
  (
    '119.59.101.63',
    <String>[],
    '197F746696062FA3BD07BB3BC0656ABD6692B4DAA27DACF0F474754F2B09B060',
  ),
  (
    '172.104.215.182',
    ['2600:3c03::f03c:93ff:fe7f:6096'],
    'DA2BD927E01CD05EBCC2574EBE5BEBB10FF59AE0B2105A7D1E2B40E49BB20239',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bundled seed table is exactly the canonical pairs', () {
    expect([
      for (final seed in BootstrapNodes.seeds)
        (seed.host, seed.alternateHosts, seed.publicKey),
    ], _seeds);
    expect(BootstrapNodes.seeds.map((seed) => seed.port).toSet(), {33445});
    // Two independent operators at least, so one outage is survivable.
    expect(_ipv6Seeds.values.toSet(), hasLength(2));
    for (final host in _ipv6Seeds.keys) {
      expect(InternetAddress.tryParse(host)?.type, InternetAddressType.IPv6);
    }
  });

  test('the offline catalogue keeps IPv6 as valid alternate hosts', () {
    final fallback = NodeCatalogue.fallback;
    expect([
      for (final node in fallback)
        (node.host, node.alternateHosts, node.publicKey),
    ], _seeds);
    for (final node in fallback) {
      expect(node.port, 33445);
      expect(node.isValid, isTrue, reason: node.endpoint);
      for (final alternate in node.alternateHosts) {
        expect(
          BootstrapNode(
            host: alternate,
            port: node.port,
            publicKey: node.publicKey,
          ).isValid,
          isTrue,
          reason: alternate,
        );
      }
    }
  });

  for (final ipv6Only in [false, true]) {
    test('session start hands every seed to native before any catalogue '
        '(${ipv6Only ? 'IPv6-only' : 'IPv4 or dual-stack'} device)', () async {
      final root = await Directory.systemTemp.createTemp('ditmesh_ipv6_');
      final session = _RecordingService(root);
      final runtime = Tim2ToxBootstrapRuntime(
        session: () => session,
        profileRoot: root.path,
        preferIpv6: () async => ipv6Only,
      );
      final catalogue = Completer<BootstrapCatalogue>();
      final service = Tim2ToxNetworkBootstrapService(
        store: MemoryKeyValueStore(),
        runtime: runtime,
        fetchNodes: () => catalogue.future,
      );
      try {
        await service.initialize();
        await service.sessionStarted();
        expect(session.calls, [
          for (final (ipv4, ipv6, key) in _seeds)
            for (final host in ipv6Only ? [...ipv6, ipv4] : [ipv4, ...ipv6])
              (host, 33445, key),
        ]);
      } finally {
        await service.dispose();
        await root.delete(recursive: true);
      }
    });
  }
}
