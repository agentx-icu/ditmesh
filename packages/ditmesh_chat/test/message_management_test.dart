import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import 'helpers/fakes.dart';

/// F07 over the real `FfiChatService` Dart layer (history, offline queue,
/// drain) and a binding fake: whole-history search, deep jumps, and
/// single-message cancel / retry. Nothing here needs the native library.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  const cid = 'c2c_$kPeerKey';

  late Directory tempRoot;
  late FakeTim2ToxFfi ffi;
  late FfiChatService engineService;
  late FakeChatEngine engine;
  late FakeIdentityService identity;
  late Tim2ToxChatService chat;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ditmesh_f07_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (_) async => tempRoot.path);
    ffi = FakeTim2ToxFfi()
      ..friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
    final store = HoldingKeyValueStore();
    engineService = await newEngineService(ffi, store, tempRoot, 'identity');
    engine = FakeChatEngine();
    identity = FakeIdentityService.withProfile(
      identity: const Identity(toxId: kSelfToxId, displayName: 'me'),
      connectDelay: Duration.zero,
    );
    await identity.open();
    chat = Tim2ToxChatService(
      engine: engine,
      identity: identity,
      store: store,
      pollInterval: const Duration(milliseconds: 50),
    );
    engine.bind(engineService);
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 80));
  });

  tearDown(() async {
    await chat.dispose();
    await engine.dispose();
    await identity.dispose();
    await engineService.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, null);
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  /// Online for the drain, without the native came-online side effects.
  Future<void> peerOnline() async {
    engineService.debugSetFriendOnline(kPeerKey, true);
    await engineService.getFriendList();
  }

  test('search reaches rows beyond the loaded page, newest first', () async {
    for (var i = 0; i < 60; i++) {
      await chat.sendText(cid, i.isEven ? 'CQ test $i' : 'other $i');
    }
    expect(await chat.loadHistory(cid), hasLength(50));
    final seen = <String>[];
    MessageSearchCursor? cursor;
    do {
      final page = await chat.searchMessages(
        cid,
        const MessageSearchQuery(text: 'cq TEST'),
        cursor: cursor,
        limit: 7,
      );
      seen.addAll(page.results.map((m) => m.text));
      cursor = page.next;
    } while (cursor != null);
    expect(seen, hasLength(30));
    expect(seen.toSet(), hasLength(30));
    expect(seen.first, 'CQ test 58');
    expect(seen.last, 'CQ test 0');
  });

  test('search and jumps skip non-text rows (as history does)', () async {
    final sent = await chat.sendText(cid, 'CQ text');
    // A custom payload a toxee peer pushed: stored in the engine's
    // history, but not a chat message.
    expect(
      engineService.ingestInboundC2cCustom(from: kPeerKey, data: 'CQ custom'),
      isTrue,
    );
    expect(
      engineService.getHistory(kPeerKey).map((m) => m.text),
      contains('CQ custom'),
    );
    final page = await chat.searchMessages(
      cid,
      const MessageSearchQuery(text: 'cq'),
    );
    expect(page.results.map((m) => m.id), [sent.id]);
    final around = await chat.loadAround(cid, sent.id);
    expect(around.map((m) => m.id), [sent.id]);
  });

  test('a cancelled search stops instead of returning results', () async {
    await chat.sendText(cid, 'CQ');
    final cancel = MessageSearchCancel()..cancel();
    await expectLater(
      chat.searchMessages(
        cid,
        const MessageSearchQuery(text: 'cq'),
        cancel: cancel,
      ),
      throwsA(isA<MessageSearchCancelled>()),
    );
  });

  test('loadAround finds an old row for a deep jump', () async {
    final rows = <ChatMessage>[];
    for (var i = 0; i < 60; i++) {
      rows.add(await chat.sendText(cid, 'm$i'));
    }
    final around = await chat.loadAround(cid, rows[3].id, before: 2, after: 2);
    expect(around.map((m) => m.text), ['m1', 'm2', 'm3', 'm4', 'm5']);
    expect(await chat.loadAround(cid, 'missing'), isEmpty);
  });

  test('cancel a queued message: cancelled event, never sent', () async {
    expect(chat.supportsSendControl, isTrue);
    final events = <ChatMessage>[];
    final sub = chat.messageEvents.listen(events.add);
    final row = await chat.sendText(cid, 'cancel me');
    expect(row.status, MessageStatus.pending);
    expect(
      await chat.cancelPendingMessage(cid, row.id),
      MessageActionResult.success,
    );
    await pumpEventQueue();
    expect(events.last.status, MessageStatus.cancelled);
    expect(
      (await chat.loadHistory(cid)).single.status,
      MessageStatus.cancelled,
    );
    await peerOnline();
    await engineService.retryPendingC2cMessages(kPeerKey);
    expect(ffi.sentTextPeers, isEmpty);
    expect(
      await chat.cancelPendingMessage(cid, row.id),
      MessageActionResult.stateChanged,
      reason: 'our row moved on',
    );
    await sub.cancel();
  });

  test(
    'a failed drain surfaces failed; retry sends it under the same row',
    () async {
      final row = await chat.sendText(cid, 'retry me');
      await peerOnline();
      ffi.failSends = true;
      await engineService.retryPendingC2cMessages(kPeerKey);
      expect((await chat.loadHistory(cid)).single.status, MessageStatus.failed);

      ffi.failSends = false;
      expect(await chat.retryMessage(cid, row.id), MessageActionResult.success);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final rows = await chat.loadHistory(cid);
      expect(rows, hasLength(1), reason: 'no second bubble');
      expect(rows.single.id, row.id);
      expect(rows.single.status, MessageStatus.sent);
      expect(ffi.sentTextPeers, [kPeerKey]);
      expect(
        await chat.retryMessage(cid, row.id),
        MessageActionResult.stateChanged,
      );
    },
  );

  test('note-to-self and received rows have no send control', () async {
    final self = chat.selfConversationId!;
    final note = await chat.sendText(self, 'note');
    expect(
      await chat.cancelPendingMessage(self, note.id),
      MessageActionResult.unavailable,
    );
    expect(
      await chat.retryMessage(cid, 'unknown'),
      MessageActionResult.unavailable,
    );
  });
}
