/// Public node metadata and network settings; no native handle crosses this API.
enum BootstrapMode { auto, manual, lan }

enum BootstrapProbeVerdict {
  reachable,
  unreachable,
  invalid,
  udpUnavailable,
  unavailable;

  /// A local inability to probe says nothing negative about a TCP-capable node.
  bool get permitsSelection =>
      this == reachable || this == udpUnavailable || this == unavailable;
}

class BootstrapNode {
  const BootstrapNode({
    required this.host,
    required this.port,
    required this.publicKey,
    this.alternateHosts = const [],
    this.udpOnline = false,
    this.tcpOnline = false,
    this.tcpPorts = const [],
    this.maintainer,
    this.location,
    this.lastPing,
  });

  final String host;
  final int port;
  final String publicKey;
  final List<String> alternateHosts;
  final bool udpOnline;
  final bool tcpOnline;
  final List<int> tcpPorts;
  final String? maintainer;
  final String? location;
  final DateTime? lastPing;
  bool get online => udpOnline || tcpOnline;
  String get endpoint => host.contains(':') ? '[$host]:$port' : '$host:$port';
  String get id => '$host|$port|${publicKey.toUpperCase()}';
  bool get isValid =>
      port > 0 &&
      port <= 65535 &&
      host.isNotEmpty &&
      host.length <= 255 &&
      host == host.trim() &&
      !host.codeUnits.any((c) => c <= 0x20 || c == 0x7f) &&
      !host.contains(RegExp(r'[/\\?#@\[\]]')) &&
      RegExp(r'^[0-9A-Fa-f]{64}$').hasMatch(publicKey);
  List<String> get hosts => {host, ...alternateHosts}.toList();

  BootstrapNode withHost(String value) => BootstrapNode(
    host: value,
    port: port,
    publicKey: publicKey,
    udpOnline: udpOnline,
    tcpOnline: tcpOnline,
    tcpPorts: tcpPorts,
    maintainer: maintainer,
    location: location,
    lastPing: lastPing,
  );

  @override
  bool operator ==(Object other) => other is BootstrapNode && id == other.id;
  @override
  int get hashCode => id.hashCode;
}

class BootstrapCatalogue {
  const BootstrapCatalogue({required this.nodes, required this.fromFallback});
  final List<BootstrapNode> nodes;
  final bool fromFallback;
}

class BootstrapConfiguration {
  const BootstrapConfiguration({
    this.mode = BootstrapMode.auto,
    this.current,
    this.lanNode,
    this.lanPort = 33445,
    this.supportsLan = false,
  });
  final BootstrapMode mode;
  final BootstrapNode? current;
  final BootstrapNode? lanNode;
  final int lanPort;
  final bool supportsLan;
}

abstract interface class NetworkBootstrapService {
  BootstrapConfiguration get configuration;
  Stream<BootstrapConfiguration> get changes;
  Future<BootstrapCatalogue> loadNodes();
  Future<BootstrapProbeVerdict> probe(BootstrapNode node);
  Future<void> selectNode(BootstrapNode node, {bool requireProbe = false});
  Future<void> setMode(BootstrapMode mode);
  Future<void> startLan(int port);
  Future<void> stopLan();
  Future<void> rebootstrap({
    bool onlyIfDisconnected = false,
    bool Function()? isCurrent,
  });
  Future<void> dispose();
}
