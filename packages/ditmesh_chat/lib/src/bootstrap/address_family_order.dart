import 'dart:io';

import '../adapters/key_value_store.dart';

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
/// drops it (a never-confirmed slot is killed once its connect fails), so a
/// previous IPv4 entry can still win until then. Tim2Tox's own pre-start
/// submission of the saved node is covered by [preferredSavedHost].
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
    if (_isIpv4(address)) {
      ipv4 = true;
    } else {
      ipv6 = true;
    }
  }
  return ipv6 && !ipv4;
}

/// IPv4, including an IPv4-mapped IPv6 address (`::ffff:a.b.c.d`), which
/// toxcore sends over the IPv4 path and NAT64 synthesis never produces.
bool _isIpv4(InternetAddress address) {
  if (address.type == InternetAddressType.IPv4) return true;
  final raw = address.rawAddress;
  if (raw.length != 16) return false;
  for (var i = 0; i < 10; i++) {
    if (raw[i] != 0) return false;
  }
  return raw[10] == 0xff && raw[11] == 0xff;
}

/// De-duplicated, stable: the preferred family first, everything else after
/// in its original order.
List<String> orderAddressesByFamily(
  Iterable<String> addresses, {
  required bool preferIpv6,
}) {
  final unique = addresses.toSet().toList();
  bool preferred(String text) {
    final address = InternetAddress.tryParse(text);
    return address != null && _isIpv4(address) != preferIpv6;
  }

  return [...unique.where(preferred), ...unique.where((a) => !preferred(a))];
}

/// Store suffix holding a saved node's alternate hosts. The value is bound
/// to the saved host and key (`HOST|KEY|alt,alt`), so a writer that only
/// knows host/port/key (Tim2Tox, older builds) makes it inert, not wrong.
const savedAlternatesSuffix = '_alternates';

String encodeSavedAlternates(
  String host,
  String publicKey,
  List<String> alternates,
) => '$host|${publicKey.toUpperCase()}|${alternates.join(',')}';

/// The alternates saved for exactly this [host] and [publicKey], else none.
List<String> decodeSavedAlternates(String? raw, String host, String publicKey) {
  final parts = raw?.split('|');
  if (parts == null ||
      parts.length != 3 ||
      parts[0] != host ||
      parts[1] != publicKey.toUpperCase() ||
      parts[2].isEmpty) {
    return const [];
  }
  return parts[2]
      .split(',')
      .where((alternate) => alternate.isNotEmpty)
      .toList();
}

/// The saved node's host to submit before the ordered re-application:
/// Tim2Tox submits one saved host at native start, which would otherwise
/// claim the key with IPv4 on an IPv6-only device.
Future<String> preferredSavedHost(
  KeyValueStore store,
  String host,
  String publicKey,
  PreferIpv6 preference, {
  String prefix = 'current_bootstrap',
}) async {
  final alternates = decodeSavedAlternates(
    store.getString('$prefix$savedAlternatesSuffix'),
    host,
    publicKey,
  );
  if (alternates.isEmpty) return host;
  return orderAddressesByFamily([
    host,
    ...alternates,
  ], preferIpv6: await resolvePreferIpv6(preference)).first;
}
