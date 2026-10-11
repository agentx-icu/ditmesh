import 'dart:io';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';
import '../logging/chat_logger.dart';
import 'address_family_order.dart';
import 'bootstrap_runtime.dart';
import 'host_resolver.dart';
import 'lan_bootstrap_host.dart';
import 'node_probe.dart';

class Tim2ToxBootstrapRuntime implements BootstrapRuntime {
  Tim2ToxBootstrapRuntime({
    required FfiChatService? Function() session,
    required String profileRoot,
    ChatLogger logger = const SilentChatLogger(),
    PreferIpv6 preferIpv6 = deviceIsIpv6Only,
    BootstrapHostResolver? resolver,
  }) : _session = session,
       _preferIpv6 = preferIpv6,
       _resolver = resolver ?? BootstrapHostResolver(),
       _host = LanBootstrapHost(
         profileDirectory: '$profileRoot/lan',
         logger: logger,
       ),
       _probe = NativeNodeProbe(profileRoot: '$profileRoot/probes');
  final FfiChatService? Function() _session;
  final LanBootstrapHost _host;
  final NativeNodeProbe _probe;
  final PreferIpv6 _preferIpv6;
  final BootstrapHostResolver _resolver;
  @override
  bool get supportsLan =>
      Platform.isMacOS || Platform.isLinux || Platform.isWindows;
  @override
  bool get hasSession => _session() != null;
  @override
  bool get isConnected => _session()?.isConnected ?? false;
  @override
  Future<bool> apply(BootstrapNode node, {bool Function()? isCurrent}) async {
    final session = _session();
    if (session == null || !node.isValid) return false;
    bool live() =>
        identical(_session(), session) && (isCurrent?.call() ?? true);
    // Resolve every host first: native keeps only the first onion/TCP-relay
    // address per key, so the order is chosen across the whole node.
    final resolved = <String>[];
    for (final host in node.hosts) {
      if (!live()) return false;
      resolved.addAll(await _resolver.addresses(host));
    }
    if (!live()) return false;
    final addresses = orderAddressesByFamily(
      resolved,
      preferIpv6: await resolvePreferIpv6(_preferIpv6),
    );
    var accepted = false;
    for (final address in addresses) {
      if (!live()) return false;
      accepted =
          await session.tryBootstrapNode(address, node.port, node.publicKey) ||
          accepted;
    }
    return accepted;
  }

  @override
  Future<BootstrapProbeVerdict> probe(BootstrapNode node) => _probe.probe(node);
  @override
  Future<BootstrapNode?> startLan(int port) =>
      supportsLan ? _host.start(port) : Future.value(null);
  @override
  Future<bool> stopLan() => _host.stop();
  @override
  Future<void> dispose() async {
    // Begin both cancellations before waiting for either resource to retire.
    await Future.wait<void>([_host.stop().then((_) {}), _probe.dispose()]);
  }
}
