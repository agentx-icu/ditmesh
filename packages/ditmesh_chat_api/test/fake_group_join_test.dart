import 'dart:async';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:test/test.dart';

final String kPeer = 'A' * 64;
final String kChatId = 'D' * 64;

Matcher _code(String code) =>
    throwsA(isA<ChatException>().having((e) => e.code, 'code', code));

/// The fake mirrors the backend for sends to non-friends (M1) and for
/// asynchronous group-join refusals and their retries (M2 / M3).
void main() {
  late FakeChatService service;

  setUp(() => service = FakeChatService());
  tearDown(() => service.dispose());

  Future<List<GroupJoinRefusal>> refusalsOf(
    Future<void> Function() action,
  ) async {
    final events = <GroupJoinRefusal>[];
    final sub = service.groupJoinRefusals.listen(events.add);
    await action();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    return events;
  }

  group('sendText target', () {
    test('a non-friend c2c target is refused with not_friend', () async {
      await expectLater(
        service.sendText('c2c_$kPeer', 'CQ'),
        _code('not_friend'),
      );
    });

    test(
      'a removed friend is refused, a blocked key is peer_blocked',
      () async {
        service.addFakeFriend(Friend(publicKey: kPeer, displayName: 'W1AW'));
        await service.sendText('c2c_$kPeer', 'CQ');
        await service.removeFriend(kPeer);
        await expectLater(
          service.sendText('c2c_$kPeer', 'CQ'),
          _code('not_friend'),
        );
        await service.blockPeer(kPeer);
        await expectLater(
          service.sendText('c2c_$kPeer', 'CQ'),
          _code('peer_blocked'),
        );
      },
    );
  });

  group('group join refusals', () {
    test('an invite that needs a password is refused after the accept and '
        'listed again; the right password joins', () async {
      final invite = service.receiveGroupInvite(
        fromPublicKey: kPeer,
        groupName: 'Private',
      );
      service.requireGroupPassword(invite.inviteId, 'pw');
      final events = await refusalsOf(
        () => service.acceptGroupInvite(invite.inviteId),
      );
      expect(events.single.inviteId, invite.inviteId);
      expect(events.single.groupName, 'Private');
      expect(events.single.reason, GroupJoinRefusalReason.invalidPassword);
      expect(service.groups, isEmpty);
      expect(service.groupInvites.map((i) => i.inviteId), [invite.inviteId]);

      final again = await refusalsOf(
        () => service.acceptGroupInvite(invite.inviteId, password: 'pw'),
      );
      expect(again, isEmpty);
      expect(service.groups.map((g) => g.name), ['Private']);
    });

    test('a join by chat id with a wrong password is refused', () async {
      service.requireGroupPassword(kChatId, 'pw');
      final events = await refusalsOf(
        () => service.joinGroup(kChatId, password: 'nope'),
      );
      expect(events.single.chatId, kChatId);
      expect(events.single.inviteId, isNull);
      expect(service.groups, isEmpty);
      await service.joinGroup(kChatId, password: 'pw');
      expect(service.groups.single.chatId, kChatId);
    });

    test('rejoinGroup retries a held group and reports a refusal as '
        'established', () async {
      service.addFakeGroup(
        const Group(id: 'tox_9', name: 'Held', kind: GroupKind.group),
      );
      service.requireGroupPassword('tox_9', 'pw');
      final events = await refusalsOf(() => service.rejoinGroup('tox_9'));
      expect(events.single.established, isTrue);
      expect(events.single.groupId, 'tox_9');
      expect(service.groups.map((g) => g.id), ['tox_9']);
      expect(
        await refusalsOf(() => service.rejoinGroup('tox_9', password: 'pw')),
        isEmpty,
      );
      await expectLater(service.rejoinGroup('tox_x'), _code('group_not_found'));
    });

    test('refuseGroupJoin emits a refusal as given', () async {
      final events = await refusalsOf(() async {
        service.refuseGroupJoin(
          const GroupJoinRefusal(
            groupId: 'tox_5',
            reason: GroupJoinRefusalReason.groupFull,
          ),
        );
      });
      expect(events.single.reason, GroupJoinRefusalReason.groupFull);
    });
  });
}
