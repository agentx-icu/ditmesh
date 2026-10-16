import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/src/engine/ditmesh_ffi_chat_service.dart';
import 'package:ditmesh_chat/src/engine/rhythm_protocol.dart';
import 'package:ditmesh_chat/src/engine/rhythm_replay.dart';
import 'package:ditmesh_chat/src/chat/recording_metadata.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart' show KeyedRecording;
import 'package:tim2tox_dart/models/chat_message.dart';
import 'package:tim2tox_dart/utils/offline_message_queue_persistence.dart';
import 'helpers/fakes.dart';
import 'rhythm_service_test.dart' show PacketFfi;

final _id = 'a' * 32;
final _metadata = RecordingMetadata.encode(
  KeyedRecording(durationsMs: [83, 113, 251]),
);

/// A native control send that can refuse packets (a full send buffer).
final class _GateFfi extends PacketFfi {
  bool refuse = false;
  bool refuseChunks = false;
  int refused = 0;
  @override
  int Function(ffi.Pointer<Utf8>, ffi.Pointer<ffi.Uint8>, int, int)
  get sendC2CControlNative {
    final accept = super.sendC2CControlNative;
    return (peer, data, count, route) {
      final carrier = jsonDecode(utf8.decode(data.asTypedList(count))) as Map;
      final packet = utf8.decode(
        base64Decode((carrier['msgID'] as String).substring(5)),
      );
      if (!refuse && !(refuseChunks && _isChunk(packet))) {
        return accept(peer, data, count, route);
      }
      refused++;
      return 0;
    };
  }
}

/// The sender, whose history load can be held and whose peer can be blocked
/// while a replay waits for that load.
final class _Alice extends DitmeshFfiChatService {
  _Alice(String dir, PacketFfi ffi)
    : super(
        historyDirectory: dir,
        queueFilePath: '$dir/queue.json',
        ffiForTesting: ffi,
      );
  Completer<void>? hold;
  bool blocked = false;
  int loads = 0;

  @override
  Future<void> loadHistory(String id) async {
    loads++;
    await hold?.future;
    return super.loadHistory(id);
  }

  @override
  bool isBlocked(String peerId) => blocked || super.isBlocked(peerId);
}

bool _isChunk(String packet) =>
    (jsonDecode(packet) as Map<String, dynamic>)['kind'] == 'chunk';

/// Alice (sender, `a`) and Bob (receiver, `b`) joined by a packet pump that
/// can drop either direction, the way a silent drop loses buffered packets.
final class _Pair {
  _Pair(this.root) {
    startAlice();
    startBob();
  }
  final Directory root;
  late _GateFfi af;
  late PacketFfi bf;
  late _Alice a;
  late DitmeshFfiChatService b;
  var _ai = 0, _bi = 0;
  bool dropToBob = false, dropToAlice = false, dropChunksToBob = false;

  /// Every packet Alice and Bob sent, across restarts.
  final List<String> aliceSent = [], bobSent = [];

  void startAlice({bool bobOnline = true}) {
    af = _GateFfi()
      ..friends.add((userId: kPeerKey, nick: 'Bob', online: bobOnline));
    a = _Alice('${root.path}/a', af)
      ..debugBeginSessionForTest()
      ..debugSetSelfId(kSelfKey);
    _ai = 0;
  }

  void startBob() {
    bf = PacketFfi()
      ..friends.add((userId: kSelfKey, nick: 'Alice', online: true));
    b =
        DitmeshFfiChatService(
            historyDirectory: '${root.path}/b',
            ffiForTesting: bf,
          )
          ..debugBeginSessionForTest()
          ..debugSetSelfId(kPeerKey);
    _bi = 0;
  }

  /// Reports Bob's native presence to Alice's friend-list poll.
  void setBobOnline(bool online) =>
      af.friends[0] = (userId: kPeerKey, nick: 'Bob', online: online);

  void _deliver() {
    while (_ai < af.packets.length) {
      final packet = af.packets[_ai++];
      aliceSent.add(packet);
      if (dropToBob || (dropChunksToBob && _isChunk(packet))) continue;
      b.consumeCustomExtension(kSelfKey, packet);
    }
    while (_bi < bf.packets.length) {
      final packet = bf.packets[_bi++];
      bobSent.add(packet);
      if (!dropToAlice) a.consumeCustomExtension(kPeerKey, packet);
    }
  }

  /// Pumps packets and the async receive/replay work until both go quiet.
  /// Only negative expectations rely on it; positive ones await [until].
  Future<void> settle() async {
    var quiet = 0;
    for (var round = 0; quiet < 10; round++) {
      if (round == 200) throw StateError('packets never went quiet');
      final before = aliceSent.length + bobSent.length;
      _deliver();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      _deliver();
      quiet = aliceSent.length + bobSent.length == before ? quiet + 1 : 0;
    }
  }

  /// Pumps packets until [done] holds, failing after ten seconds.
  Future<void> until(bool Function() done) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (!done()) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('expected state never reached');
      }
      _deliver();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    _deliver();
  }

  /// Bob stored the message once and Alice saw its ACK.
  Future<void> delivered() => until(
    () =>
        bobRows().isNotEmpty &&
        a.getHistory(kPeerKey).any((row) => row.text == 'CQ' && row.isReceived),
  );

  Future<void> connect() async {
    a.onFriendWireState(kPeerKey, true);
    b.onFriendWireState(kSelfKey, true);
    await settle();
    expect(a.supportsRecordedPeer(kPeerKey), isTrue);
    expect(b.supportsRecordedPeer(kSelfKey), isTrue);
  }

  /// Both sides observe the peer offline (toxcore's 32 s timeout).
  void dropLink() {
    a.onFriendWireState(kPeerKey, false);
    b.onFriendWireState(kSelfKey, false);
  }

  Future<ChatMessage> send({String text = 'CQ', String? id}) =>
      a.sendTextWithResult(
        kPeerKey,
        text,
        clientMessageID: 'dmr:${id ?? _id}',
        cloudCustomData: _metadata,
      );

  /// Alice sends into a silent drop, then restarts with the row on disk.
  Future<void> restartAliceWithUnacked() async {
    await connect();
    dropToBob = true;
    await send();
    await a.flushPendingHistory();
    await a.dispose();
    startAlice();
    dropToBob = false;
    b.onFriendWireState(kSelfKey, false);
  }

  ChatMessage aliceRow() =>
      a.getHistory(kPeerKey).singleWhere((row) => row.text == 'CQ');

  List<ChatMessage> bobRows() =>
      b.getHistory(kSelfKey).where((row) => row.text == 'CQ').toList();

  Future<void> dispose() async {
    await a.dispose();
    await b.dispose();
  }
}

/// Envelopes carrying [id] among [packets], one per complete transfer.
int envelopesWithId(List<String> packets, String id) {
  final assembler = RhythmPacketAssembler();
  var count = 0;
  for (final packet in packets) {
    final envelope = assembler.add('peer', '', packet);
    if (envelope != null && envelope['id'] == id) count++;
  }
  return count;
}

int acksWithId(List<String> packets, String id) => packets.where((packet) {
  final value = jsonDecode(packet) as Map<String, dynamic>;
  return value['kind'] == 'ack' && value['id'] == id;
}).length;

ChatMessage _row({
  required DateTime at,
  String id = 'dmr:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  List<String>? alias,
  bool received = false,
  bool failed = false,
  bool self = true,
  String? metadata,
}) => ChatMessage(
  text: 'CQ',
  fromUserId: kSelfKey,
  isSelf: self,
  timestamp: at,
  msgID: id,
  altMsgIds: alias ?? [id],
  isReceived: received,
  isFailed: failed,
  cloudCustomData: metadata ?? _metadata,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late _Pair pair;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('ditmesh_resend_');
    pair = _Pair(root);
  });
  tearDown(() async {
    await pair.dispose();
    await root.delete(recursive: true);
  });

  test('a send lost in a silent drop is resent once after the handshake, '
      'and its ACK ends the replays', () async {
    await pair.connect();
    pair.dropToBob = true;
    final sent = await pair.send();
    expect(sent.altMsgIds, ['dmr:$_id']);
    await pair.settle();
    expect(pair.bobRows(), isEmpty);
    pair.dropLink();
    pair.dropToBob = false;
    final before = pair.aliceSent.length;
    await pair.connect();
    await pair.delivered();
    expect(envelopesWithId(pair.aliceSent.sublist(before), _id), 1);
    expect(pair.bobRows(), hasLength(1));
    expect(pair.aliceRow().isReceived, isTrue);

    pair.dropLink();
    final again = pair.aliceSent.length;
    await pair.connect();
    expect(envelopesWithId(pair.aliceSent.sublist(again), _id), 0);
    await pair.delivered();
    expect(pair.bobRows(), hasLength(1));
  });

  test('a send acknowledged before the drop is not resent', () async {
    await pair.connect();
    await pair.send();
    await pair.settle();
    await pair.delivered();
    expect(pair.aliceRow().isReceived, isTrue);
    pair.dropLink();
    final before = pair.aliceSent.length;
    await pair.connect();
    expect(envelopesWithId(pair.aliceSent.sublist(before), _id), 0);
    await pair.delivered();
    expect(pair.bobRows(), hasLength(1));
  });

  test(
    'an unacknowledged row on disk is resent by a restarted sender',
    () async {
      await pair.restartAliceWithUnacked();
      final before = pair.aliceSent.length;
      await pair.connect();
      await pair.delivered();
      expect(envelopesWithId(pair.aliceSent.sublist(before), _id), 1);
      expect(pair.bobRows(), hasLength(1));
      expect(pair.aliceRow().isReceived, isTrue);
    },
  );

  test(
    'a stored arrival whose ACK was lost is stored once and ACKed again',
    () async {
      await pair.connect();
      pair.dropToAlice = true;
      await pair.send();
      await pair.until(() => pair.bobRows().isNotEmpty);
      await pair.settle();
      expect(pair.bobRows(), hasLength(1));
      expect(pair.aliceRow().isReceived, isFalse);
      pair.dropLink();
      pair.dropToAlice = false;
      await pair.connect();
      await pair.delivered();
      expect(pair.bobRows(), hasLength(1));
      expect(acksWithId(pair.bobSent, _id), 2);
      expect(pair.aliceRow().isReceived, isTrue);
    },
  );

  test(
    'a receiver restart the sender never saw as offline gets the resend',
    () async {
      await pair.connect();
      pair.dropToBob = true;
      await pair.send();
      await pair.settle();
      await pair.b.dispose();
      pair.startBob();
      pair.dropToBob = false;
      final before = pair.aliceSent.length;
      // Alice's online poll never observed Bob's outage.
      pair.b.onFriendWireState(kSelfKey, true);
      await pair.settle();
      await pair.delivered();
      expect(envelopesWithId(pair.aliceSent.sublist(before), _id), 1);
      expect(pair.bobRows(), hasLength(1));
      expect(pair.aliceRow().isReceived, isTrue);
    },
  );

  test(
    'a recorded send that fell back to plain text is never replayed',
    () async {
      // Bob never answers the hello, so the recorded send times out to text.
      pair.dropToBob = true;
      final sent = await pair.send();
      expect(sent.msgID, 'dmr:$_id');
      expect(sent.altMsgIds, isNot(contains('dmr:$_id')));
      expect(pair.af.sentTextPeers, [kPeerKey]);
      pair.dropLink();
      pair.dropToBob = false;
      await pair.connect();
      expect(envelopesWithId(pair.aliceSent, _id), 0);
    },
  );

  test(
    'a one-sided reconnect under an unchanged session replays again',
    () async {
      await pair.connect();
      pair.dropToBob = true;
      await pair.send();
      await pair.settle();
      // Only Bob saw the outage; Alice replayed moments ago for this session.
      pair.b.onFriendWireState(kSelfKey, false);
      pair.dropToBob = false;
      final before = pair.aliceSent.length;
      pair.b.onFriendWireState(kSelfKey, true);
      await pair.settle();
      await pair.delivered();
      expect(envelopesWithId(pair.aliceSent.sublist(before), _id), 1);
      expect(pair.bobRows(), hasLength(1));
      expect(pair.aliceRow().isReceived, isTrue);
    },
  );

  test(
    'a row whose queue item is a cancelled tombstone is not replayed',
    () async {
      await pair.restartAliceWithUnacked();
      // The cancel committed on the queue; its history write was lost.
      await pair.a.loadHistory(kPeerKey);
      pair.a.offlineMessageQueuePersistence.setCache({
        kPeerKey: [
          (
            kind: 'text',
            text: 'CQ',
            filePath: null,
            fileName: null,
            timestamp: pair.aliceRow().timestamp,
            msgID: 'dmr:$_id',
            cloudCustomData: _metadata,
            contentKind: ChatMessageContentKind.normal,
            control: OfflineSendControl.cancelled,
          ),
        ],
      });
      expect(pair.aliceRow().isCancelled, isFalse);
      final before = pair.aliceSent.length;
      await pair.connect();
      await pair.settle();
      expect(envelopesWithId(pair.aliceSent.sublist(before), _id), 0);
      expect(pair.bobRows(), isEmpty);
    },
  );

  test('an offline-queue drain lost in a silent drop is resent', () async {
    pair.setBobOnline(false);
    await pair.a.getFriendList();
    final queued = await pair.send();
    expect(queued.isPending, isTrue);
    // Bob returns; the drain's envelope is lost after its queue item goes.
    pair.dropChunksToBob = true;
    pair.setBobOnline(true);
    await pair.a.getFriendList();
    await pair.settle();
    expect(pair.aliceRow().altMsgIds, contains('dmr:$_id'));
    expect(pair.aliceRow().isPending, isFalse);
    expect(pair.bobRows(), isEmpty);
    pair.dropLink();
    pair.dropChunksToBob = false;
    await pair.connect();
    await pair.delivered();
    expect(pair.bobRows(), hasLength(1));
    expect(pair.aliceRow().isReceived, isTrue);
  });

  test('a refused packet keeps a draining queue item queued', () async {
    pair.setBobOnline(false);
    await pair.a.getFriendList();
    await pair.send();
    pair.af.refuseChunks = true;
    pair.setBobOnline(true);
    await pair.a.getFriendList();
    await pair.until(() => pair.af.refused > 0);
    await pair.settle();
    final kept = pair.aliceRow();
    expect(kept.isPending, isTrue);
    expect(kept.isFailed, isFalse);
    expect(pair.a.offlineMessageQueuePersistence.getMessages(kPeerKey), [
      isA<Object>(),
    ]);
    pair.af.refuseChunks = false;
    pair.dropLink();
    pair.setBobOnline(false);
    await pair.a.getFriendList();
    pair.setBobOnline(true);
    await pair.a.getFriendList();
    await pair.delivered();
    expect(pair.bobRows(), hasLength(1));
    expect(
      pair.a.offlineMessageQueuePersistence.getMessages(kPeerKey),
      isEmpty,
    );
  });

  test(
    'a refused packet ends the replay; the next handshake retries',
    () async {
      final second = 'b' * 32;
      await pair.connect();
      pair.dropToBob = true;
      await pair.send();
      await pair.send(text: 'QRZ', id: second);
      await pair.settle();
      pair.dropLink();
      pair.dropToBob = false;
      pair.af.refuse = true;
      pair.b.onFriendWireState(kSelfKey, true);
      await pair.settle();
      // The hello_ack and the first row's first chunk; the second row waits.
      expect(pair.af.refused, 2);
      pair.af.refuse = false;
      pair.dropLink();
      final before = pair.aliceSent.length;
      await pair.connect();
      await pair.delivered();
      expect(envelopesWithId(pair.aliceSent.sublist(before), _id), 1);
      expect(envelopesWithId(pair.aliceSent.sublist(before), second), 1);
      await pair.until(() => pair.b.getHistory(kSelfKey).length == 2);
      expect(pair.b.getHistory(kSelfKey).map((row) => row.text), ['CQ', 'QRZ']);
    },
  );

  group('a replay waiting for the history load', () {
    Future<void> holdReplay() async {
      await pair.restartAliceWithUnacked();
      pair.a.hold = Completer<void>();
      await pair.connect();
      expect(pair.a.loads, 1);
    }

    test('does not send once the peer is blocked', () async {
      await holdReplay();
      pair.a.blocked = true;
      final before = pair.af.packets.length;
      pair.a.hold!.complete();
      await pair.settle();
      expect(envelopesWithId(pair.af.packets.sublist(before), _id), 0);
    });

    test('does not send to a session that went away', () async {
      await holdReplay();
      pair.dropLink();
      final before = pair.aliceSent.length;
      pair.a.hold!.complete();
      await pair.settle();
      expect(envelopesWithId(pair.aliceSent.sublist(before), _id), 0);
      await pair.connect();
      await pair.delivered();
      expect(envelopesWithId(pair.aliceSent.sublist(before), _id), 1);
      expect(pair.aliceRow().isReceived, isTrue);
    });

    test('does not send after the service is disposed', () async {
      await holdReplay();
      final before = pair.af.packets.length;
      final disposing = pair.a.dispose();
      pair.a.hold!.complete();
      await disposing;
      await pair.settle();
      expect(pair.af.packets.sublist(before), isEmpty);
    });
  });

  group('RhythmReplay.candidates', () {
    final now = DateTime(2026, 10, 16, 12);
    String id(int i) => 'dmr:${i.toRadixString(16).padLeft(32, '0')}';

    test('takes the oldest eligible rows up to the cap', () {
      final rows = [
        for (var i = 40; i > 0; i--)
          _row(
            at: now.subtract(Duration(minutes: i)),
            id: id(i),
          ),
      ];
      final picked = RhythmReplay.candidates(rows.reversed.toList(), now);
      expect(picked, hasLength(RhythmReplay.maxRows));
      expect(picked.first.msgID, id(40));
      expect(picked.last.msgID, id(40 - RhythmReplay.maxRows + 1));
    });

    test(
      'skips received, failed, aged, incoming, unrecorded and text rows',
      () {
        final fresh = now.subtract(const Duration(minutes: 1));
        final rows = [
          _row(at: fresh, id: id(1), received: true),
          _row(at: fresh, id: id(2), failed: true),
          _row(at: now.subtract(RhythmReplay.maxAge * 2), id: id(3)),
          _row(at: fresh, id: id(4), self: false),
          _row(at: fresh, id: id(5), metadata: 'not json'),
          _row(at: fresh, id: id(6), alias: ['native-6']),
          _row(at: fresh, id: id(7)),
        ];
        expect(RhythmReplay.candidates(rows, now).map((row) => row.msgID), [
          id(7),
        ]);
      },
    );
  });
}
