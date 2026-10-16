import 'dart:async';
import 'dart:convert';
import 'package:tim2tox_dart/models/chat_message.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';
import 'package:tim2tox_dart/utils/message_history_persistence.dart'
    show MessageHistoryReceiptScope;
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart' show KeyedRecording;
import '../chat/recording_metadata.dart';
import '../chat/group_bindings.dart';
import 'rhythm_protocol.dart';
import 'rhythm_replay.dart';

/// Direct arrivals admitted but not yet finished, across every peer. Matches
/// the service-wide bound on receives awaiting persistence: an arrival beyond
/// it is dropped unacknowledged, so its sender never sees it as received.
const _maxQueuedDirectArrivals = 128;

/// A validated direct envelope plus the session epoch and history receipt
/// scope current when it arrived. A clear or a session change while it waits
/// behind an earlier arrival makes it stale, so it is never stored or ACKed.
typedef _DirectArrival = ({
  String key,
  String id,
  String text,
  String authorSession,
  Map<String, dynamic> envelope,
  int epoch,
  MessageHistoryReceiptScope scope,
});

/// Direct replay uses a negotiated envelope because standard C2C text has no
/// cross-peer ID. NGC keeps its ordinary text and attaches by native gmid.
final class RhythmTransport {
  RhythmTransport(this.service, {RecordedTextReceiver? receiveText})
    : _receiveText = receiveText ?? service.receiveExtensionText;
  final FfiChatService service;

  /// Persists and publishes one recorded arrival; the service's own receive
  /// path, replaceable in tests to control its timing.
  final RecordedTextReceiver _receiveText;
  final String _session = RhythmProtocol.freshId();
  final _assembler = RhythmPacketAssembler();
  final Map<String, String> _challenges = {};
  final Map<String, String> _peerSessions = {};
  final Map<String, DateTime> _helloAt = {};
  final Map<String, Completer<void>> _ready = {};

  /// Peers with a replay in flight, mapped to whether another handshake
  /// completed meanwhile and asked for a rerun. A rerun is never dropped: a
  /// fresh hello may be a new recovery even under an unchanged session.
  final Map<String, bool> _replays = {};

  /// `peer|dmr:id` of every direct arrival from admission until it finishes,
  /// whether queued or being received; its size is the admitted count.
  final Set<String> _receiving = {};
  final Map<String, String> _groupMetadata = {};

  /// The tail of each peer's direct-arrival chain. The receive path awaits
  /// disk work before it stamps and appends a row, so two arrivals handled
  /// concurrently could be stored, and shown, in reverse order; each one
  /// waits for the previous one from the same peer instead.
  final Map<String, Future<void>> _directArrivals = {};

  bool supportsPeer(String peer) =>
      _peerSessions.containsKey(peer.toUpperCase());

  void presence(String peer, bool online) {
    peer = peer.toUpperCase();
    if (!online) {
      _peerSessions.remove(peer);
      _challenges.remove(peer);
      _helloAt.remove(peer);
      _ready.remove(peer);
      return;
    }
    if (supportsPeer(peer)) return;
    final last = _helloAt[peer];
    if (last != null && DateTime.now().difference(last).inSeconds < 2) return;
    final nonce = _challenges.putIfAbsent(peer, RhythmProtocol.freshId);
    _helloAt[peer] = DateTime.now();
    service.sendExtensionPacket(
      peer,
      RhythmProtocol.control('hello', {'nonce': nonce, 'session': _session}),
    );
  }

  Future<String?> send(
    String peer,
    String text,
    String? metadata, {
    String? durableId,
    required ChatMessageContentKind kind,
  }) async {
    final recording = RecordingMetadata.decode(metadata);
    if (recording == null) return null;
    peer = peer.toUpperCase();
    presence(peer, true);
    if (!supportsPeer(peer)) {
      final ready = _ready.putIfAbsent(peer, Completer<void>.new);
      try {
        await ready.future.timeout(const Duration(milliseconds: 1500));
      } on TimeoutException {
        /* Legacy peers receive ordinary plaintext. */
      }
    }
    final remoteSession = _peerSessions[peer];
    if (remoteSession == null) return null;
    final candidate = durableId?.startsWith('dmr:') == true
        ? durableId!.substring(4)
        : null;
    final id = RhythmProtocol.validId(candidate)
        ? candidate!
        : RhythmProtocol.freshId();
    if (!_sendAll(
      peer,
      _envelopePackets(remoteSession, id, text, recording, kind),
    )) {
      // Once a chunk escaped, a plaintext fallback could duplicate the text.
      // A queue drain keeps its item for a later retry under the same id.
      throw ExtensionSendRefused('Recorded message packet was not accepted');
    }
    return 'dmr:$id';
  }

  /// One envelope addressed to [remoteSession], under a fresh transfer id.
  /// A replay keeps [id], which the receiver deduplicates and acknowledges.
  List<String> _envelopePackets(
    String remoteSession,
    String id,
    String text,
    KeyedRecording recording,
    ChatMessageContentKind kind,
  ) {
    final transferId = RhythmProtocol.freshId();
    return RhythmProtocol.packets(transferId, {
      'version': 1,
      'id': id,
      'transferId': transferId,
      'session': remoteSession,
      'authorSession': _session,
      'text': text,
      'contentKind': kind.name,
      'recording': recording.toJson(),
    });
  }

  bool _sendAll(String peer, List<String> packets) {
    for (final packet in packets) {
      if (!service.sendExtensionPacket(peer, packet)) return false;
    }
    return true;
  }

  /// Resends this peer's unacknowledged recorded rows ([RhythmReplay]) once
  /// the handshake has completed again: after a silent drop, a restart on
  /// either side, or a peer that lost our session.
  void _replayUnacked(String peer) {
    if (!_peerSessions.containsKey(peer)) return;
    if (_replays.containsKey(peer)) {
      _replays[peer] = true;
      return;
    }
    _replays[peer] = false;
    unawaited(_runReplays(peer, service.extensionSessionEpoch));
  }

  Future<void> _runReplays(String peer, int epoch) async {
    try {
      do {
        _replays[peer] = false;
        await _replay(peer, epoch);
      } while (_replays[peer] == true &&
          epoch == service.extensionSessionEpoch);
    } on Object {
      // Best effort: the rows stay unacknowledged for the next handshake.
    } finally {
      _replays.remove(peer);
    }
  }

  Future<void> _replay(String peer, int epoch) async {
    // Sends this handshake released go first: a replay only takes the send
    // capacity they leave, and stops at its first refused packet.
    await Future<void>(() {});
    final session = _peerSessions[peer];
    if (session == null) return;
    // A cold start may not have loaded this conversation yet.
    if (service.getHistory(peer).isEmpty) await service.loadHistory(peer);
    // The peer went offline, restarted or was blocked meanwhile, or this
    // service closed: a rerun or the next handshake replays instead.
    if (epoch != service.extensionSessionEpoch ||
        _peerSessions[peer] != session ||
        service.isBlocked(peer)) {
      return;
    }
    final rows = RhythmReplay.candidates(
      service.getHistory(peer),
      DateTime.now(),
    );
    for (final row in rows) {
      final packets = _envelopePackets(
        session,
        RhythmReplay.wireId(row)!,
        row.text,
        RecordingMetadata.decode(row.cloudCustomData)!,
        row.contentKind,
      );
      // A full send buffer or a closed session: the next handshake retries.
      if (!_sendAll(peer, packets)) return;
    }
  }

  bool consume(String peer, String payload, {String? groupId}) {
    Map<String, dynamic>? packet;
    try {
      final value = jsonDecode(payload);
      if (value is! Map<String, dynamic> || !value.containsKey('ditmesh')) {
        return false;
      }
      packet = RhythmProtocol.parse(payload);
    } on FormatException {
      return false;
    }
    // Reserved extension controls never become custom rows, even when a newer
    // version or invalid metadata cannot be interpreted by this client.
    if (packet == null || service.isBlocked(peer)) return true;
    peer = peer.toUpperCase();
    if (groupId == null) {
      switch (packet['kind']) {
        case 'hello':
          final nonce = packet['nonce'];
          if (RhythmProtocol.validId(nonce)) {
            // Native transport authenticates the sender. A fresh hello can
            // therefore refresh a restarted peer even when no offline poll
            // was observed. Invalidate older challenges before accepting ACKs.
            if (RhythmProtocol.validId(packet['session'])) {
              _peerSessions[peer] = packet['session'] as String;
              _challenges.remove(peer);
              final ready = _ready[peer];
              if (ready != null && !ready.isCompleted) ready.complete();
            }
            service.sendExtensionPacket(
              peer,
              RhythmProtocol.control('hello_ack', {
                'nonce': nonce,
                'session': _session,
              }),
            );
            presence(peer, true);
            // A peer says hello only when it lacks our session: it restarted
            // or saw us offline, so what we sent meanwhile may be lost.
            _replayUnacked(peer);
          }
        case 'hello_ack':
          if (packet['nonce'] == _challenges[peer] &&
              RhythmProtocol.validId(packet['session'])) {
            _peerSessions[peer] = packet['session'] as String;
            final ready = _ready[peer];
            if (ready != null && !ready.isCompleted) ready.complete();
            _replayUnacked(peer);
          }
        case 'ack':
          if (packet['session'] == _session &&
              RhythmProtocol.validId(packet['id'])) {
            service.applyNativeDeliveryAck(peer, 'dmr:${packet['id']}');
          }
      }
    }
    if (packet['kind'] == 'chunk') {
      final envelope = _assembler.add(peer, groupId ?? '', payload);
      if (envelope != null && envelope['transferId'] == packet['id']) {
        if (groupId == null) {
          _queueDirect(peer, envelope);
        } else {
          _receiveGroup(peer, groupId, envelope);
        }
      }
    }
    return true;
  }

  /// Admits [envelope] behind the peer's earlier arrivals. Validation, the
  /// duplicate check and the bound run here, and the epoch and receipt scope
  /// are captured here, because the receive itself may wait arbitrarily long.
  void _queueDirect(String peer, Map<String, dynamic> envelope) {
    final arrival = _admitDirect(peer, envelope);
    if (arrival == null) return;
    final previous = _directArrivals[peer] ?? Future<void>.value();
    final next = previous.then((_) async {
      try {
        await _receiveDirect(peer, arrival);
      } on Object {
        // A failed arrival must not block the next one; it stays unACKed.
      } finally {
        _receiving.remove(arrival.key);
      }
    });
    _directArrivals[peer] = next;
    unawaited(
      next.whenComplete(() {
        if (identical(_directArrivals[peer], next)) {
          _directArrivals.remove(peer);
        }
      }),
    );
  }

  _DirectArrival? _admitDirect(String peer, Map<String, dynamic> envelope) {
    final id = envelope['id'];
    final text = envelope['text'];
    final authorSession = envelope['authorSession'];
    if (envelope['session'] != _session ||
        !RhythmProtocol.validId(id) ||
        !RhythmProtocol.validId(authorSession) ||
        text is! String ||
        text.isEmpty ||
        text.contains('\u0000') ||
        utf8.encode(text).length > 1322) {
      return null;
    }
    final key = '$peer|dmr:$id';
    if (_receiving.length >= _maxQueuedDirectArrivals || !_receiving.add(key)) {
      return null;
    }
    return (
      key: key,
      id: id as String,
      text: text,
      authorSession: authorSession as String,
      envelope: envelope,
      epoch: service.extensionSessionEpoch,
      // The same store, normalized conversation and clear generation the
      // service's own receive captures.
      scope: service.messageHistoryPersistence.receiptScope(
        service.normalizeToxId(peer),
      ),
    );
  }

  Future<void> _receiveDirect(String peer, _DirectArrival arrival) async {
    // No await precedes the service call, so its own receipt scope is taken
    // in the generation checked here.
    if (arrival.epoch != service.extensionSessionEpoch ||
        !arrival.scope.isCurrent) {
      return;
    }
    final envelope = arrival.envelope;
    final recording = envelope['version'] == 1
        ? KeyedRecording.fromJson(envelope['recording'])
        : null;
    await _receiveText(
      peer,
      'dmr:${arrival.id}',
      arrival.text,
      metadata: RecordingMetadata.encode(recording),
      kind: envelope['contentKind'] == 'action'
          ? ChatMessageContentKind.action
          : ChatMessageContentKind.normal,
    );
    // Duplicate envelope IDs are acknowledged again after disk identity
    // lookup, so a sender's retry can recover a lost receipt. A row that
    // became durable before a later clear is still acknowledged.
    if (service.extensionSessionEpoch == arrival.epoch &&
        !service.isBlocked(peer)) {
      service.sendExtensionPacket(
        peer,
        RhythmProtocol.control('ack', {
          'id': arrival.id,
          'session': arrival.authorSession,
        }),
      );
    }
  }

  void groupSent(String group, String text, String? metadata, String? alias) {
    final recording = RecordingMetadata.decode(metadata);
    if (recording == null || alias == null) return;
    final parts = alias.substring('gmid:'.length).split('|');
    if (parts.length != 3) return;
    final chatId = service.getGroupChatId(group);
    if (chatId == null) return;
    final id = RhythmProtocol.freshId();
    final packets = RhythmProtocol.packets(id, {
      'version': 1,
      'id': id,
      'transferId': id,
      'chatId': chatId.toUpperCase(),
      'sender': parts[1].toUpperCase(),
      'messageId': int.tryParse(parts[2]),
      'recording': recording.toJson(),
    });
    unawaited(
      _sendGroupMetadata(group, parts[1], packets).catchError((Object _) {}),
    );
  }

  Future<void> _sendGroupMetadata(
    String group,
    String selfKey,
    List<String> packets,
  ) async {
    final members = await GroupBindings.members(
      group,
      selfKey: selfKey,
      nameOf: (_) => null,
    );
    for (final member in members) {
      if (member.isSelf || !member.online) continue;
      for (final packet in packets) {
        if (!service.sendExtensionPacket(
          member.publicKey,
          packet,
          groupId: group,
        )) {
          break;
        }
      }
    }
  }

  void _receiveGroup(String peer, String group, Map<String, dynamic> envelope) {
    final id = envelope['messageId'];
    final recording = KeyedRecording.fromJson(envelope['recording']);
    if (envelope['version'] != 1 ||
        recording == null ||
        id is! int ||
        id < 0 ||
        id > 0xffffffff ||
        envelope['sender'] != peer ||
        envelope['chatId'] != service.getGroupChatId(group)?.toUpperCase()) {
      return;
    }
    final alias = FfiChatService.groupMessageAlias(
      groupId: group,
      senderPk: peer,
      pseudoMsgId: id,
    );
    final metadata = RecordingMetadata.encode(recording)!;
    if (_groupMetadata.length >= 128) {
      _groupMetadata.remove(_groupMetadata.keys.first);
    }
    _groupMetadata.putIfAbsent(alias, () => metadata);
    unawaited(
      service
          .attachExtensionMetadata(group, peer, alias, _groupMetadata[alias]!)
          .catchError((Object _) => false),
    );
  }

  ChatMessage enrich(ChatMessage row) {
    for (final alias in row.altMsgIds) {
      final metadata = _groupMetadata[alias];
      if (metadata != null) return row.copyWith(cloudCustomData: metadata);
    }
    return row;
  }
}

/// Signature of `FfiChatService.receiveExtensionText`.
typedef RecordedTextReceiver =
    Future<bool> Function(
      String sender,
      String alias,
      String text, {
      String? metadata,
      ChatMessageContentKind kind,
    });
