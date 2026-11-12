import 'dart:typed_data';

sealed class RendezvousEvent {
  RendezvousEvent(this.chatIdHex);

  /// Lower-case hex Chat ID (64 chars) of the cell.
  final String chatIdHex;
}

/// We are in the cell: joined an existing group (`founded == false`) or
/// founded it because nobody answered within 30 s (`founded == true`).
final class RendezvousJoined extends RendezvousEvent {
  RendezvousJoined(super.chatIdHex, {required this.founded});
  final bool founded;
}

/// We left the cell. `reason` is one of `kicked`, `failed`, `stale`, `left`,
/// `full`. (`refound` is internal and never surfaces.)
final class RendezvousLeft extends RendezvousEvent {
  RendezvousLeft(super.chatIdHex, {required this.reason});
  final String reason;
}

/// A peer became confirmed (`joined == true`) or left.
final class RendezvousPeer extends RendezvousEvent {
  RendezvousPeer(
    super.chatIdHex, {
    required this.peerPkHex,
    required this.joined,
  });
  final String peerPkHex;
  final bool joined;
}

/// Coalesced form emitted when peer events exceed the native budget: the
/// client should re-read the peer count and rebuild its table lazily.
final class RendezvousPeersChanged extends RendezvousEvent {
  RendezvousPeersChanged(super.chatIdHex, {required this.count});
  final int count;
}

/// The cell refused us because it is full (peer limit).
final class RendezvousFull extends RendezvousEvent {
  RendezvousFull(super.chatIdHex);
}

/// An opaque payload from `peerPkHex` (`private == true` when it came over a
/// private packet).
final class RendezvousPacket extends RendezvousEvent {
  RendezvousPacket(
    super.chatIdHex, {
    required this.peerPkHex,
    required this.isPrivate,
    required this.payload,
  });
  final String peerPkHex;
  final bool isPrivate;
  final Uint8List payload;
}

abstract class NearbyTransport {
  Stream<RendezvousEvent> get events;

  /// 1 accepted, 0 refused, 2 already present.
  int join(Uint8List seed, {required String name, required String nick});
  bool leave(String chatIdHex);
  int leaveAll();

  /// 1 sent, 0 not sent, -1 too large, -2 unknown peer, -3 unknown cell.
  int send(String chatIdHex, Uint8List payload, {String? peerPkHex});
  int peerCount(String chatIdHex);
  int dhtAnnounceCapableCount();
}

/// Optional chat-backend capability. A transport is valid for one session only.
abstract interface class NearbyTransportProvider {
  NearbyTransport? get nearbyTransport;
}
