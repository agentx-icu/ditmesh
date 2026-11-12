import 'dart:typed_data';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:tim2tox_dart/service/rendezvous_transport.dart' as native;

/// Adapts one live session without letting native SDK types escape the backend.
final class Tim2ToxNearbyTransport implements NearbyTransport {
  Tim2ToxNearbyTransport(this._inner, {required bool Function() isCurrent})
    : _isCurrent = isCurrent;

  final native.RendezvousTransport _inner;
  final bool Function() _isCurrent;

  @override
  Stream<RendezvousEvent> get events => _inner.events.map(_map);

  static RendezvousEvent _map(native.RendezvousEvent event) => switch (event) {
    native.RendezvousJoined() => RendezvousJoined(
      event.chatIdHex,
      founded: event.founded,
    ),
    native.RendezvousLeft() => RendezvousLeft(
      event.chatIdHex,
      reason: event.reason,
    ),
    native.RendezvousPeer() => RendezvousPeer(
      event.chatIdHex,
      peerPkHex: event.peerPkHex,
      joined: event.joined,
    ),
    native.RendezvousPeersChanged() => RendezvousPeersChanged(
      event.chatIdHex,
      count: event.count,
    ),
    native.RendezvousFull() => RendezvousFull(event.chatIdHex),
    native.RendezvousPacket() => RendezvousPacket(
      event.chatIdHex,
      peerPkHex: event.peerPkHex,
      isPrivate: event.isPrivate,
      payload: event.payload,
    ),
  };

  @override
  int join(Uint8List seed, {required String name, required String nick}) =>
      _isCurrent() ? _inner.join(seed, name: name, nick: nick) : 0;
  @override
  bool leave(String chatIdHex) => _isCurrent() && _inner.leave(chatIdHex);
  @override
  int leaveAll() => _isCurrent() ? _inner.leaveAll() : 0;
  @override
  int send(String chatIdHex, Uint8List payload, {String? peerPkHex}) =>
      _isCurrent() ? _inner.send(chatIdHex, payload, peerPkHex: peerPkHex) : 0;
  @override
  int peerCount(String chatIdHex) =>
      _isCurrent() ? _inner.peerCount(chatIdHex) : 0;
  @override
  int dhtAnnounceCapableCount() =>
      _isCurrent() ? _inner.dhtAnnounceCapableCount() : 0;
}
