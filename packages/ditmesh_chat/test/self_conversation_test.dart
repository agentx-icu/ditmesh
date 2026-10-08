import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import 'helpers/fakes.dart';

/// The note-to-self conversation over the real `FfiChatService` (binding
/// fake underneath): always listed while connected, titled with the own
/// display name, and everything sent to it stays local — no native send, no
/// offline queue (Tim2Tox's self-conversation guard).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');

  late Directory tempRoot;
  late FakeTim2ToxFfi ffi;
  late HoldingKeyValueStore store;
  late FfiChatService engineService;
  late FakeChatEngine engine;
  late FakeIdentityService identity;
  late Tim2ToxChatService chat;

  const selfId = 'c2c_$kSelfKey';

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ditmesh_self_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (_) async => tempRoot.path);
    ffi = FakeTim2ToxFfi();
    store = HoldingKeyValueStore();
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

  Future<void> bind([FfiChatService? svc]) async {
    engine.bind(svc ?? engineService);
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  Conversation? selfRow() =>
      chat.conversations.where((c) => c.isSelf).firstOrNull;

  test('the id comes from the identity; the row from the session', () async {
    expect(chat.selfConversationId, selfId);
    expect(chat.conversations, isEmpty, reason: 'not connected yet');

    await bind();
    final Conversation row = selfRow()!;
    expect(row.id, selfId);
    expect(row.kind, ConversationKind.c2c);
    expect(row.title, 'me');
    expect(row.unreadCount, 0);

    engine.bind(null);
    await pumpEventQueue();
    expect(chat.conversations, isEmpty);
    expect(chat.selfConversationId, selfId, reason: 'Contacts still shows it');
  });

  test('a note to self is stored, delivered at once, and never sent', () async {
    await bind();
    final List<ChatMessage> events = [];
    final StreamSubscription<ChatMessage> sub = chat.messageEvents.listen(
      events.add,
    );

    final ChatMessage row = await chat.sendText(selfId, 'CQ CQ practice');
    await pumpEventQueue();
    await sub.cancel();

    expect(row.status, MessageStatus.sent);
    expect(row.isMine, isTrue);
    expect(row.conversationId, selfId);
    expect(events.map((e) => e.conversationId), everyElement(selfId));
    expect(events.map((e) => e.status), everyElement(MessageStatus.sent));
    expect(ffi.sentTextPeers, isEmpty, reason: 'nothing reaches native');
    expect(
      engineService.offlineMessageQueuePersistence.getMessages(kSelfKey),
      isEmpty,
      reason: 'self is not an offline friend',
    );
    expect(selfRow()!.lastMessage?.text, 'CQ CQ practice');
    expect((await chat.loadHistory(selfId)).single.text, 'CQ CQ practice');
  });

  test('a friend who is online still goes to the wire', () async {
    ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: true));
    await bind();
    final ChatMessage row = await chat.sendText('c2c_$kPeerKey', 'hi');
    expect(row.status, MessageStatus.sent);
    expect(ffi.sentTextPeers, [kPeerKey]);
  });

  final Matcher refused = throwsA(
    isA<ChatException>().having((e) => e.code, 'code', 'self_conversation'),
  );

  test('deleting it is refused and changes nothing', () async {
    await bind();
    await chat.sendText(selfId, 'note');
    await chat.setPinned(selfId, true);
    await chat.setDraft(selfId, 'half');

    await expectLater(chat.deleteConversation(selfId), refused);
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final Conversation row = selfRow()!;
    expect(row.lastMessage?.text, 'note');
    expect(row.draft, 'half');
    expect(row.pinned, isTrue);
    expect((await chat.loadHistory(selfId)).single.text, 'note');
  });

  test(
    'deleting it is refused offline too, before the session check',
    () async {
      await expectLater(chat.deleteConversation(selfId), refused);
    },
  );

  test('clearHistory still empties it explicitly; the row stays', () async {
    await bind();
    await chat.sendText(selfId, 'note');
    await chat.setPinned(selfId, true);

    await chat.clearHistory(selfId);
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final Conversation row = selfRow()!;
    expect(row.isSelf, isTrue);
    expect(row.lastMessage, isNull);
    expect(row.pinned, isTrue);
    expect(await chat.loadHistory(selfId), isEmpty);
  });

  test('renaming the identity retitles it', () async {
    await bind();
    await identity.updateProfile(displayName: 'Alice');
    await pumpEventQueue();
    expect(selfRow()!.title, 'Alice');
  });

  test('notes survive a restart of the session', () async {
    await bind();
    await chat.sendText(selfId, 'keep me');
    await engineService.flushPendingHistory();
    engine.bind(null);
    await engineService.dispose();

    engineService = await newEngineService(ffi, store, tempRoot, 'identity');
    await bind(engineService);
    final List<ChatMessage> history = await chat.loadHistory(selfId);
    expect(history.map((m) => m.text), ['keep me']);
    expect(history.single.status, MessageStatus.sent);
    expect(selfRow()!.lastMessage?.text, 'keep me');
  });
}
