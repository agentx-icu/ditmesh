import 'dart:async';
import 'dart:convert';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:http/http.dart' as http;
import '../adapters/bootstrap_nodes.dart';

/// The official public catalogue. A bad row never discards healthy neighbours.
class NodeCatalogue {
  NodeCatalogue({
    http.Client? client,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client;
  final http.Client? _client;
  final Duration timeout;
  static final Uri source = Uri.parse('https://nodes.tox.chat/json');
  static List<BootstrapNode> get fallback => BootstrapNodes.seeds
      .map(
        (n) => BootstrapNode(
          host: n.host,
          port: n.port,
          publicKey: n.publicKey,
          udpOnline: true,
          tcpOnline: true,
        ),
      )
      .toList(growable: false);
  Future<BootstrapCatalogue> fetch() async {
    final client = _client ?? http.Client();
    try {
      final response = await client.get(source).timeout(timeout);
      if (response.statusCode != 200) return _fallback();
      final data = jsonDecode(response.body);
      if (data is! Map || data['nodes'] is! List) return _fallback();
      final nodes = <BootstrapNode>[];
      for (final row in data['nodes'] as List) {
        final node = parseNode(row);
        if (node != null) nodes.add(node);
      }
      return nodes.isEmpty
          ? _fallback()
          : BootstrapCatalogue(
              nodes: List.unmodifiable(nodes),
              fromFallback: false,
            );
    } on Object {
      return _fallback();
    } finally {
      if (_client == null) client.close();
    }
  }

  BootstrapCatalogue _fallback() => BootstrapCatalogue(
    nodes: List.unmodifiable(fallback),
    fromFallback: true,
  );
  static BootstrapNode? parseNode(Object? value) {
    if (value is! Map) return null;
    String? host(Object? raw) {
      if (raw is! String) return null;
      final text = raw.trim();
      return text.isEmpty || text == '-' || text.toUpperCase() == 'NONE'
          ? null
          : text;
    }

    final ipv4 = host(value['ipv4']);
    final ipv6 = host(value['ipv6']);
    final preferred = ipv4 ?? ipv6;
    final port = value['port'];
    final key = value['public_key'];
    if (preferred == null || port is! int || key is! String) return null;
    final rawTcp = value['tcp_ports'];
    final tcp = rawTcp is List
        ? rawTcp
              .whereType<int>()
              .where((port) => port > 0 && port <= 65535)
              .toSet()
              .toList()
        : <int>[];
    final ping = value['last_ping'];
    final node = BootstrapNode(
      host: preferred,
      port: port,
      publicKey: key,
      alternateHosts: ipv4 != null && ipv6 != null && ipv4 != ipv6
          ? [ipv6]
          : const [],
      udpOnline: value['status_udp'] == true,
      tcpOnline: value['status_tcp'] == true,
      tcpPorts: List.unmodifiable(tcp),
      maintainer: value['maintainer'] is String
          ? value['maintainer'] as String
          : null,
      location: value['location'] is String
          ? value['location'] as String
          : null,
      lastPing: ping is int && ping > 0 && ping <= 8640000000000
          ? DateTime.fromMillisecondsSinceEpoch(ping * 1000, isUtc: true)
          : null,
    );
    return node.isValid ? node : null;
  }
}
