import 'dart:io';

import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/bootstrap_adapter.dart';
import 'package:ditmesh_chat/src/adapters/prefs_adapter.dart';
import 'package:ditmesh_chat/src/bootstrap/address_family_order.dart';
import 'package:ditmesh_chat/src/bootstrap/bootstrap_settings.dart';
import 'package:ditmesh_chat/src/bootstrap/network_bootstrap_service.dart';
import 'package:ditmesh_chat/src/bootstrap/tim2tox_bootstrap_runtime.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import 'helpers/fakes.dart';

const _key = '2016A0F2797EE3A8B004BA623F11AAFC8146F1B8F45107232A1A1AECCE856674';
const _ipv4 = '144.172.88.203';
const _ipv6 = '2602:fa59:16:111::1';
const _dualStack = BootstrapNode(
  host: _ipv4,
  alternateHosts: [_ipv6],
  port: 33445,
  publicKey: _key,
);

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('IPv4-mapped IPv6 addresses count as IPv4', () {
    const mixed = ['::ffff:1.2.3.4', '2001:db8::1', '5.6.7.8'];
    expect(orderAddressesByFamily(mixed, preferIpv6: true), [
      '2001:db8::1',
      '::ffff:1.2.3.4',
      '5.6.7.8',
    ]);
    expect(orderAddressesByFamily(mixed, preferIpv6: false), [
      '::ffff:1.2.3.4',
      '5.6.7.8',
      '2001:db8::1',
    ]);
    expect(
      preferIpv6For([
        InternetAddress('2001:db8::5'),
        InternetAddress('::ffff:10.0.0.2'),
      ]),
      isFalse,
    );
  });

  test('a saved node keeps its IPv6 alternate across a restart', () async {
    final store = MemoryKeyValueStore();
    await BootstrapSettings(store).setCurrent(_dualStack);
    final restored = BootstrapSettings(store).current!;
    expect(restored.host, _ipv4);
    expect(restored.alternateHosts, [_ipv6]);
    expect(restored, _dualStack);

    await BootstrapSettings(store).setCurrent(
      const BootstrapNode(host: '1.2.3.4', port: 33445, publicKey: _key),
    );
    expect(BootstrapSettings(store).current!.alternateHosts, isEmpty);
    expect(store.getString('current_bootstrap_alternates'), isNull);

    await BootstrapSettings(store).setCurrent(_dualStack);
    await BootstrapSettings(store).setCurrent(null);
    expect(store.keys(), isEmpty);
  });

  test('alternates saved for another node are ignored', () async {
    final store = MemoryKeyValueStore();
    await BootstrapSettings(store).setCurrent(_dualStack);
    // A writer that only knows host/port/key (Tim2Tox, ensureConfigured).
    await Tim2ToxBootstrapAdapter(
      store,
    ).setBootstrapNode(host: '144.217.167.73', port: 33445, publicKey: _key);
    expect(BootstrapSettings(store).current!.alternateHosts, isEmpty);
    final adapter = Tim2ToxBootstrapAdapter(
      store,
      preferIpv6: () async => true,
    );
    expect(await adapter.getBootstrapHost(), '144.217.167.73');
  });

  for (final ipv6Only in [false, true]) {
    final expected = ipv6Only ? _ipv6 : _ipv4;
    test('native start submits the saved $expected '
        '(${ipv6Only ? 'IPv6-only' : 'IPv4 or dual-stack'} device)', () async {
      final store = MemoryKeyValueStore();
      await BootstrapSettings(store).setCurrent(_dualStack);
      final resolved = <String>[];
      Future<String?> resolve(String host) async {
        resolved.add(host);
        return host;
      }

      final bootstrap = Tim2ToxBootstrapAdapter(
        store,
        resolveHost: resolve,
        preferIpv6: () async => ipv6Only,
      );
      expect(await bootstrap.getBootstrapHost(), expected);
      final prefs = Tim2ToxPreferencesAdapter(
        store,
        accountPrefix: '0123456789ABCDEF',
        resolveBootstrapHost: resolve,
        preferIpv6: () async => ipv6Only,
      );
      expect(await prefs.getCurrentBootstrapNode(), (
        host: expected,
        port: 33445,
        pubkey: _key,
      ));
      expect(resolved, [expected, expected]);
    });

    test('re-bootstrap re-applies the saved node in family order '
        '(${ipv6Only ? 'IPv6-only' : 'IPv4 or dual-stack'} device)', () async {
      final root = await Directory.systemTemp.createTemp('ditmesh_saved_');
      final session = _RecordingService(root);
      final store = MemoryKeyValueStore();
      await store.setString('bootstrap_node_mode', 'manual');
      await BootstrapSettings(store).setCurrent(_dualStack);
      final service = Tim2ToxNetworkBootstrapService(
        store: store,
        runtime: Tim2ToxBootstrapRuntime(
          session: () => session,
          profileRoot: root.path,
          preferIpv6: () async => ipv6Only,
        ),
        fetchNodes: () async => fail('manual mode fetched the catalogue'),
      );
      try {
        await service.initialize();
        await service.rebootstrap();
        expect(
          session.calls,
          ipv6Only
              ? const [(_ipv6, 33445, _key), (_ipv4, 33445, _key)]
              : const [(_ipv4, 33445, _key), (_ipv6, 33445, _key)],
        );
      } finally {
        await service.dispose();
        await root.delete(recursive: true);
      }
    });
  }
}
