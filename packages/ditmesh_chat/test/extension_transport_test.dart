import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tim2tox_dart/models/chat_message.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';
import 'helpers/fakes.dart';

class ExtensionService extends FfiChatService {
  ExtensionService(Directory root)
    : super(historyDirectory: root.path, ffiForTesting: FakeTim2ToxFfi()) {
    debugBeginSessionForTest();
    debugSetSelfId(kSelfKey);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'late group timing emits an explicit update with the original identity',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'ditmesh_group_update_',
      );
      final svc = ExtensionService(root);
      final events = <ChatMessage>[];
      final subscription = svc.messages.listen(events.add);
      try {
        svc.ingestInboundGroupText(
          gid: 'tox_1',
          from: kPeerKey,
          text: 'CQ',
          pseudoMsgId: 42,
          forceEmit: true,
        );
        await pumpEventQueue();
        final alias = FfiChatService.groupMessageAlias(
          groupId: 'tox_1',
          senderPk: kPeerKey,
          pseudoMsgId: 42,
        );
        await svc.attachExtensionMetadata(
          'tox_1',
          kPeerKey,
          alias,
          '{"ditmeshRhythm":{"version":1,"durationsMs":[80]}}',
        );
        await pumpEventQueue();
        expect(events, hasLength(2));
        expect(events.last.msgID, events.first.msgID);
        expect(isExtensionMetadataUpdate(events.first), isFalse);
        expect(isExtensionMetadataUpdate(events.last), isTrue);
        expect(svc.getUnreadOf('tox_1'), 1);
      } finally {
        await subscription.cancel();
        await svc.dispose();
        await root.delete(recursive: true);
      }
    },
  );

  test(
    'extension text identity survives duplicate and reload without unread pollution',
    () async {
      final root = await Directory.systemTemp.createTemp('ditmesh_extension_');
      final svc = ExtensionService(root);
      try {
        expect(
          await svc.receiveExtensionText(
            kPeerKey,
            'dmr:abc',
            'CQ',
            metadata: '{"ditmeshRhythm":{"version":1,"durationsMs":[80]}}',
          ),
          isTrue,
        );
        expect(
          await svc.receiveExtensionText(kPeerKey, 'dmr:abc', 'CQ'),
          isFalse,
        );
        expect(svc.getHistory(kPeerKey), hasLength(1));
        expect(
          svc.getHistory(kPeerKey).single.contentKind,
          ChatMessageContentKind.normal,
        );
        expect(svc.getUnreadOf(kPeerKey), 1);
        expect(
          await svc.receiveExtensionText(kPeerKey, 'dmr:def', 'CQ'),
          isTrue,
        );
        expect(
          svc.getHistory(kPeerKey),
          hasLength(2),
          reason: 'different explicit IDs must retain repeated identical texts',
        );
        await svc.messageHistoryPersistence.flushPendingSaves();
        final reopened = ExtensionService(root);
        try {
          await reopened.messageHistoryPersistence.loadHistory(kPeerKey);
          expect(
            await reopened.receiveExtensionText(kPeerKey, 'dmr:abc', 'CQ'),
            isFalse,
          );
          expect(reopened.getHistory(kPeerKey), hasLength(2));
        } finally {
          await reopened.dispose();
        }
      } finally {
        await svc.dispose();
        await root.delete(recursive: true);
      }
    },
  );
}
