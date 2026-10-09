import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/src/engine/ditmesh_ffi_chat_service.dart';
import 'package:ditmesh_chat/src/chat/recording_metadata.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'helpers/fakes.dart';
import 'rhythm_service_test.dart' show PacketFfi;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'one-sided remote restart with no observed offline refreshes peer session',
    () async {
      final root = await Directory.systemTemp.createTemp('ditmesh_one_sided_');
      final af = PacketFfi()
        ..friends.add((userId: kPeerKey, nick: 'Bob', online: true));
      var bf = PacketFfi()
        ..friends.add((userId: kSelfKey, nick: 'Alice', online: true));
      final a =
          DitmeshFfiChatService(
              historyDirectory: '${root.path}/a',
              ffiForTesting: af,
            )
            ..debugBeginSessionForTest()
            ..debugSetSelfId(kSelfKey);
      var b =
          DitmeshFfiChatService(
              historyDirectory: '${root.path}/b',
              ffiForTesting: bf,
            )
            ..debugBeginSessionForTest()
            ..debugSetSelfId(kPeerKey);
      var ai = 0, bi = 0;
      void deliver() {
        var rounds = 0;
        while (ai < af.packets.length || bi < bf.packets.length) {
          if (++rounds > 20) throw StateError('hello ping-pong');
          while (ai < af.packets.length) {
            b.consumeCustomExtension(kSelfKey, af.packets[ai++]);
          }
          while (bi < bf.packets.length) {
            a.consumeCustomExtension(kPeerKey, bf.packets[bi++]);
          }
        }
      }

      try {
        a.onFriendWireState(kPeerKey, true);
        deliver();
        expect(a.supportsRecordedPeer(kPeerKey), isTrue);
        expect(b.supportsRecordedPeer(kSelfKey), isTrue);
        await b.dispose();
        bf = PacketFfi()
          ..friends.add((userId: kSelfKey, nick: 'Alice', online: true));
        b =
            DitmeshFfiChatService(
                historyDirectory: '${root.path}/b',
                ffiForTesting: bf,
              )
              ..debugBeginSessionForTest()
              ..debugSetSelfId(kPeerKey);
        bi = 0;
        // Alice's online poll never observed Bob's short outage.
        b.onFriendWireState(kSelfKey, true);
        deliver();
        await a.sendTextWithResult(
          kPeerKey,
          'CQ',
          clientMessageID: 'dmr:${'a' * 32}',
          cloudCustomData: RecordingMetadata.encode(
            KeyedRecording(durationsMs: [83]),
          ),
        );
        deliver();
        await Future<void>.delayed(const Duration(milliseconds: 500));
        expect(b.getHistory(kSelfKey).map((row) => row.text), contains('CQ'));
      } finally {
        await a.dispose();
        await b.dispose();
        await root.delete(recursive: true);
      }
    },
  );
}
