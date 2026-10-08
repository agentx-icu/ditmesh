import 'dart:async';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:test/test.dart';

/// The note-to-self conversation of [FakeChatService]: it follows the
/// identity service it is given (the fake identity's `identityChanges` does
/// not replay, so the fake must seed itself from `current`).
void main() {
  late FakeIdentityService identity;
  late FakeChatService chat;

  Conversation? selfRow() =>
      chat.conversations.where((c) => c.isSelf).firstOrNull;

  setUp(() {
    identity = FakeIdentityService(connectDelay: Duration.zero);
  });

  tearDown(() async {
    await chat.dispose();
    await identity.dispose();
  });

  test('no identity service: no self conversation (unchanged default)', () {
    chat = FakeChatService();
    expect(chat.selfConversationId, isNull);
    expect(chat.conversations, isEmpty);
  });

  test('seeded from an identity that already exists', () async {
    final Identity me = await identity.create(displayName: 'Alice');
    await identity.connect();
    chat = FakeChatService(identity: identity);
    expect(chat.selfPublicKey, me.publicKey);
    expect(chat.selfConversationId, 'c2c_${me.publicKey}');
    final Conversation row = selfRow()!;
    expect(row.id, chat.selfConversationId);
    expect(row.title, 'Alice');
    expect(row.kind, ConversationKind.c2c);
  });

  test('follows creation, rename, replacement and removal', () async {
    chat = FakeChatService(identity: identity);
    expect(chat.selfConversationId, isNull, reason: 'first run: no profile');

    final Identity first = await identity.create(displayName: 'Alice');
    await identity.connect();
    await pumpEventQueue();
    expect(chat.selfConversationId, 'c2c_${first.publicKey}');
    expect(selfRow()!.title, 'Alice');

    await identity.updateProfile(displayName: 'Alice K');
    await pumpEventQueue();
    expect(selfRow()!.title, 'Alice K');
    expect(chat.conversations.where((c) => c.isSelf), hasLength(1));

    await identity.deleteIdentity();
    await pumpEventQueue();
    final Identity second = await identity.create(displayName: 'Bob');
    await identity.connect();
    await pumpEventQueue();
    expect(second.publicKey, isNot(first.publicKey));
    expect(chat.selfConversationId, 'c2c_${second.publicKey}');
    expect(
      chat.conversations.map((c) => c.id),
      ['c2c_${second.publicKey}'],
      reason: 'the old identity\'s self row is gone',
    );

    await identity.deleteIdentity();
    await pumpEventQueue();
    expect(chat.selfConversationId, isNull);
    expect(chat.conversations, isEmpty);
  });

  test(
    'deleting the identity erases its notes; a restore starts empty',
    () async {
      await identity.create(displayName: 'Alice');
      await identity.connect();
      final backup = await identity.exportBackup();
      chat = FakeChatService(identity: identity);
      final String id = chat.selfConversationId!;
      await chat.sendText(id, 'written after the backup');

      await identity.deleteIdentity();
      await pumpEventQueue();
      expect(chat.selfConversationId, isNull);

      await identity.importBackup(backup);
      await identity.connect();
      await pumpEventQueue();
      expect(chat.selfConversationId, id, reason: 'same key restored');
      expect(await chat.loadHistory(id), isEmpty);
      expect(selfRow()!.lastMessage, isNull);
    },
  );

  test('sending to self is delivered at once and never pending', () async {
    await identity.create(displayName: 'Alice');
    await identity.connect();
    chat = FakeChatService(identity: identity);
    final String id = chat.selfConversationId!;
    final List<ChatMessage> events = [];
    final StreamSubscription<ChatMessage> sub = chat.messageEvents.listen(
      events.add,
    );

    final ChatMessage sent = await chat.sendText(id, 'CQ practice');
    await pumpEventQueue();
    await sub.cancel();

    expect(sent.status, MessageStatus.sent);
    expect(sent.isMine, isTrue);
    expect(events.single.id, sent.id);
    expect(selfRow()!.lastMessage?.text, 'CQ practice');
    expect((await chat.loadHistory(id)).single.text, 'CQ practice');
  });

  test('deleting it is refused and changes nothing', () async {
    await identity.create(displayName: 'Alice');
    await identity.connect();
    chat = FakeChatService(identity: identity);
    final String id = chat.selfConversationId!;
    await chat.sendText(id, 'note');
    await chat.setPinned(id, true);
    await chat.setDraft(id, 'half');
    final List<List<Conversation>> published = [];
    final StreamSubscription<List<Conversation>> sub = chat.conversationChanges
        .listen(published.add);
    await pumpEventQueue();
    published.clear(); // the subject replays the latest list on subscribe

    await expectLater(
      chat.deleteConversation(id),
      throwsA(
        isA<ChatException>().having((e) => e.code, 'code', 'self_conversation'),
      ),
    );
    await pumpEventQueue();
    await sub.cancel();

    expect(published, isEmpty, reason: 'nothing was republished');
    final Conversation row = selfRow()!;
    expect(row.lastMessage?.text, 'note');
    expect(row.pinned, isTrue);
    expect(row.draft, 'half');
    expect(row.title, 'Alice');
    expect((await chat.loadHistory(id)).single.text, 'note');
  });

  test('clearHistory still empties it explicitly; the row stays', () async {
    await identity.create(displayName: 'Alice');
    await identity.connect();
    chat = FakeChatService(identity: identity);
    final String id = chat.selfConversationId!;
    await chat.sendText(id, 'note');
    await chat.setPinned(id, true);

    await chat.clearHistory(id);

    final Conversation row = selfRow()!;
    expect(row.isSelf, isTrue, reason: 'clearHistory keeps the flag');
    expect(row.lastMessage, isNull);
    expect(row.pinned, isTrue);
    expect(await chat.loadHistory(id), isEmpty);
  });
}
