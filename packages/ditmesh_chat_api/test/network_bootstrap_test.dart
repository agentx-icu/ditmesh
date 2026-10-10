import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:test/test.dart';

const String _key =
    '7E5668E0EE09E19F320AD47902419331FFEE147BB3606769CFBE921A2A2FD34C';

BootstrapNode _node({String host = 'node.example', int port = 33445}) =>
    BootstrapNode(host: host, port: port, publicKey: _key);

void main() {
  group('BootstrapProbeVerdict.permitsSelection', () {
    test('only a negative answer from the node itself blocks selection', () {
      expect(
        {for (final v in BootstrapProbeVerdict.values) v: v.permitsSelection},
        {
          BootstrapProbeVerdict.reachable: true,
          BootstrapProbeVerdict.unreachable: false,
          BootstrapProbeVerdict.invalid: false,
          BootstrapProbeVerdict.udpUnavailable: true,
          BootstrapProbeVerdict.unavailable: true,
        },
      );
    });
  });

  group('BootstrapNode', () {
    test('a well-formed node is valid', () {
      expect(_node().isValid, isTrue);
      expect(_node(host: '2001:db8::1').isValid, isTrue);
      expect(_node(port: 1).isValid, isTrue);
      expect(_node(port: 65535).isValid, isTrue);
    });

    test('ports outside 1..65535 are invalid', () {
      expect(_node(port: 0).isValid, isFalse);
      expect(_node(port: -1).isValid, isFalse);
      expect(_node(port: 65536).isValid, isFalse);
    });

    test(
      'hosts that could smuggle a path, URL or control byte are invalid',
      () {
        for (final host in <String>[
          '',
          ' node.example',
          'node.example ',
          'node example',
          'node\texample',
          'node\u007f',
          'node/x',
          r'node\x',
          'node?x',
          'node#x',
          'user@node',
          '[::1]',
          'a' * 256,
        ]) {
          expect(_node(host: host).isValid, isFalse, reason: 'host "$host"');
        }
        expect(_node(host: 'a' * 255).isValid, isTrue);
      },
    );

    test('the public key must be exactly 64 hex digits, either case', () {
      BootstrapNode keyed(String k) =>
          BootstrapNode(host: 'h', port: 1, publicKey: k);
      expect(keyed(_key.toLowerCase()).isValid, isTrue);
      expect(keyed(_key.substring(1)).isValid, isFalse);
      expect(keyed('${_key}0').isValid, isFalse);
      expect(keyed('${_key.substring(1)}G').isValid, isFalse);
    });

    test('endpoint brackets IPv6 literals only', () {
      expect(_node().endpoint, 'node.example:33445');
      expect(_node(host: '192.0.2.1').endpoint, '192.0.2.1:33445');
      expect(_node(host: '2001:db8::1').endpoint, '[2001:db8::1]:33445');
    });

    test('identity is host, port and key case-insensitively', () {
      final a = _node();
      final b = BootstrapNode(
        host: 'node.example',
        port: 33445,
        publicKey: _key.toLowerCase(),
        udpOnline: true,
        maintainer: 'someone else',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.id, 'node.example|33445|$_key');
      expect(a, isNot(_node(port: 33446)));
      expect(a, isNot(_node(host: 'other.example')));
      expect({a, b}, hasLength(1));
    });

    test('online when either transport is up', () {
      expect(_node().online, isFalse);
      expect(
        const BootstrapNode(
          host: 'h',
          port: 1,
          publicKey: _key,
          udpOnline: true,
        ).online,
        isTrue,
      );
      expect(
        const BootstrapNode(
          host: 'h',
          port: 1,
          publicKey: _key,
          tcpOnline: true,
        ).online,
        isTrue,
      );
    });

    test('hosts lists the primary first and drops duplicate alternates', () {
      const node = BootstrapNode(
        host: '192.0.2.1',
        port: 1,
        publicKey: _key,
        alternateHosts: ['2001:db8::1', '192.0.2.1', '2001:db8::1'],
      );
      expect(node.hosts, ['192.0.2.1', '2001:db8::1']);
    });

    test('withHost changes the host and keeps the metadata', () {
      final when = DateTime.utc(2026, 10, 1);
      final node = BootstrapNode(
        host: 'node.example',
        port: 33445,
        publicKey: _key,
        alternateHosts: const ['192.0.2.1'],
        udpOnline: true,
        tcpOnline: true,
        tcpPorts: const [443, 3389],
        maintainer: 'm',
        location: 'DE',
        lastPing: when,
      );
      final moved = node.withHost('192.0.2.1');
      expect(moved.host, '192.0.2.1');
      expect(moved.port, 33445);
      expect(moved.publicKey, _key);
      expect(moved.udpOnline, isTrue);
      expect(moved.tcpOnline, isTrue);
      expect(moved.tcpPorts, [443, 3389]);
      expect(moved.maintainer, 'm');
      expect(moved.location, 'DE');
      expect(moved.lastPing, when);
    });
  });

  group('BootstrapConfiguration defaults', () {
    test('automatic mode on the Tox default port, no LAN', () {
      const c = BootstrapConfiguration();
      expect(c.mode, BootstrapMode.auto);
      expect(c.current, isNull);
      expect(c.lanNode, isNull);
      expect(c.lanPort, 33445);
      expect(c.supportsLan, isFalse);
    });
  });

  group('FakeNetworkBootstrapService', () {
    late FakeNetworkBootstrapService service;
    late List<BootstrapConfiguration> seen;

    setUp(() {
      service = FakeNetworkBootstrapService();
      seen = [];
      service.changes.listen(seen.add);
    });
    tearDown(() => service.dispose());

    test('starts in automatic mode and reports LAN support', () {
      expect(service.configuration.mode, BootstrapMode.auto);
      expect(service.configuration.supportsLan, isTrue);
      expect(
        FakeNetworkBootstrapService(
          supportsLan: false,
        ).configuration.supportsLan,
        isFalse,
      );
    });

    test('the bundled catalogue holds one valid online node', () async {
      final cat = await service.loadNodes();
      expect(cat.fromFallback, isFalse);
      expect(cat.nodes, hasLength(1));
      expect(cat.nodes.single.isValid, isTrue);
      expect(cat.nodes.single.online, isTrue);
    });

    test('probe records the node and answers the scripted verdict', () async {
      final node = _node();
      expect(await service.probe(node), BootstrapProbeVerdict.reachable);
      service.verdict = BootstrapProbeVerdict.unreachable;
      expect(await service.probe(node), BootstrapProbeVerdict.unreachable);
      expect(service.probed, [node, node]);
    });

    test('selectNode applies the node and announces it', () async {
      final node = _node();
      await service.selectNode(node);
      expect(service.selected, [node]);
      expect(service.configuration.current, node);
      expect(seen.single.current, node);
    });

    test('a failed selection leaves the configuration alone', () async {
      service.failSelection = true;
      await expectLater(
        service.selectNode(_node()),
        throwsA(
          isA<ChatException>().having(
            (e) => e.code,
            'code',
            'bootstrap_apply_failed',
          ),
        ),
      );
      expect(service.selected, isEmpty);
      expect(service.configuration.current, isNull);
      expect(seen, isEmpty);
    });

    test('setMode keeps the selected node', () async {
      final node = _node();
      await service.selectNode(node);
      await service.setMode(BootstrapMode.manual);
      expect(service.configuration.mode, BootstrapMode.manual);
      expect(service.configuration.current, node);
    });

    test('startLan hosts a node on the port; stopLan clears it', () async {
      await service.startLan(40000);
      final lan = service.configuration;
      expect(lan.mode, BootstrapMode.lan);
      expect(lan.lanPort, 40000);
      expect(lan.lanNode, isNotNull);
      expect(lan.lanNode!.port, 40000);
      expect(lan.lanNode!.isValid, isTrue);
      expect(lan.current, lan.lanNode);

      await service.stopLan();
      expect(service.configuration.lanNode, isNull);
      expect(service.configuration.current, isNull);
      expect(service.configuration.supportsLan, isTrue);
      expect(seen, hasLength(2));
    });

    test('the LAN port survives a mode change or a node selection', () async {
      await service.startLan(40000);
      await service.setMode(BootstrapMode.manual);
      expect(service.configuration.lanPort, 40000);
      await service.selectNode(_node());
      expect(service.configuration.lanPort, 40000);
      await service.stopLan();
      expect(service.configuration.lanPort, 40000);
    });

    test('rebootstrap is a no-op and dispose closes the stream', () async {
      await service.rebootstrap(
        onlyIfDisconnected: true,
        isCurrent: () => true,
      );
      expect(seen, isEmpty);
      await service.dispose();
      await service.setMode(BootstrapMode.manual); // no add after close
      expect(seen, hasLength(0));
    });
  });
}
