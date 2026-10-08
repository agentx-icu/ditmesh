import 'dart:async';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:test/test.dart';

/// The fake follows the backend's session and replacement rules, so widget
/// tests on the fake see what the Tox backend would do.
void main() {
  late FakeIdentityService identity;
  late FakeChatService chat;
  final String peer = 'A' * 64;
  final String peerConv = 'c2c_$peer';

  Matcher throwsCode(String code) =>
      throwsA(isA<ChatException>().having((e) => e.code, 'code', code));

  setUp(() async {
    identity = FakeIdentityService(connectDelay: Duration.zero);
    await identity.create(displayName: 'Me');
    chat = FakeChatService(identity: identity);
  });

  tearDown(() async {
    await chat.dispose();
    await identity.dispose();
  });

  test('without a session: reads throw not_connected, pin/draft work', () async {
    chat.addFakeFriend(Friend(publicKey: peer, displayName: 'Ann'));
    await expectLater(chat.loadHistory(peerConv), throwsCode('not_connected'));
    await expectLater(chat.sendText(peerConv, 'CQ'), throwsCode('not_connected'));
    await expectLater(chat.markRead(peerConv), throwsCode('not_connected'));
    await chat.setDraft(peerConv, 'half');
    await chat.setPinned(peerConv, true);
    expect(chat.conversations.where((c) => c.isSelf), isEmpty);

    await identity.connect();
    await pumpEventQueue();
    expect(await chat.loadHistory(peerConv), isEmpty);
    expect(chat.conversations.where((c) => c.isSelf), hasLength(1));
  });

  test('every friend has a row; a deleted one returns with a message', () async {
    await identity.connect();
    chat.addFakeFriend(Friend(publicKey: peer, displayName: 'Ann'));
    expect(chat.conversations.map((c) => c.id), contains(peerConv));
    await chat.deleteConversation(peerConv);
    expect(chat.conversations.map((c) => c.id), isNot(contains(peerConv)));
    chat.receiveMessage(peerConv, 'CQ');
    expect(chat.conversations.map((c) => c.id), contains(peerConv));
  });

  test('deleting or replacing the identity empties the chat state', () async {
    await identity.connect();
    chat
      ..addFakeFriend(Friend(publicKey: peer, displayName: 'Ann'))
      ..addFakeGroup(const Group(id: 'tox_9', name: 'Net', kind: GroupKind.group))
      ..receiveFriendRequest('B' * 64);
    final backup = await identity.exportBackup();
    await identity.importBackup(backup); // same key
    await pumpEventQueue();
    expect(chat.friends, isEmpty);
    expect(chat.groups, isEmpty);
    expect(chat.friendRequests, isEmpty);
  });

  test('group sends stay pending while the group is disconnected', () async {
    await identity.connect();
    final Group g = chat.addFakeGroup(
      const Group(id: 'tox_9', name: 'Net', kind: GroupKind.group),
    );
    chat.setGroupConnected(g.id, false);
    final ChatMessage sent = await chat.sendText('group_${g.id}', 'QRL?');
    expect(sent.status, MessageStatus.pending);
    chat.setGroupConnected(g.id, true);
    final history = await chat.loadHistory('group_${g.id}');
    expect(history.single.status, MessageStatus.sent);
  });

  test('error codes match the backend', () async {
    await identity.connect();
    await expectLater(chat.createGroup('  '), throwsCode('invalid_name'));
    chat.addFakeFriend(Friend(publicKey: peer, displayName: 'Ann'));
    await expectLater(chat.sendText(peerConv, '   '), throwsCode('empty_message'));
    await expectLater(
      chat.addFriend('${'A' * 64}${'1' * 8}FFFF'),
      throwsCode('invalid_tox_id'),
    );
    await chat.rejectFriendRequest('C' * 64); // unknown: a no-op
  });

  test('use after dispose is not_connected, not a StateError', () async {
    await identity.connect();
    chat.addFakeFriend(Friend(publicKey: peer, displayName: 'Ann'));
    await chat.dispose();
    await expectLater(chat.sendText(peerConv, 'CQ'), throwsCode('not_connected'));
  });

  test('without a session every list is empty, and comes back after', () async {
    await identity.connect();
    chat
      ..addFakeFriend(Friend(publicKey: peer, displayName: 'Ann'))
      ..addFakeGroup(const Group(id: 'tox_9', name: 'Net', kind: GroupKind.group))
      ..receiveFriendRequest('B' * 64);
    await identity.disconnect();
    await pumpEventQueue();
    expect(chat.friends, isEmpty);
    expect(chat.groups, isEmpty);
    expect(chat.friendRequests, isEmpty);
    expect(chat.conversations, isEmpty);
    expect(await chat.friendChanges.first, isEmpty);
    await identity.connect();
    await pumpEventQueue();
    expect(chat.friends, hasLength(1));
  });

  test('a draft or pin does not bring back a deleted conversation', () async {
    await identity.connect();
    chat.addFakeFriend(Friend(publicKey: peer, displayName: 'Ann'));
    chat.receiveMessage(peerConv, 'CQ');
    await chat.deleteConversation(peerConv);
    await chat.setDraft(peerConv, 'half');
    await chat.setPinned(peerConv, true);
    expect(chat.conversations.map((c) => c.id), isNot(contains(peerConv)));
  });

  test('an answer held across a reconnect does not land on the new session',
      () async {
    await identity.connect();
    chat.receiveFriendRequest('B' * 64);
    final Completer<void> hold = Completer<void>();
    chat.holdAnswers = hold;
    final Future<void> accepting = chat.acceptFriendRequest('B' * 64);
    await identity.disconnect();
    await identity.connect();
    hold.complete();
    await expectLater(accepting, throwsCode('not_connected'));
    expect(chat.friends, isEmpty);
  });
}
