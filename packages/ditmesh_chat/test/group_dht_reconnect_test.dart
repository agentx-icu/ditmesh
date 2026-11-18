import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';
import 'package:tim2tox_dart/utils/offline_message_queue_persistence.dart';

import 'helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const groupId = 'tox_7';
  late _GroupFfi native;
  late FfiChatService chat;

  setUp(() async {
    final root = await Directory.systemTemp.createTemp('ditmesh_group_dht_');
    addTearDown(() => root.delete(recursive: true));
    native = _GroupFfi();
    chat =
        FfiChatService(
            historyDirectory: root.path,
            offlineMessageQueuePersistence: OfflineMessageQueuePersistence(
              queueFilePath: '${root.path}/queue.json',
            ),
            ffiForTesting: native,
          )
          ..debugBeginSessionForTest()
          ..debugSetSelfId(kSelfKey)
          ..debugAddKnownGroupForTest(groupId)
          ..debugSetConnected(false);
    addTearDown(chat.dispose);
  });

  test('confirmed NGC drains its queue and sends with DHT offline', () async {
    final queued = await chat.sendGroupTextWithResult(groupId, 'queued');
    expect(queued.isPending, isTrue);
    expect(native.sent, isEmpty);

    final updates = chat.messages.where((row) => row.msgID == queued.msgID);
    final states = <bool>[];
    final subscription = updates.listen((row) => states.add(row.isPending));
    addTearDown(subscription.cancel);

    native.wireReady = 1;
    await chat.retryPendingGroupMessages(groupId);
    await chat.retryPendingGroupMessages(groupId);
    final fresh = await chat.sendGroupTextWithResult(groupId, 'fresh');

    expect(chat.isConnected, isFalse);
    expect(native.sent, ['queued', 'fresh']);
    expect(fresh.isPending, isFalse);
    expect(states, [false]);
    expect(
      chat
          .getHistory(groupId)
          .singleWhere((row) => row.msgID == queued.msgID)
          .isPending,
      isFalse,
    );
  });

  test('legacy or unconfirmed groups still queue with DHT offline', () async {
    for (final (ready, kind) in [(1, 'conference'), (1, null), (-1, 'group')]) {
      native
        ..wireReady = ready
        ..kind = kind;
      final row = await chat.sendGroupTextWithResult(groupId, 'queued');
      expect(row.isPending, isTrue, reason: 'wire=$ready kind=$kind');
      await chat.retryPendingGroupMessages(groupId);
      expect(native.sent, isEmpty);
    }
  });
}

class _GroupFfi extends FakeTim2ToxFfi {
  int wireReady = 0;
  String? kind = 'group';
  final sent = <String>[];

  @override
  int Function(ffi.Pointer<Utf8>) get groupWireReady =>
      (_) => wireReady;

  @override
  int Function(int, ffi.Pointer<Utf8>, ffi.Pointer<ffi.Int8>, int)
  get getGroupTypeFromStorageNative => (_, _, output, capacity) {
    final type = kind;
    if (type == null) return 0;
    final bytes = output.cast<ffi.Uint8>().asTypedList(capacity);
    bytes.setRange(0, type.length, type.codeUnits);
    bytes[type.length] = 0;
    return 1;
  };

  @override
  int Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>) get sendGroupText =>
      (_, text) {
        sent.add(text.toDartString());
        return 1;
      };
}
