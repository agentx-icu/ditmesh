import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:test/test.dart';

final String kPeer = 'A' * 64;
// AA..AA and nospam 11111111 cancel out in both checksum lanes: 0000.
final String kPeerToxId = '${'A' * 64}${'1' * 8}0000';
final String kSelf = 'F' * 64;

void main() {
  late FakeChatService service;
  late DateTime now;

  setUp(() {
    now = DateTime.utc(2026, 9, 30, 12);
    service = FakeChatService(clock: () => now);
  });

  tearDown(() => service.dispose());

  group('friends', () {
    test('addFriend validates the Tox ID and records the request', () async {
      await expectLater(
        service.addFriend('nope'),
        throwsA(
          isA<ChatException>().having((e) => e.code, 'code', 'invalid_tox_id'),
        ),
      );
      await expectLater(
        service.addFriend('${kSelf}000000000000'),
        throwsA(isA<ChatException>().having((e) => e.code, 'code', 'own_id')),
      );
      await service.addFriend(kPeerToxId.toLowerCase());
      expect(service.outgoingFriendRequests, [kPeerToxId]);
      expect(service.friends.single.publicKey, kPeer);
      expect(service.friends.single.online, isFalse);
      await expectLater(
        service.addFriend(kPeerToxId),
        throwsA(
          isA<ChatException>().having((e) => e.code, 'code', 'already_friend'),
        ),
      );
    });

    test('friendChanges replays the current list to late listeners', () async {
      service.addFakeFriend(Friend(publicKey: kPeer, displayName: 'Ann'));
      final List<Friend> first = await service.friendChanges.first;
      expect(first.single.displayName, 'Ann');
    });

    test('accept / reject friend requests', () async {
      service.receiveFriendRequest(kPeer, message: 'CQ');
      service.receiveFriendRequest('B' * 64);
      expect(service.friendRequests, hasLength(2));
      await service.acceptFriendRequest(kPeer);
      await service.rejectFriendRequest('B' * 64);
      expect(service.friendRequests, isEmpty);
      expect(service.friends.single.publicKey, kPeer);
    });

    test('removeFriend also drops the conversation', () async {
      service.addFakeFriend(Friend(publicKey: kPeer, displayName: 'Ann'));
      await service.sendText(FakeChatService.c2cConversationId(kPeer), 'HI');
      expect(service.conversations, hasLength(1));
      await service.removeFriend(kPeer);
      expect(service.friends, isEmpty);
      expect(service.conversations, isEmpty);
    });
  });

  group('messages', () {
    final String cid = 'c2c_$kPeer';

    setUp(() {
      service.addFakeFriend(Friend(publicKey: kPeer, displayName: 'Ann'));
    });

    test(
      'sendText is pending while the peer is offline, sent when online',
      () async {
        final ChatMessage pending = await service.sendText(cid, 'CQ CQ');
        expect(pending.id, 'msg_1');
        expect(pending.status, MessageStatus.pending);
        expect(pending.isMine, isTrue);
        expect(service.conversations.single.lastMessage?.id, 'msg_1');

        service.setFriendOnline(kPeer, true);
        final ChatMessage sent = await service.sendText(cid, 'DE FAKE');
        expect(sent.status, MessageStatus.sent);
      },
    );

    test(
      'coming online flushes pending rows and emits status events',
      () async {
        final List<ChatMessage> events = <ChatMessage>[];
        final sub = service.messageEvents.listen(events.add);
        final ChatMessage pending = await service.sendText(cid, 'K');
        service.setFriendOnline(kPeer, true);
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();
        expect(events.map((e) => e.status), [
          MessageStatus.pending,
          MessageStatus.sent,
        ]);
        expect(events.last.id, pending.id);
        final List<ChatMessage> history = await service.loadHistory(cid);
        expect(history.single.status, MessageStatus.sent);
        expect(
          service.conversations.single.lastMessage?.status,
          MessageStatus.sent,
        );
      },
    );

    test('sendText enforces the byte budget', () async {
      final FakeChatService small = FakeChatService(maxMessageBytes: 4);
      addTearDown(small.dispose);
      small.addFakeFriend(Friend(publicKey: kPeer, displayName: 'Ann'));
      await expectLater(
        small.sendText(cid, 'ÄÄÄ'), // 6 bytes in UTF-8
        throwsA(
          isA<ChatException>().having(
            (e) => e.code,
            'code',
            'message_too_long',
          ),
        ),
      );
      await small.sendText(cid, 'ÄÄ');
    });

    test('receiveMessage bumps unread; markRead clears it', () async {
      service.receiveMessage(cid, 'HELLO');
      service.receiveMessage(cid, 'WORLD');
      expect(service.conversations.single.unreadCount, 2);
      expect(service.conversations.single.lastMessage?.text, 'WORLD');
      await service.markRead(cid);
      expect(service.conversations.single.unreadCount, 0);
    });

    test('loadHistory pages backwards', () async {
      for (int i = 0; i < 5; i++) {
        now = now.add(const Duration(minutes: 1));
        service.receiveMessage(cid, 'M$i');
      }
      final List<ChatMessage> latest = await service.loadHistory(cid, limit: 2);
      expect(latest.map((m) => m.text), ['M3', 'M4']);
      final List<ChatMessage> older = await service.loadHistory(
        cid,
        limit: 2,
        before: latest.first.timestamp,
      );
      expect(older.map((m) => m.text), ['M1', 'M2']);
    });

    test('pin, draft, clearHistory and delete', () async {
      await service.setDraft(cid, 'CQ DE');
      expect(service.conversations.single.draft, 'CQ DE');
      await service.setPinned(cid, true);
      expect(service.conversations.single.pinned, isTrue);
      service.receiveMessage(cid, 'X');
      await service.clearHistory(cid);
      expect(await service.loadHistory(cid), isEmpty);
      expect(service.conversations.single.lastMessage, isNull);
      expect(service.conversations.single.pinned, isTrue);
      await service.deleteConversation(cid);
      expect(service.conversations, isEmpty);
    });

    test('failMessage emits a failed status', () async {
      final ChatMessage m = await service.sendText(cid, 'K');
      final Future<ChatMessage> next = service.messageEvents.first;
      service.failMessage(m.id);
      expect((await next).status, MessageStatus.failed);
    });
  });

  group('groups', () {
    test('createGroup defaults to NGC with a 64-hex chat id', () async {
      final Group g = await service.createGroup('  Net 40m ');
      expect(g.id, 'tox_1');
      expect(g.name, 'Net 40m');
      expect(g.kind, GroupKind.group);
      expect(g.chatId, hasLength(64));
      expect(FakeChatService.isValidChatId(g.chatId!), isTrue);
      expect(service.conversations.single.id, 'group_tox_1');
      expect(service.conversations.single.kind, ConversationKind.group);
    });

    test('addFakeGroupMember lists the member and bumps the count', () async {
      final Group g = await service.createGroup('Net');
      expect(g.memberCount, 1);
      final List<Group> seen = <Group>[];
      final sub = service.groupChanges.listen((groups) => seen.add(groups.single));
      addTearDown(sub.cancel);
      service.addFakeGroupMember(
        g.id,
        GroupMember(publicKey: 'B' * 64, displayName: 'Bea'),
      );
      // Replacing the same key does not double-count.
      service.addFakeGroupMember(
        g.id,
        GroupMember(publicKey: 'B' * 64, displayName: 'Bea (renamed)'),
      );
      final List<GroupMember> members = await service.groupMembers(g.id);
      expect(members.map((m) => m.displayName), <String>['Me', 'Bea (renamed)']);
      expect(service.groups.single.memberCount, 2);
      await Future<void>.delayed(Duration.zero);
      expect(seen.last.memberCount, 2);
      expect(
        () => service.addFakeGroupMember(
          'nope',
          const GroupMember(publicKey: 'C', displayName: 'C'),
        ),
        throwsA(isA<ChatException>()),
      );
    });

    test('conference groups have no chat id', () async {
      final Group g = await service.createGroup(
        'Old',
        kind: GroupKind.conference,
      );
      expect(g.chatId, isNull);
    });

    test('joinGroup validates the chat id and refuses duplicates', () async {
      await expectLater(
        service.joinGroup('abc'),
        throwsA(
          isA<ChatException>().having((e) => e.code, 'code', 'invalid_chat_id'),
        ),
      );
      await service.joinGroup('c' * 64);
      expect(service.groups.single.chatId, 'C' * 64);
      await expectLater(
        service.joinGroup('C' * 64),
        throwsA(
          isA<ChatException>().having((e) => e.code, 'code', 'already_joined'),
        ),
      );
    });

    test('invites can be accepted or rejected', () async {
      final GroupInvite a = service.receiveGroupInvite(
        fromPublicKey: kPeer,
        groupName: 'A',
      );
      final GroupInvite b = service.receiveGroupInvite(
        fromPublicKey: kPeer,
        groupName: 'B',
        kind: GroupKind.conference,
      );
      expect(service.groupInvites, hasLength(2));
      await service.acceptGroupInvite(a.inviteId);
      await service.rejectGroupInvite(b.inviteId);
      expect(service.groupInvites, isEmpty);
      expect(service.groups.single.name, 'A');
    });

    test(
      'group messages are always sent; leave drops the conversation',
      () async {
        final Group g = await service.createGroup('Net');
        final String cid = FakeChatService.groupConversationId(g.id);
        final ChatMessage m = await service.sendText(cid, 'CQ');
        expect(m.status, MessageStatus.sent);
        service.receiveMessage(cid, 'K', senderId: kPeer, senderName: 'Ann');
        expect(service.conversations.single.unreadCount, 1);
        expect((await service.groupMembers(g.id)).single.isSelf, isTrue);
        await service.leaveGroup(g.id);
        expect(service.groups, isEmpty);
        expect(service.conversations, isEmpty);
      },
    );
  });

  test('dispose closes every stream', () async {
    final Future<void> done = service.conversationChanges.drain<void>();
    await service.dispose();
    await done;
    await service.dispose(); // idempotent
  });
}
