import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/src/engine/ditmesh_ffi_chat_service.dart';
import 'package:ditmesh_chat/src/engine/rhythm_protocol.dart';
import 'package:ditmesh_chat/src/chat/recording_metadata.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'helpers/fakes.dart';

class PacketFfi extends FakeTim2ToxFfi {
  final List<String> packets = [];
  final List<String> carriers = [];
  @override
  int Function(ffi.Pointer<Utf8>, ffi.Pointer<ffi.Uint8>, int, int)
  get sendC2CControlNative => (_, data, count, route) {
    final carrier = utf8.decode(data.asTypedList(count));
    carriers.add(carrier);
    expect(route, 1);
    expect(count, lessThanOrEqualTo(1300));
    final decoded = jsonDecode(carrier) as Map;
    packets.add(
      utf8.decode(base64Decode((decoded['msgID'] as String).substring(5))),
    );
    return 1;
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'capability is sender bound and modern recorded text receives exact ACK',
    () async {
      final dir = await Directory.systemTemp.createTemp('ditmesh_rhythm_');
      final native = PacketFfi()
        ..friends.add((userId: kPeerKey, nick: 'Bob', online: true));
      final svc =
          DitmeshFfiChatService(
              ffiForTesting: native,
              historyDirectory: dir.path,
            )
            ..debugBeginSessionForTest()
            ..debugSetSelfId(kSelfKey);
      try {
        svc.onFriendWireState(kPeerKey, true);
        final hello = jsonDecode(native.packets.last) as Map<String, dynamic>;
        final response = RhythmProtocol.control('hello_ack', {
          'nonce': hello['nonce'],
          'session': 'f' * 32,
        });
        svc.consumeCustomExtension('3' * 64, response);
        expect(svc.supportsRecordedPeer(kPeerKey), isFalse);
        svc.consumeCustomExtension(kPeerKey, response);
        expect(svc.supportsRecordedPeer(kPeerKey), isTrue);
        final recording = KeyedRecording(durationsMs: [83, 113, 251]);
        final sent = await svc.sendTextWithResult(
          kPeerKey,
          'CQ',
          clientMessageID: 'dmr:${'a' * 32}',
          cloudCustomData: RecordingMetadata.encode(recording),
        );
        expect(native.sentTextPeers, isEmpty);
        expect(sent.altMsgIds, contains('dmr:${'a' * 32}'));
        final assembler = RhythmPacketAssembler();
        Map<String, dynamic>? envelope;
        for (final packet in native.packets) {
          envelope = assembler.add(kSelfKey, '', packet) ?? envelope;
        }
        expect(envelope?['text'], 'CQ');
        svc.consumeCustomExtension(
          kPeerKey,
          RhythmProtocol.control('ack', {
            'id': 'a' * 32,
            'session': envelope!['authorSession'],
          }),
        );
        expect(svc.getHistory(kPeerKey).single.isReceived, isTrue);
        svc.onFriendWireState(kPeerKey, false);
        expect(svc.supportsRecordedPeer(kPeerKey), isFalse);
      } finally {
        await svc.dispose();
        await dir.delete(recursive: true);
      }
    },
  );
}
