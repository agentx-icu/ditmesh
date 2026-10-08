import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:test/test.dart';

void main() {
  final peer = 'A' * 64;
  final c2c = FakeChatService.c2cConversationId(peer);

  test('the fake outbox counts every pending row of ours, once', () async {
    var now = DateTime.utc(2026, 10, 4);
    final chat = FakeChatService(clock: () => now = now.add(const Duration(seconds: 1)));
    addTearDown(chat.dispose);
    chat.addFakeFriend(Friend(publicKey: peer, displayName: 'K1ABC'));
    expect(chat, isA<OutboxInspector>());
    expect(chat.pendingOutbox(), PendingOutboxSummary.empty);

    final first = await chat.sendText(c2c, 'CQ');
    await chat.sendText(c2c, 'DE K1ABC');
    chat.receiveMessage(c2c, 'R R');
    var summary = chat.pendingOutbox(conversationId: c2c)!;
    expect(summary.count, 2);
    expect(summary.oldest, first.timestamp);

    // Delivered rows leave the outbox.
    chat.setFriendOnline(peer, true);
    summary = chat.pendingOutbox(conversationId: c2c)!;
    expect(summary, PendingOutboxSummary.empty);
  });

  test('without a session the outbox is unknown', () async {
    final identity = FakeIdentityService(connectDelay: Duration.zero);
    final chat = FakeChatService(identity: identity);
    addTearDown(() async {
      await chat.dispose();
      await identity.dispose();
    });
    expect(chat.pendingOutbox(), isNull);
  });
}
