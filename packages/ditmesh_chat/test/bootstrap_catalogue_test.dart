import 'dart:convert';

import 'package:ditmesh_chat/src/bootstrap/node_catalogue.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _key = '7E5668E0EE09E19F320AD47902419331FFEE147BB3606769CFBE921A2A2FD34C';

void main() {
  test('node descriptors validate host, key and port and display IPv6', () {
    const node = BootstrapNode(
      host: '2001:db8::1',
      port: 33445,
      publicKey: _key,
    );
    expect(node.isValid, isTrue);
    expect(node.endpoint, '[2001:db8::1]:33445');
    for (final host in [
      '',
      'bad host',
      'https://node.example',
      ' node.example',
    ]) {
      expect(
        BootstrapNode(host: host, port: 33445, publicKey: _key).isValid,
        isFalse,
        reason: host,
      );
    }
    expect(
      const BootstrapNode(host: 'localhost', port: 0, publicKey: _key).isValid,
      isFalse,
    );
    expect(
      const BootstrapNode(
        host: 'localhost',
        port: 33445,
        publicKey: 'bad',
      ).isValid,
      isFalse,
    );
  });

  test(
    'catalogue rejects bad rows independently and retains transport metadata',
    () async {
      final catalogue = NodeCatalogue(
        client: MockClient((request) async {
          expect(request.url.toString(), 'https://nodes.tox.chat/json');
          return http.Response(
            jsonEncode({
              'nodes': [
                {
                  'ipv4': 'NONE',
                  'ipv6': '2001:db8::1',
                  'port': 33445,
                  'public_key': _key,
                  'status_udp': false,
                  'status_tcp': true,
                  'tcp_ports': [443, 3389],
                  'location': 'CA',
                  'maintainer': 'test',
                  'last_ping': 100,
                },
                {'ipv4': '192.0.2.1', 'port': -2, 'public_key': _key},
                {'ipv4': '192.0.2.2', 'port': 33445, 'public_key': 'bad'},
                'bad row',
              ],
            }),
            200,
          );
        }),
      );
      final result = await catalogue.fetch();
      expect(result.fromFallback, isFalse);
      expect(result.nodes, hasLength(1));
      expect(result.nodes.single.host, '2001:db8::1');
      expect(result.nodes.single.online, isTrue);
      expect(result.nodes.single.udpOnline, isFalse);
      expect(result.nodes.single.tcpPorts, [443, 3389]);
      expect(
        result.nodes.single.lastPing,
        DateTime.fromMillisecondsSinceEpoch(100000, isUtc: true),
      );
    },
  );

  test(
    'huge optional timestamp never discards a healthy neighbouring row',
    () async {
      final result = await NodeCatalogue(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'nodes': [
                {
                  'ipv4': '192.0.2.1',
                  'port': 33445,
                  'public_key': _key,
                  'last_ping': 9223372036854775807,
                },
                {'ipv4': '192.0.2.2', 'port': 33445, 'public_key': _key},
              ],
            }),
            200,
          ),
        ),
      ).fetch();
      expect(result.fromFallback, isFalse);
      expect(result.nodes.map((node) => node.host), contains('192.0.2.2'));
    },
  );

  test(
    'HTTP failure, invalid JSON and empty catalogue produce explicit numeric fallback',
    () async {
      for (final response in [
        http.Response('failed', 503),
        http.Response('{', 200),
        http.Response('{"nodes":[]}', 200),
      ]) {
        final result = await NodeCatalogue(
          client: MockClient((_) async => response),
        ).fetch();
        expect(result.fromFallback, isTrue);
        expect(result.nodes, hasLength(4));
        expect(result.nodes.every((n) => n.isValid), isTrue);
      }
    },
  );
}
