import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/notifications/notification_payload.dart';

void main() {
  group('NotificationTapTarget', () {
    test('an account tag round-trips; untagged payloads still parse', () {
      final String account = 'F' * 16;
      for (final NotificationTapTarget t in [
        OpenConversationTarget('c2c_${'A' * 64}', account: account),
        FriendRequestTarget('B' * 64, account: account),
        GroupInviteTarget('inv_1', account: account),
      ]) {
        expect(NotificationTapTarget.parse(t.encode()), t);
        expect(t.encode(), endsWith('#$account'));
      }
      expect(
        NotificationTapTarget.parse('conv:c2c_X'),
        const OpenConversationTarget('c2c_X'),
      );
      expect(
        const OpenConversationTarget('c2c_X', account: 'A'),
        isNot(const OpenConversationTarget('c2c_X')),
      );
    });

    test('round-trips every kind', () {
      const List<NotificationTapTarget> targets = <NotificationTapTarget>[
        OpenConversationTarget('c2c_ABC'),
        OpenConversationTarget('group_tox_1'),
        FriendRequestTarget('ABC'),
        GroupInviteTarget('inv_1'),
      ];
      for (final NotificationTapTarget t in targets) {
        expect(NotificationTapTarget.parse(t.encode()), t);
      }
    });

    test('conversation ids are carried verbatim', () {
      expect(const OpenConversationTarget('c2c_ABC').encode(), 'conv:c2c_ABC');
      expect(
        NotificationTapTarget.parse(' conv:group_tox_9 '),
        const OpenConversationTarget('group_tox_9'),
      );
    });

    test('rejects empty and unknown payloads', () {
      expect(NotificationTapTarget.parse(''), isNull);
      expect(NotificationTapTarget.parse('conv:'), isNull);
      expect(NotificationTapTarget.parse('friend_req:'), isNull);
      expect(NotificationTapTarget.parse('c2c_ABC'), isNull);
      expect(NotificationTapTarget.parse('missed_call:x'), isNull);
    });

    test('equality is by kind and id', () {
      expect(
        const FriendRequestTarget('X'),
        isNot(const GroupInviteTarget('X')),
      );
      expect(
        const OpenConversationTarget('a').hashCode,
        const OpenConversationTarget('a').hashCode,
      );
    });
    test('hashes are per kind and toString names the kind and payload', () {
      expect(
        const FriendRequestTarget('X').hashCode,
        const FriendRequestTarget('X').hashCode,
      );
      expect(
        const GroupInviteTarget('X').hashCode,
        const GroupInviteTarget('X').hashCode,
      );
      expect(
        const OpenConversationTarget('c2c_A').toString(),
        'OpenConversationTarget(${const OpenConversationTarget('c2c_A').encode()})',
      );
      expect(
        const FriendRequestTarget('ABC').toString(),
        'FriendRequestTarget(${const FriendRequestTarget('ABC').encode()})',
      );
      expect(
        const GroupInviteTarget('inv_1').toString(),
        'GroupInviteTarget(${const GroupInviteTarget('inv_1').encode()})',
      );
      expect(<NotificationTapTarget>{
        const FriendRequestTarget('X'),
        const GroupInviteTarget('X'),
        const OpenConversationTarget('X'),
      }, hasLength(3));
    });
  });

  group('stableNotificationId', () {
    test('is deterministic, non-negative and fits an Android int', () {
      final int a = stableNotificationId('conv:c2c_ABC');
      expect(a, stableNotificationId('conv:c2c_ABC'));
      expect(a, greaterThanOrEqualTo(0));
      expect(a, lessThanOrEqualTo(0x7FFFFFFF));
    });

    test('differs across targets', () {
      expect(
        stableNotificationId('conv:c2c_ABC'),
        isNot(stableNotificationId('conv:c2c_ABD')),
      );
      expect(
        stableNotificationId('friend_req:ABC'),
        isNot(stableNotificationId('conv:ABC')),
      );
    });

    test('matches the FNV-1a reference for a known input', () {
      // FNV-1a 32-bit of "a" is 0xE40C292C; masked to 31 bits.
      expect(stableNotificationId('a'), 0xE40C292C & 0x7FFFFFFF);
    });
  });
}
