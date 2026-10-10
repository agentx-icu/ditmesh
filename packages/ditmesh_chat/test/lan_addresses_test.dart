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

  group('LAN address edge cases', () {
    LanAddressCandidate v4(String address, {String name = 'en0'}) =>
        LanAddressCandidate(
          interfaceName: name,
          address: address,
          type: InternetAddressType.IPv4,
        );

    test('only 172.16.0.0/12 counts as private in 172/8', () {
      // A private address outranks any other real IPv4 on the host.
      for (final private in ['172.16.0.1', '172.20.5.5', '172.31.255.254']) {
        expect(
          LanAddresses.selectPreferredAddress([
            v4('8.8.4.4', name: 'en0'),
            v4(private, name: 'en9'),
          ]),
          private,
        );
      }
      // Just outside the block, or malformed: an ordinary (rank 1) address,
      // ordered by interface name against another one.
      for (final public in [
        '172.15.0.1',
        '172.32.0.1',
        '172.x.0.1',
        '172.16',
      ]) {
        expect(
          LanAddresses.selectPreferredAddress([
            v4('8.8.4.4', name: 'en1'),
            v4(public, name: 'en0'),
          ]),
          public,
          reason: public,
        );
      }
    });

    test('ties on one interface resolve by address, independent of order', () {
      final a = v4('192.168.1.30');
      final b = v4('192.168.1.4');
      expect(LanAddresses.selectPreferredAddress([a, b]), '192.168.1.30');
      expect(LanAddresses.selectPreferredAddress([b, a]), '192.168.1.30');
    });

    test('blank, padded and repeated addresses', () {
      expect(LanAddresses.selectPreferredAddress([v4('   ')]), isNull);
      expect(
        LanAddresses.selectPreferredAddress([v4(' 10.1.2.3 '), v4('10.1.2.3')]),
        '10.1.2.3',
      );
    });

    test('IPv6 outside ULA and global unicast is never advertised', () {
      for (final address in ['::1', 'FE80::1', 'ff02::1', '64:ff9b::1']) {
        expect(
          LanAddresses.selectPreferredAddress([
            LanAddressCandidate(
              interfaceName: 'en0',
              address: address,
              type: InternetAddressType.IPv6,
            ),
          ]),
          isNull,
          reason: address,
        );
      }
      expect(
        LanAddresses.selectPreferredAddress([
          const LanAddressCandidate(
            interfaceName: 'en0',
            address: 'FD12::1',
            type: InternetAddressType.IPv6,
          ),
        ]),
        'FD12::1',
      );
    });

    test('every listed virtual interface family is skipped', () {
      for (final name in [
        'docker0',
        'veth1a2b',
        'br-123abc',
        'virbr0',
        'vboxnet0',
        'vmnet8',
        'tun0',
        'tap0',
        'utun4',
        'wg0',
        'WG1',
      ]) {
        expect(
          LanAddresses.selectPreferredAddress([v4('10.0.0.2', name: name)]),
          isNull,
          reason: name,
        );
      }
    });

    test(
      'the host lookup answers a usable address or none, never throws',
      () async {
        final address = await LanAddresses.getLocalIPAddress();
        if (address != null) {
          expect(InternetAddress.tryParse(address), isNotNull);
          expect(InternetAddress(address).isLoopback, isFalse);
        }
      },
    );
  });
}
