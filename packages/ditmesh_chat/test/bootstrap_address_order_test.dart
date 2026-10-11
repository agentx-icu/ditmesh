import 'dart:io';

import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/bootstrap_nodes.dart';
import 'package:ditmesh_chat/src/bootstrap/address_family_order.dart';
import 'package:ditmesh_chat/src/bootstrap/host_resolver.dart';
import 'package:ditmesh_chat/src/bootstrap/tim2tox_bootstrap_runtime.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import 'helpers/fakes.dart';

const _dualKey =
    '2016A0F2797EE3A8B004BA623F11AAFC8146F1B8F45107232A1A1AECCE856674';

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

InternetAddress _ip(String text) => InternetAddress(text);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('preferIpv6For', () {
    test('only a device with IPv6 and no IPv4 path prefers IPv6', () {
      expect(preferIpv6For([_ip('2001:db8::5')]), isTrue);
      expect(preferIpv6For([_ip('2001:db8::5'), _ip('10.0.0.2')]), isFalse);
      expect(preferIpv6For([_ip('10.0.0.2')]), isFalse);
      expect(preferIpv6For(const []), isFalse);
    });

    test('loopback and link-local addresses do not count', () {
      expect(
        preferIpv6For([
          _ip('2001:db8::5'),
          _ip('127.0.0.1'),
          _ip('169.254.10.20'),
        ]),
        isTrue,
      );
      expect(
        preferIpv6For([_ip('fe80::1'), _ip('::1'), _ip('10.0.0.2')]),
        isFalse,
      );
      expect(preferIpv6For([_ip('fe80::1')]), isFalse);
    });

    test('an Android CLAT IPv4 address keeps IPv4 literals first', () {
      expect(preferIpv6For([_ip('2001:db8::5'), _ip('192.0.0.4')]), isFalse);
    });

    test('an interface listing failure keeps the IPv4-first order', () async {
      expect(
        await deviceIsIpv6Only(
          interfaces: () async => throw const SocketException('denied'),
        ),
        isFalse,
      );
    });
  });

  test('ordering is stable, de-duplicated and keeps every address', () {
    const mixed = ['1.2.3.4', '2001:db8::1', '5.6.7.8', '2001:db8::1'];
    expect(orderAddressesByFamily(mixed, preferIpv6: false), [
      '1.2.3.4',
      '5.6.7.8',
      '2001:db8::1',
    ]);
    expect(orderAddressesByFamily(mixed, preferIpv6: true), [
      '2001:db8::1',
      '1.2.3.4',
      '5.6.7.8',
    ]);
  });

  test('bundled seeds go IPv4 first on dual-stack or IPv4 networks', () async {
    final nodes = BootstrapNodes(
      MemoryKeyValueStore(),
      preferIpv6: () async => false,
    );
    final calls = <(String, int, String)>[];
    await nodes.applyAutoNodes((host, port, key) async {
      calls.add((host, port, key));
      return true;
    });
    expect(calls, const [
      (
        '144.217.167.73',
        33445,
        '7E5668E0EE09E19F320AD47902419331FFEE147BB3606769CFBE921A2A2FD34C',
      ),
      ('144.172.88.203', 33445, _dualKey),
      ('2602:fa59:16:111::1', 33445, _dualKey),
      (
        '119.59.101.63',
        33445,
        '197F746696062FA3BD07BB3BC0656ABD6692B4DAA27DACF0F474754F2B09B060',
      ),
      (
        '172.104.215.182',
        33445,
        'DA2BD927E01CD05EBCC2574EBE5BEBB10FF59AE0B2105A7D1E2B40E49BB20239',
      ),
      (
        '2600:3c03::f03c:93ff:fe7f:6096',
        33445,
        'DA2BD927E01CD05EBCC2574EBE5BEBB10FF59AE0B2105A7D1E2B40E49BB20239',
      ),
    ]);
  });

  test('an IPv6-only device registers each seed IPv6 before its IPv4', () async {
    var asked = 0;
    final nodes = BootstrapNodes(
      MemoryKeyValueStore(),
      preferIpv6: () async {
        asked++;
        return true;
      },
    );
    final calls = <(String, int, String)>[];
    await nodes.applyAutoNodes((host, port, key) async {
      calls.add((host, port, key));
      return true;
    });
    expect(asked, 1);
    expect(calls.map((call) => call.$1), const [
      '144.217.167.73',
      '2602:fa59:16:111::1',
      '144.172.88.203',
      '119.59.101.63',
      '2600:3c03::f03c:93ff:fe7f:6096',
      '172.104.215.182',
    ]);
    // The first address native sees for each key is the reachable one.
    final first = <String, String>{};
    for (final (host, _, key) in calls) {
      first.putIfAbsent(key, () => host);
    }
    expect(first[_dualKey], '2602:fa59:16:111::1');
    expect(
      first['DA2BD927E01CD05EBCC2574EBE5BEBB10FF59AE0B2105A7D1E2B40E49BB20239'],
      '2600:3c03::f03c:93ff:fe7f:6096',
    );
  });

  test('a failing preference probe keeps seeds IPv4 first', () async {
    final nodes = BootstrapNodes(
      MemoryKeyValueStore(),
      preferIpv6: () async => throw const SocketException('no interfaces'),
    );
    final hosts = <String>[];
    await nodes.applyAutoNodes((host, port, key) async {
      hosts.add(host);
      return true;
    });
    expect(hosts, const [
      '144.217.167.73',
      '144.172.88.203',
      '2602:fa59:16:111::1',
      '119.59.101.63',
      '172.104.215.182',
      '2600:3c03::f03c:93ff:fe7f:6096',
    ]);
  });

  group('runtime apply', () {
    late Directory root;
    late _RecordingService session;
    setUp(() async {
      root = await Directory.systemTemp.createTemp('ditmesh_order_');
      session = _RecordingService(root);
    });
    tearDown(() => root.delete(recursive: true));

    Tim2ToxBootstrapRuntime runtime({required bool preferIpv6}) =>
        Tim2ToxBootstrapRuntime(
          session: () => session,
          profileRoot: root.path,
          preferIpv6: () async => preferIpv6,
          resolver: BootstrapHostResolver(
            lookup: (host) async => [
              InternetAddress('2001:db8::7'),
              InternetAddress('198.51.100.7'),
            ],
          ),
        );

    const catalogueNode = BootstrapNode(
      host: '144.172.88.203',
      alternateHosts: ['2602:fa59:16:111::1'],
      port: 33445,
      publicKey: _dualKey,
    );

    test(
      'a catalogue node is registered with the reachable family first',
      () async {
        expect(await runtime(preferIpv6: true).apply(catalogueNode), isTrue);
        expect(session.calls, const [
          ('2602:fa59:16:111::1', 33445, _dualKey),
          ('144.172.88.203', 33445, _dualKey),
        ]);
        session.calls.clear();
        expect(await runtime(preferIpv6: false).apply(catalogueNode), isTrue);
        expect(session.calls, const [
          ('144.172.88.203', 33445, _dualKey),
          ('2602:fa59:16:111::1', 33445, _dualKey),
        ]);
      },
    );

    test('a failing preference probe keeps a node IPv4 first', () async {
      final failing = Tim2ToxBootstrapRuntime(
        session: () => session,
        profileRoot: root.path,
        preferIpv6: () async => throw StateError('probe failed'),
      );
      expect(await failing.apply(catalogueNode), isTrue);
      expect(session.calls, const [
        ('144.172.88.203', 33445, _dualKey),
        ('2602:fa59:16:111::1', 33445, _dualKey),
      ]);
    });

    test('a hostname resolving to both families is ordered too', () async {
      const named = BootstrapNode(
        host: 'node.example',
        port: 443,
        publicKey: _dualKey,
      );
      await runtime(preferIpv6: false).apply(named);
      expect(session.calls.map((call) => call.$1), [
        '198.51.100.7',
        '2001:db8::7',
      ]);
      session.calls.clear();
      await runtime(preferIpv6: true).apply(named);
      expect(session.calls.map((call) => call.$1), [
        '2001:db8::7',
        '198.51.100.7',
      ]);
    });
  });
}
