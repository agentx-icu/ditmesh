import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/src/bootstrap/lan_addresses.dart';

void main() {
  group('LAN address policy', () {
    const virtualIpv4 = LanAddressCandidate(
      interfaceName: 'docker0',
      address: '192.168.99.1',
      type: InternetAddressType.IPv4,
    );
    const wifiIpv4 = LanAddressCandidate(
      interfaceName: 'en0',
      address: '192.168.1.20',
      type: InternetAddressType.IPv4,
    );
    const ethernetIpv4 = LanAddressCandidate(
      interfaceName: 'en1',
      address: '10.0.0.8',
      type: InternetAddressType.IPv4,
    );
    const ulaIpv6 = LanAddressCandidate(
      interfaceName: 'en0',
      address: 'fd00::20',
      type: InternetAddressType.IPv6,
    );

    test('filters virtual interfaces and is stable across input order', () {
      final forward = LanAddresses.selectPreferredAddress([
        virtualIpv4,
        ethernetIpv4,
        wifiIpv4,
      ]);
      final reverse = LanAddresses.selectPreferredAddress(
        [wifiIpv4, ethernetIpv4, virtualIpv4].reversed,
      );

      expect(forward, '192.168.1.20');
      expect(reverse, forward);
    });

    test('prefers physical IPv4 before IPv6', () {
      expect(
        LanAddresses.selectPreferredAddress([ulaIpv6, wifiIpv4]),
        wifiIpv4.address,
      );
    });

    test('falls back to ULA then global IPv6', () {
      const global = LanAddressCandidate(
        interfaceName: 'en1',
        address: '2001:4860::20',
        type: InternetAddressType.IPv6,
      );

      expect(
        LanAddresses.selectPreferredAddress([global, ulaIpv6]),
        ulaIpv6.address,
      );
      expect(LanAddresses.selectPreferredAddress([global]), global.address);
    });

    test('excludes loopback and IPv6 link-local addresses', () {
      const loopback = LanAddressCandidate(
        interfaceName: 'lo0',
        address: '::1',
        type: InternetAddressType.IPv6,
        isLoopback: true,
      );
      const linkLocal = LanAddressCandidate(
        interfaceName: 'en0',
        address: 'fe80::1',
        type: InternetAddressType.IPv6,
      );

      expect(
        LanAddresses.selectPreferredAddress([loopback, linkLocal]),
        isNull,
      );
    });

    test('uses APIPA only as the final fallback', () {
      const apipa = LanAddressCandidate(
        interfaceName: 'en0',
        address: '169.254.10.20',
        type: InternetAddressType.IPv4,
      );

      expect(
        LanAddresses.selectPreferredAddress([apipa, ulaIpv6]),
        ulaIpv6.address,
      );
      expect(LanAddresses.selectPreferredAddress([apipa]), apipa.address);
    });

    // VPN-only endpoints are excluded from local node advertisements.
    test('filters a Tailscale/VPN CGNAT address in favour of a real LAN', () {
      const tailscale = LanAddressCandidate(
        interfaceName: 'utun3',
        address: '100.101.102.103',
        type: InternetAddressType.IPv4,
      );

      // A real LAN address is chosen over the VPN endpoint...
      expect(
        LanAddresses.selectPreferredAddress([tailscale, wifiIpv4]),
        wifiIpv4.address,
      );
      // A VPN-only host has no advertised local address.
      expect(LanAddresses.selectPreferredAddress([tailscale]), isNull);
    });
  });
}
