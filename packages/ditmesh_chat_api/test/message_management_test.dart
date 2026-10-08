import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:test/test.dart';

void main() {
  const peer =
      'CDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCDCD';
  const cid = 'c2c_$peer';
  final t0 = DateTime.utc(2026, 10, 3, 12);

  late FakeChatService chat;
  late DateTime now;

  setUp(() {
    now = t0;
    chat = FakeChatService(clock: () => now)
      ..addFakeFriend(const Friend(publicKey: peer, displayName: 'Bob'));
  });

  tearDown(() => chat.dispose());

  group('searchMessages', () {
    test('a fired cancel token aborts the search', () async {
      chat.receiveMessage(cid, 'CQ');
      final cancel = MessageSearchCancel()..cancel();
      await expectLater(
        chat.searchMessages(cid, const MessageSearchQuery(), cancel: cancel),
        throwsA(isA<MessageSearchCancelled>()),
      );
    });

    test('matches the whole history case-insensitively, newest first', () {
      for (var i = 0; i < 120; i++) {
        chat.receiveMessage(
          cid,
          i.isEven ? 'cq de k1abc $i' : 'other $i',
          timestamp: t0.add(Duration(seconds: i)),
        );
      }
      return chat
          .searchMessages(
            cid,
            const MessageSearchQuery(text: 'CQ DE'),
            limit: 100,
          )
          .then((page) {
            expect(page.results, hasLength(60));
            expect(page.results.first.text, 'cq de k1abc 118');
            expect(page.results.last.text, 'cq de k1abc 0');
            expect(page.hasMore, isFalse);
          });
    });

    test('equal timestamps page without loss or duplicates', () async {
      for (var i = 0; i < 7; i++) {
        chat.receiveMessage(cid, 'same $i', timestamp: t0);
      }
      final seen = <String>[];
      MessageSearchCursor? cursor;
      do {
        final page = await chat.searchMessages(
          cid,
          const MessageSearchQuery(text: 'same'),
          cursor: cursor,
          limit: 3,
        );
        seen.addAll(page.results.map((m) => m.id));
        cursor = page.next;
      } while (cursor != null);
      expect(seen, hasLength(7));
      expect(seen.toSet(), hasLength(7));
      // Newest-first tie-break: id descending.
      expect(seen, [...seen]..sort((a, b) => b.compareTo(a)));
    });

    test('sender and date filters', () async {
      chat.receiveMessage(cid, 'hi', timestamp: t0);
      now = t0.add(const Duration(hours: 1));
      await chat.sendText(cid, 'hi back');
      final mine = await chat.searchMessages(
        cid,
        MessageSearchQuery(senderId: chat.selfPublicKey.toLowerCase()),
      );
      expect(mine.results.map((m) => m.text), ['hi back']);
      final early = await chat.searchMessages(
        cid,
        MessageSearchQuery(to: t0.add(const Duration(minutes: 1))),
      );
      expect(early.results.map((m) => m.text), ['hi']);
      final late = await chat.searchMessages(
        cid,
        MessageSearchQuery(
          text: 'HI',
          from: t0.add(const Duration(minutes: 1)),
        ),
      );
      expect(late.results.map((m) => m.text), ['hi back']);
    });

    test('profile isolation: other conversations never leak in', () async {
      chat.receiveMessage(cid, 'needle');
      final other = await chat.searchMessages(
        'c2c_${'E' * 64}',
        const MessageSearchQuery(text: 'needle'),
      );
      expect(other.results, isEmpty);
    });
  });

  test('loadAround returns the neighbourhood oldest first', () async {
    final ids = <String>[];
    for (var i = 0; i < 100; i++) {
      ids.add(
        chat
            .receiveMessage(cid, 'm$i', timestamp: t0.add(Duration(seconds: i)))
            .id,
      );
    }
    final rows = await chat.loadAround(cid, ids[10], before: 3, after: 2);
    expect(rows.map((m) => m.text), ['m7', 'm8', 'm9', 'm10', 'm11', 'm12']);
    expect(await chat.loadAround(cid, 'missing'), isEmpty);
    final edge = await chat.loadAround(cid, ids[0], before: 5, after: 1);
    expect(edge.map((m) => m.text), ['m0', 'm1']);
  });

  group('send control', () {
    test('cancel a pending message; it stays cancelled when the peer '
        'comes online', () async {
      final events = <ChatMessage>[];
      final sub = chat.messageEvents.listen(events.add);
      final m = await chat.sendText(cid, 'queued');
      expect(m.status, MessageStatus.pending);
      expect(
        await chat.cancelPendingMessage(cid, m.id),
        MessageActionResult.success,
      );
      chat.setFriendOnline(peer, true);
      final rows = await chat.loadHistory(cid);
      expect(rows.single.status, MessageStatus.cancelled);
      await Future<void>.delayed(Duration.zero);
      expect(events.last.status, MessageStatus.cancelled);
      await sub.cancel();
    });

    test(
      'cancel after the transport claimed it reports stateChanged',
      () async {
        final m = await chat.sendText(cid, 'queued');
        chat.claimMessage(m.id);
        expect(
          await chat.cancelPendingMessage(cid, m.id),
          MessageActionResult.stateChanged,
        );
      },
    );

    test('retry keeps one row and only applies to failed messages', () async {
      final m = await chat.sendText(cid, 'oops');
      expect(
        await chat.retryMessage(cid, m.id),
        MessageActionResult.stateChanged,
      );
      chat.failMessage(m.id);
      chat.setFriendOnline(peer, true);
      expect(await chat.retryMessage(cid, m.id), MessageActionResult.success);
      expect(
        await chat.retryMessage(cid, m.id),
        MessageActionResult.stateChanged,
      );
      final rows = await chat.loadHistory(cid);
      expect(rows, hasLength(1));
      expect(rows.single.status, MessageStatus.sent);
    });

    test('a retry to a disconnected group stays pending', () async {
      final g = chat.addFakeGroup(
        const Group(id: 'tox_9', name: 'Net', kind: GroupKind.group),
      );
      final gid = 'group_${g.id}';
      chat.setGroupConnected(g.id, false);
      final m = await chat.sendText(gid, 'QRL?');
      chat.failMessage(m.id);
      expect(await chat.retryMessage(gid, m.id), MessageActionResult.success);
      expect(
        (await chat.loadHistory(gid)).single.status,
        MessageStatus.pending,
      );
      chat.setGroupConnected(g.id, true);
      expect((await chat.loadHistory(gid)).single.status, MessageStatus.sent);
    });

    test('every operation needs a session, like history', () async {
      final identity = FakeIdentityService();
      await identity.create(displayName: 'Me');
      final own = FakeChatService(identity: identity)
        ..addFakeFriend(const Friend(publicKey: peer, displayName: 'Bob'));
      addTearDown(own.dispose);
      await identity.connect();
      final m = await own.sendText(cid, 'queued');
      await identity.disconnect();
      final notConnected = throwsA(
        isA<ChatException>().having((e) => e.code, 'code', 'not_connected'),
      );
      await expectLater(
        own.searchMessages(cid, const MessageSearchQuery()),
        notConnected,
      );
      await expectLater(own.loadAround(cid, m.id), notConnected);
      await expectLater(own.retryMessage(cid, m.id), notConnected);
      await expectLater(own.cancelPendingMessage(cid, m.id), notConnected);
    });

    test('note-to-self rows have no send control', () async {
      final identity = FakeIdentityService();
      await identity.create(displayName: 'Me');
      final own = FakeChatService(identity: identity);
      await identity.connect();
      addTearDown(own.dispose);
      final m = await own.sendText(own.selfConversationId!, 'note');
      expect(
        await own.retryMessage(own.selfConversationId!, m.id),
        MessageActionResult.unavailable,
      );
      expect(
        await own.cancelPendingMessage(own.selfConversationId!, m.id),
        MessageActionResult.unavailable,
      );
    });

    test('received messages and unknown ids are unavailable', () async {
      final r = chat.receiveMessage(cid, 'hello');
      expect(
        await chat.retryMessage(cid, r.id),
        MessageActionResult.unavailable,
      );
      expect(
        await chat.cancelPendingMessage(cid, r.id),
        MessageActionResult.unavailable,
      );
      expect(
        await chat.cancelPendingMessage(cid, 'nope'),
        MessageActionResult.unavailable,
      );
    });
  });
}
