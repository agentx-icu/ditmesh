import 'dart:io';

import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/bootstrap_adapter.dart';
import 'package:ditmesh_chat/src/adapters/bootstrap_nodes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every bundled address, IPv4 and the IPv6 alternates, is one attempt.
final _seedHosts = BootstrapNodes.seeds.fold<int>(
  0,
  (sum, node) => sum + 1 + node.alternateHosts.length,
);

void main() {
  test('bundled nodes use numeric addresses without hostname resolution', () {
    expect(BootstrapNodes.seeds, hasLength(4));
    for (final node in BootstrapNodes.seeds) {
      final address = InternetAddress.tryParse(node.host);
      expect(address, isNotNull, reason: node.host);
      expect(address!.type, InternetAddressType.IPv4);
      for (final alternate in node.alternateHosts) {
        final v6 = InternetAddress.tryParse(alternate);
        expect(v6?.type, InternetAddressType.IPv6, reason: alternate);
      }
      expect(node.publicKey, matches(RegExp(r'^[0-9A-F]{64}$')));
      expect(node.port, inInclusiveRange(1, 65535));
    }
  });

  test(
    'fresh auto session configures a node before native initialization',
    () async {
      final store = MemoryKeyValueStore();
      final nodes = BootstrapNodes(store);
      await nodes.ensureConfigured();
      final adapter = Tim2ToxBootstrapAdapter(store);
      expect(await adapter.getBootstrapHost(), isNotEmpty);
      expect(await adapter.getBootstrapPort(), inInclusiveRange(1, 65535));
      expect(
        await adapter.getBootstrapPublicKey(),
        matches(RegExp(r'^[0-9A-F]{64}$')),
      );
      expect(store.keys(), {
        'current_bootstrap_host',
        'current_bootstrap_port',
        'current_bootstrap_pubkey',
      });
    },
  );

  test(
    'a saved choice stays selected while auto mode gains fallback nodes',
    () async {
      final store = MemoryKeyValueStore();
      final adapter = Tim2ToxBootstrapAdapter(store);
      await adapter.setBootstrapNode(
        host: 'selected.example',
        port: 443,
        publicKey: 'A' * 64,
      );
      final nodes = BootstrapNodes(store);
      await nodes.ensureConfigured();
      final applied = <String>[];
      await nodes.applyAutoNodes((host, port, key) async {
        applied.add(host);
        return true;
      });
      expect(await adapter.getBootstrapHost(), 'selected.example');
      expect(await adapter.getBootstrapPort(), 443);
      expect(await adapter.getBootstrapPublicKey(), 'A' * 64);
      expect(applied, hasLength(_seedHosts));
      expect(applied.toSet(), hasLength(_seedHosts));
      expect(applied.where((host) => host.contains(':')), isNotEmpty);
    },
  );

  test('manual mode without a node remains isolated for local peers', () async {
    final store = MemoryKeyValueStore();
    await store.setString('bootstrap_node_mode', 'manual');
    final nodes = BootstrapNodes(store);
    await nodes.ensureConfigured();
    await nodes.applyAutoNodes(
      (host, port, key) async => fail('manual mode added a public seed'),
    );
    expect(store.keys(), {'bootstrap_node_mode'});
    expect(await Tim2ToxBootstrapAdapter(store).getBootstrapHost(), isNull);
  });

  test('manual selection is retained and no default node is added', () async {
    final store = MemoryKeyValueStore();
    await store.setString('bootstrap_node_mode', 'manual');
    final adapter = Tim2ToxBootstrapAdapter(store);
    await adapter.setBootstrapNode(
      host: '127.0.0.1',
      port: 12345,
      publicKey: 'B' * 64,
    );
    final nodes = BootstrapNodes(store);
    await nodes.ensureConfigured();
    await nodes.applyAutoNodes(
      (host, port, key) async => fail('manual choice was augmented'),
    );
    expect(await adapter.getBootstrapHost(), '127.0.0.1');
    expect(await adapter.getBootstrapPort(), 12345);
  });

  test(
    'one bootstrap refusal or exception does not suppress other seeds',
    () async {
      final logger = MemoryChatLogger();
      final nodes = BootstrapNodes(MemoryKeyValueStore(), logger: logger);
      var calls = 0;
      await nodes.applyAutoNodes((host, port, key) async {
        calls++;
        expect(port, 33445);
        expect(key, matches(RegExp(r'^[0-9A-F]{64}$')));
        if (calls == 1) throw StateError('first node unavailable');
        return calls > 2;
      });
      expect(calls, _seedHosts);
      expect(
        logger.records.where((record) => record.level == ChatLogLevel.warning),
        hasLength(2),
      );
    },
  );

  test(
    'a detached session stops adding nodes to the native singleton',
    () async {
      final nodes = BootstrapNodes(MemoryKeyValueStore());
      var live = true;
      var calls = 0;
      await nodes.applyAutoNodes((host, port, key) async {
        calls++;
        live = false;
        return true;
      }, isCurrent: () => live);
      expect(calls, 1);
    },
  );
}
