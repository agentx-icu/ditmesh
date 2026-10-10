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

Map<String, String> get _ipv6Seeds => {
  for (final seed in BootstrapNodes.seeds)
    for (final host in seed.alternateHosts) host: seed.publicKey,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('IPv6-only networks get bundled seeds with their own keys', () {
    // Two independent operators at least, so one outage is survivable.
    expect(_ipv6Seeds.length, greaterThanOrEqualTo(2));
    expect(_ipv6Seeds.values.toSet().length, greaterThanOrEqualTo(2));
    for (final host in _ipv6Seeds.keys) {
      final address = InternetAddress.tryParse(host);
      expect(address?.type, InternetAddressType.IPv6, reason: host);
    }
    // Every bundled address is distinct; a key never repeats across seeds.
    final hosts = [
      for (final seed in BootstrapNodes.seeds) ...[
        seed.host,
        ...seed.alternateHosts,
      ],
    ];
    expect(hosts.toSet(), hasLength(hosts.length));
    final keys = BootstrapNodes.seeds.map((seed) => seed.publicKey);
    expect(keys.toSet(), hasLength(BootstrapNodes.seeds.length));
  });

  test('the offline catalogue keeps IPv6 as valid alternate hosts', () {
    final fallback = NodeCatalogue.fallback;
    expect(fallback, hasLength(BootstrapNodes.seeds.length));
    for (final node in fallback) {
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
    final alternates = {
      for (final node in fallback)
        for (final host in node.alternateHosts) host: node.publicKey,
    };
    expect(alternates, _ipv6Seeds);
  });

  test(
    'session start hands every IPv6 seed to native before any catalogue',
    () async {
      final root = await Directory.systemTemp.createTemp('ditmesh_ipv6_');
      final session = _RecordingService(root);
      final runtime = Tim2ToxBootstrapRuntime(
        session: () => session,
        profileRoot: root.path,
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
        final applied = {
          for (final (host, port, key) in session.calls)
            if (host.contains(':')) host: (port, key),
        };
        expect(applied.keys.toSet(), _ipv6Seeds.keys.toSet());
        for (final MapEntry(key: host, value: (port, key)) in applied.entries) {
          expect(port, 33445, reason: host);
          expect(key, _ipv6Seeds[host], reason: host);
        }
        // IPv4 is still tried for the same seeds; nothing was replaced.
        for (final seed in BootstrapNodes.seeds) {
          expect(session.calls.map((call) => call.$1), contains(seed.host));
        }
      } finally {
        await service.dispose();
        await root.delete(recursive: true);
      }
    },
  );
}
