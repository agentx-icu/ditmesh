import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/src/engine/ditmesh_ffi_chat_service.dart';
import 'package:ditmesh_chat/src/engine/rhythm_protocol.dart';
import 'package:ditmesh_chat/src/chat/recording_metadata.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'helpers/fakes.dart';
import 'rhythm_service_test.dart' show PacketFfi;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'old hello remains compatible and late old ACK cannot roll back refreshed session',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'ditmesh_hello_compat_',
      );
      final native = PacketFfi()
        ..friends.add((userId: kPeerKey, nick: 'Bob', online: true));
      final svc =
          DitmeshFfiChatService(
              historyDirectory: root.path,
              ffiForTesting: native,
            )
            ..debugBeginSessionForTest()
            ..debugSetSelfId(kSelfKey);
      try {
        svc.onFriendWireState(kPeerKey, true);
        final ourHello = jsonDecode(native.packets.last) as Map;
        final oldNonce = ourHello['nonce'];
        svc.consumeCustomExtension(
          kPeerKey,
          RhythmProtocol.control('hello', {'nonce': 'a' * 32}),
        );
        expect(svc.supportsRecordedPeer(kPeerKey), isFalse);
        svc.consumeCustomExtension(
          kPeerKey,
          RhythmProtocol.control('hello_ack', {
            'nonce': oldNonce,
            'session': 'e' * 32,
          }),
        );
        expect(svc.supportsRecordedPeer(kPeerKey), isTrue);
        final recording = RecordingMetadata.encode(
          KeyedRecording(durationsMs: [83]),
        );
        await svc.sendTextWithResult(
          kPeerKey,
          'OLD',
          clientMessageID: 'dmr:${'1' * 32}',
          cloudCustomData: recording,
        );
        svc.consumeCustomExtension(
          kPeerKey,
          RhythmProtocol.control('hello', {
            'nonce': 'b' * 32,
            'session': 'f' * 32,
          }),
        );
        svc.consumeCustomExtension(
          kPeerKey,
          RhythmProtocol.control('hello_ack', {
            'nonce': oldNonce,
            'session': 'e' * 32,
          }),
        );
        await svc.sendTextWithResult(
          kPeerKey,
          'NEW',
          clientMessageID: 'dmr:${'2' * 32}',
          cloudCustomData: recording,
        );
        final assembler = RhythmPacketAssembler();
        final envelopes = <Map<String, dynamic>>[];
        for (final p in native.packets) {
          final e = assembler.add(kSelfKey, '', p);
          if (e != null) envelopes.add(e);
        }
        expect(envelopes[0]['session'], 'e' * 32);
        expect(envelopes[1]['session'], 'f' * 32);
      } finally {
        await svc.dispose();
        await root.delete(recursive: true);
      }
    },
  );
}
