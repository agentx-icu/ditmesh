import 'dart:typed_data';

import 'package:ditmesh_chat/src/engine/nearby_transport.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tim2tox_dart/service/rendezvous_transport.dart' as native;

import 'helpers/fakes.dart';

void main() {
  test(
    'expired session refuses operations before reaching native bindings',
    () async {
      final inner = native.RendezvousTransport(FakeTim2ToxFfi());
      final transport = Tim2ToxNearbyTransport(inner, isCurrent: () => false);
      expect(transport.join(Uint8List(32), name: 'cell', nick: 'peer'), 0);
      expect(transport.leave('a' * 64), isFalse);
      expect(transport.leaveAll(), 0);
      expect(transport.send('a' * 64, Uint8List(2)), 0);
      expect(transport.peerCount('a' * 64), 0);
      expect(transport.dhtAnnounceCapableCount(), 0);
      await inner.dispose();
    },
  );

  test(
    'maps authenticated packet and membership events to SDK-free records',
    () async {
      final inner = native.RendezvousTransport(FakeTim2ToxFfi());
      final transport = Tim2ToxNearbyTransport(inner, isCurrent: () => true);
      final events = <RendezvousEvent>[];
      final sub = transport.events.listen(events.add);
      final cell = 'a' * 64;
      final peer = 'b' * 64;
      inner.handleLine('rendezvous_joined:$cell:1');
      inner.handleLine('rendezvous_peer:$cell:$peer:join');
      inner.handleLine('rendezvous_packet:$cell:$peer:p:000102');
      await Future<void>.delayed(Duration.zero);
      expect((events[0] as RendezvousJoined).founded, isTrue);
      expect((events[1] as RendezvousPeer).peerPkHex, peer);
      final packet = events[2] as RendezvousPacket;
      expect(packet.chatIdHex, cell);
      expect(packet.isPrivate, isTrue);
      expect(packet.peerPkHex, peer);
      expect(packet.payload, [0, 1, 2]);
      await sub.cancel();
      await inner.dispose();
    },
  );
}
