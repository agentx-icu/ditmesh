import 'dart:async';
import 'dart:convert';
import 'package:tim2tox_dart/models/chat_message.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart' show KeyedRecording;
import '../chat/recording_metadata.dart';
import '../chat/group_bindings.dart';
import 'rhythm_protocol.dart';

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
    final transferId = RhythmProtocol.freshId();
    final packets = RhythmProtocol.packets(transferId, {
      'version': 1,
      'id': id,
      'transferId': transferId,
      'session': remoteSession,
      'authorSession': _session,
      'text': text,
      'contentKind': kind.name,
      'recording': recording.toJson(),
    });
    for (final packet in packets) {
      if (!service.sendExtensionPacket(peer, packet)) {
        // Once a chunk escaped, a plaintext fallback could duplicate the text.
        // Upstream keeps queued items on StateError's typed transport wrapper.
        throw StateError('Recorded message packet was not accepted');
      }
    }
    return 'dmr:$id';
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
          }
        case 'hello_ack':
          if (packet['nonce'] == _challenges[peer] &&
              RhythmProtocol.validId(packet['session'])) {
            _peerSessions[peer] = packet['session'] as String;
            final ready = _ready[peer];
            if (ready != null && !ready.isCompleted) ready.complete();
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

  void _queueDirect(String peer, Map<String, dynamic> envelope) {
    final previous = _directArrivals[peer] ?? Future<void>.value();
    final next = previous.then(
      (_) => _receiveDirect(peer, envelope).catchError((Object _) {}),
    );
    _directArrivals[peer] = next;
    unawaited(
      next.whenComplete(() {
        if (identical(_directArrivals[peer], next)) {
          _directArrivals.remove(peer);
        }
      }),
    );
  }

  Future<void> _receiveDirect(
    String peer,
    Map<String, dynamic> envelope,
  ) async {
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
      return;
    }
    final alias = 'dmr:$id';
    final scope = '$peer|$alias';
    if (!_receiving.add(scope)) return;
    final receiveEpoch = service.extensionSessionEpoch;
    try {
      final recording = envelope['version'] == 1
          ? KeyedRecording.fromJson(envelope['recording'])
          : null;
      await _receiveText(
        peer,
        alias,
        text,
        metadata: RecordingMetadata.encode(recording),
        kind: envelope['contentKind'] == 'action'
            ? ChatMessageContentKind.action
            : ChatMessageContentKind.normal,
      );
      // Duplicate envelope IDs are acknowledged again after disk identity
      // lookup, so a sender's retry can recover a lost receipt.
      if (service.extensionSessionEpoch == receiveEpoch &&
          !service.isBlocked(peer)) {
        service.sendExtensionPacket(
          peer,
          RhythmProtocol.control('ack', {'id': id, 'session': authorSession}),
        );
      }
    } finally {
      _receiving.remove(scope);
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
