import 'dart:io';

/// Orders one bootstrap node's addresses for the device's current network.
///
/// toxcore keeps only the FIRST onion-bootstrap and TCP-relay address it is
/// given per public key (onion_client.c onion_add_bs_path_node,
/// TCP_connection.c add_tcp_relay_global); UDP DHT bootstrap has no such
/// limit. So every address is still handed over, but the family the device
/// can actually reach goes first: IPv6 only when the device has IPv6 and no
/// IPv4 path at all (an IPv4-literal relay is dead there unless NAT64
/// synthesis applies), IPv4 otherwise, which is the order the dual-stack and
/// IPv4-only majority needs.
///
/// Limits outside this package: toxcore restores saved TCP relays and onion
/// path nodes from the profile before these calls (Messenger.c load), and a
/// relay slot registered on an earlier network keeps its key until toxcore
/// drops it, so a previous IPv4 entry can still win for a while.
typedef PreferIpv6 = Future<bool> Function();

/// [preference], with any failure treated as "keep IPv4 first".
Future<bool> resolvePreferIpv6(PreferIpv6 preference) async {
  try {
    return await preference();
  } on Object {
    return false;
  }
}

/// Whether the device has routable IPv6 and no IPv4 path. Loopback and
/// link-local addresses do not count; Android's CLAT `192.0.0.0/29` does,
/// because it carries IPv4 literals. Any failure keeps the IPv4-first order.
Future<bool> deviceIsIpv6Only({
  Future<List<NetworkInterface>> Function()? interfaces,
}) async {
  try {
    final list = await (interfaces ?? NetworkInterface.list)();
    return preferIpv6For([
      for (final interface in list) ...interface.addresses,
    ]);
  } on Object {
    return false;
  }
}

/// The pure decision behind [deviceIsIpv6Only].
bool preferIpv6For(Iterable<InternetAddress> addresses) {
  var ipv4 = false;
  var ipv6 = false;
  for (final address in addresses) {
    if (address.isLoopback || address.isLinkLocal) continue;
    if (address.type == InternetAddressType.IPv4) ipv4 = true;
    if (address.type == InternetAddressType.IPv6) ipv6 = true;
  }
  return ipv6 && !ipv4;
}

/// De-duplicated, stable: the preferred family first, everything else after
/// in its original order.
List<String> orderAddressesByFamily(
  Iterable<String> addresses, {
  required bool preferIpv6,
}) {
  final unique = addresses.toSet().toList();
  bool preferred(String address) =>
      InternetAddress.tryParse(address)?.type ==
      (preferIpv6 ? InternetAddressType.IPv6 : InternetAddressType.IPv4);
  return [...unique.where(preferred), ...unique.where((a) => !preferred(a))];
}
