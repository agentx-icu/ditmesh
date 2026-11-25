import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tim2tox_dart/models/chat_message.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';
import 'helpers/fakes.dart';

class _PollingFfi extends FakeTim2ToxFfi {
  final events = <String>[];

  @override
  int Function(int, ffi.Pointer<ffi.Int8>, int) get pollText =>
      (_, buffer, capacity) {
        if (events.isEmpty) return 0;
        final bytes = utf8.encode(events.removeAt(0));
        final out = buffer.cast<ffi.Uint8>().asTypedList(capacity);
        out.setAll(0, bytes);
        out[bytes.length] = 0;
        return bytes.length;
      };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late _PollingFfi native;
  late FfiChatService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('inbound-identities-');
    native = _PollingFfi();
    service = FfiChatService(
      historyDirectory: root.path,
      ffiForTesting: native,
    );
    service.debugBeginSessionForTest();
    service.debugSetSelfId(kSelfKey);
  });

  tearDown(() async {
    await service.dispose();
    await root.delete(recursive: true);
  });

  test('two independent equal plain poll events remain two messages', () async {
    native.events.addAll(['c2c:$kPeerKey:ok', 'c2c:$kPeerKey:ok']);
    await service.startPolling();
    service.triggerPollOnce();
    await pumpEventQueue();
    expect(service.getHistory(kPeerKey), hasLength(2));
    expect(service.getUnreadOf(kPeerKey), 2);
  });

  test('two independent equal action events remain two messages', () {
    for (var i = 0; i < 2; i++) {
      expect(service.ingestActionEvent('c2caction:$kPeerKey:waves'), isTrue);
    }
    expect(service.getHistory(kPeerKey), hasLength(2));
    expect(service.getUnreadOf(kPeerKey), 2);
  });

  test('two equal conference messages without wire ids remain distinct', () {
    for (var i = 0; i < 2; i++) {
      service.ingestInboundGroupText(gid: 'tox_1', from: kPeerKey, text: 'CQ');
    }
    expect(service.getHistory('tox_1'), hasLength(2));
    expect(service.getUnreadOf('tox_1'), 2);
  });

  test('a native copy is claimed by only one equal plain poll event', () async {
    await service.messageHistoryPersistence.appendHistory(
      kPeerKey,
      ChatMessage(
        text: 'ok',
        fromUserId: kPeerKey,
        isSelf: false,
        timestamp: DateTime.now(),
        msgID: 'msg_1_2_3',
      ),
    );
    native.events.addAll(['c2c:$kPeerKey:ok', 'c2c:$kPeerKey:ok']);
    await service.startPolling();
    service.triggerPollOnce();
    await pumpEventQueue();
    final history = service.getHistory(kPeerKey);
    expect(history, hasLength(2));
    expect(history.first.msgID, 'msg_1_2_3');
    expect(history.first.altMsgIds, hasLength(1));
  });

  test('a native conference copy is claimed by only one poll event', () async {
    await service.messageHistoryPersistence.appendHistory(
      'tox_1',
      ChatMessage(
        text: 'CQ',
        fromUserId: kPeerKey,
        isSelf: false,
        timestamp: DateTime.now(),
        msgID: 'msg_1_2_3',
        groupId: 'tox_1',
      ),
    );
    for (var i = 0; i < 2; i++) {
      service.ingestInboundGroupText(gid: 'tox_1', from: kPeerKey, text: 'CQ');
    }
    final history = service.getHistory('tox_1');
    expect(history, hasLength(2));
    expect(history.first.msgID, 'msg_1_2_3');
    expect(history.first.altMsgIds, hasLength(1));
  });

  test('a repeated group wire identity still resolves to one row', () {
    for (var i = 0; i < 2; i++) {
      service.ingestInboundGroupText(
        gid: 'tox_1',
        from: kPeerKey,
        text: 'CQ',
        pseudoMsgId: 42,
      );
    }
    expect(service.getHistory('tox_1'), hasLength(1));
    expect(service.getUnreadOf('tox_1'), 1);
  });
}
