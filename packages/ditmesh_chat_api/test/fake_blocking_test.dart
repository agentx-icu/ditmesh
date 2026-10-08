import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:test/test.dart';

final String kPeer = 'A' * 64;
// AA..AA and nospam 11111111 cancel out in both checksum lanes: 0000.
final String kPeerToxId = '${'A' * 64}${'1' * 8}0000';
final String kMember = 'B' * 64;
final String kOther = 'C' * 64;

Matcher _code(String code) =>
    throwsA(isA<ChatException>().having((e) => e.code, 'code', code));

/// [FakeChatService] blocking follows the contract the UI relies on
/// ([ChatService.blockedPeers]).
void main() {
  late FakeChatService service;

  setUp(() => service = FakeChatService());
  tearDown(() => service.dispose());

  Group group() => service.addFakeGroup(
    const Group(id: 'tox_1', name: 'DX net', kind: GroupKind.group),
  );

  test('blocking a friend removes them and their conversation', () async {
    service.addFakeFriend(Friend(publicKey: kPeer, displayName: 'W1AW'));
    service.receiveMessage('c2c_$kPeer', 'CQ');
    await service.blockPeer(kPeerToxId.toLowerCase());
    expect(service.blockedPeers, {kPeer});
    expect(service.friends, isEmpty);
    expect(service.conversations.where((c) => c.id == 'c2c_$kPeer'), isEmpty);
    expect(await service.blockedPeerChanges.first, {kPeer});
  });

  test(
    'inbound messages, requests and invites from a blocked key are dropped',
    () async {
      await service.blockPeer(kPeer);
      final events = <ChatMessage>[];
      final sub = service.messageEvents.listen(events.add);
      group();
      service.receiveMessage('group_tox_1', 'spam', senderId: kPeer);
      service.receiveFriendRequest(kPeer);
      service.receiveGroupInvite(fromPublicKey: kPeer, groupName: 'spam net');
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
      expect(service.friendRequests, isEmpty);
      expect(service.groupInvites, isEmpty);
      await sub.cancel();
    },
  );

  test('blocking declines a pending request and invites', () async {
    service.receiveFriendRequest(kPeer);
    service.receiveFriendRequest(kOther);
    service.receiveGroupInvite(fromPublicKey: kPeer, groupName: 'X');
    await service.blockPeer(kPeer);
    expect(service.friendRequests.map((r) => r.publicKey), [kOther]);
    expect(service.groupInvites, isEmpty);
  });

  test('a blocked member is hidden from group reads until unblocked', () async {
    group();
    service.receiveMessage('group_tox_1', 'GM', senderId: kOther);
    service.receiveMessage('group_tox_1', 'spam', senderId: kMember);
    await service.blockPeer(kMember);

    expect((await service.loadHistory('group_tox_1')).map((m) => m.text), [
      'GM',
    ]);
    final hits = await service.searchMessages(
      'group_tox_1',
      const MessageSearchQuery(text: 'spam'),
    );
    expect(hits.results, isEmpty);
    final row = service.conversations.singleWhere((c) => c.id == 'group_tox_1');
    expect(row.lastMessage?.text, 'GM');
    expect(row.unreadCount, 1, reason: 'like the transport');

    await service.unblockPeer(kMember);
    expect((await service.loadHistory('group_tox_1')).map((m) => m.text), [
      'GM',
      'spam',
    ]);
  });

  test(
    'addFriend refuses a blocked key; own and malformed keys are refused',
    () async {
      await service.blockPeer(kPeer);
      await expectLater(service.addFriend(kPeerToxId), _code('peer_blocked'));
      await expectLater(
        service.blockPeer(service.selfPublicKey),
        _code('own_id'),
      );
      await expectLater(service.blockPeer('nope'), _code('invalid_tox_id'));
    },
  );

  test('without a session the list is empty and blocking throws', () async {
    final identity = FakeIdentityService.withProfile(
      identity: Identity(
        toxId: FakeIdentityService.toxIdForSeed(3),
        displayName: 'me',
      ),
      connectDelay: Duration.zero,
    );
    final offline = FakeChatService(identity: identity);
    expect(offline.blockedPeers, isEmpty);
    await expectLater(offline.blockPeer(kPeer), _code('not_connected'));
    await offline.dispose();
    await identity.dispose();
  });
}
