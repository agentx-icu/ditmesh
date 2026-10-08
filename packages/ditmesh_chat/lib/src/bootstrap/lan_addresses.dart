import 'dart:io';

class LanAddressCandidate {
  const LanAddressCandidate({
    required this.interfaceName,
    required this.address,
    required this.type,
    this.isLoopback = false,
  });

  final String interfaceName;
  final String address;
  final InternetAddressType type;
  final bool isLoopback;
}

class LanAddresses {
  static const _virtualInterfacePrefixes = [
    'docker',
    'veth',
    'br-',
    'virbr',
    'vbox',
    'vmnet',
    'tun',
    'tap',
    'utun',
    'wg',
  ];

  static bool _isVirtualInterface(String name) {
    final lower = name.toLowerCase();
    return _virtualInterfacePrefixes.any((p) => lower.startsWith(p));
  }

  static String? selectPreferredAddress(
    Iterable<LanAddressCandidate> candidates,
  ) {
    final usable = <({LanAddressCandidate candidate, int rank})>[];
    final seen = <String>{};
    for (final candidate in candidates) {
      final address = candidate.address.trim();
      if (address.isEmpty ||
          candidate.isLoopback ||
          _isVirtualInterface(candidate.interfaceName)) {
        continue;
      }
      final key = '${candidate.interfaceName}\u0000$address';
      if (!seen.add(key)) continue;
      final rank = _addressRank(candidate.type, address);
      if (rank == null) continue;
      usable.add((
        candidate: LanAddressCandidate(
          interfaceName: candidate.interfaceName,
          address: address,
          type: candidate.type,
        ),
        rank: rank,
      ));
    }
    usable.sort((left, right) {
      final rankOrder = left.rank.compareTo(right.rank);
      if (rankOrder != 0) return rankOrder;
      final interfaceOrder = left.candidate.interfaceName.compareTo(
        right.candidate.interfaceName,
      );
      if (interfaceOrder != 0) return interfaceOrder;
      return left.candidate.address.compareTo(right.candidate.address);
    });
    return usable.isEmpty ? null : usable.first.candidate.address;
  }

  static int? _addressRank(InternetAddressType type, String address) {
    final lower = address.toLowerCase();
    if (type == InternetAddressType.IPv4) {
      if (lower == '127.0.0.1') return null;
      if (lower.startsWith('169.254.')) return 4;
      if (_isPrivateIpv4(lower)) return 0;
      return 1;
    }
    if (lower == '::1' || lower.startsWith('fe80:')) return null;
    if (lower.startsWith('fc') || lower.startsWith('fd')) return 2;
    if (lower.startsWith('2') || lower.startsWith('3')) return 3;
    return null;
  }

  static bool _isPrivateIpv4(String address) {
    if (address.startsWith('10.') || address.startsWith('192.168.')) {
      return true;
    }
    if (!address.startsWith('172.')) return false;
    final parts = address.split('.');
    if (parts.length != 4) return false;
    final second = int.tryParse(parts[1]);
    return second != null && second >= 16 && second <= 31;
  }

  /// Get local LAN IP address. Filters out virtual/container interfaces.
  /// `includeLinkLocal: true` is required for the documented 169.254.x.x
  /// (APIPA) last-resort fallback — `NetworkInterface.list` omits link-local
  /// by default, which would leave the rank-4 branch in [_addressRank] dead.
  /// [selectPreferredAddress] can also fall back to a public/CGNAT IPv4 on a
  /// real interface (rank 1) when no RFC1918/link-local address exists; a LAN
  /// peer won't reach that, but a host running a LAN node normally has a
  /// private address, which always ranks first.
  static Future<String?> getLocalIPAddress() async {
    try {
      final interfaces = await NetworkInterface.list(includeLinkLocal: true);
      final candidates = interfaces.expand(
        (interface) => interface.addresses.map(
          (address) => LanAddressCandidate(
            interfaceName: interface.name,
            address: address.address,
            type: address.type,
            isLoopback: address.isLoopback,
          ),
        ),
      );
      return selectPreferredAddress(candidates);
    } catch (e) {
      return null;
    }
  }
}
