import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/notifications/notifications.dart';
import 'package:ditmesh/notifications/testing/fake_badge_api.dart';
import 'package:ditmesh/notifications/testing/fake_local_notifications_api.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';

import 'support/stub_identity_service.dart';

final String kAnn = 'A' * 64;
final String kAnnConv = 'c2c_$kAnn';
final String kBob = 'C' * 64;
final String kBobConv = 'c2c_$kBob';
const String kAnnPattern = '-.-. --.- / -.-. --.- / -.. . / .- -. -.';

/// English strings, the language every assertion below is written against
/// unless the harness is given another resolver.
final S en = lookupS(const Locale('en'));
final S zh = lookupS(const Locale('zh'));

/// Everything a NotificationCenter test needs, wired the way the
/// orchestrator will: fake backend, recording plugin fakes, prefs, a
/// foreground flag the test flips by hand and a strings resolver (English
/// by default, pinned rather than following the test host's locale).
final class Harness {
  Harness({
    NotificationPlatform platform = NotificationPlatform.android,
    bool foreground = false,
    bool badgeSupported = true,
    S Function()? strings,
    this.identity,
  }) : api = FakeLocalNotificationsApi(),
       badge = FakeBadgeApi(supported: badgeSupported),
       prefs = NotificationPrefs(),
       foreground = ValueNotifier<bool>(foreground) {
    chat = FakeChatService(selfPublicKey: 'F' * 64, clock: () => now);
    center = NotificationCenter(
      chat: chat,
      notifications: api,
      badge: badge,
      prefs: prefs,
      isForeground: this.foreground,
      identity: identity,
      platform: platform,
      strings: strings ?? () => en,
      clock: () => now,
    );
  }

  /// One clock for the backend's timestamps and the centre's start time.
  DateTime now = DateTime(2026, 9, 30, 12);

  final StubIdentityService? identity;
  late final FakeChatService chat;
  final FakeLocalNotificationsApi api;
  final FakeBadgeApi badge;
  final NotificationPrefs prefs;
  final ValueNotifier<bool> foreground;
  late final NotificationCenter center;

  /// Adds Ann as a friend and starts the center. [grant] stands for a
  /// permission the user granted earlier (the foreground ask the app makes).
  Future<void> start({bool grant = true}) async {
    chat.addFakeFriend(Friend(publicKey: kAnn, displayName: 'Ann'));
    await center.start();
    if (grant) await center.ensurePermission();
    await pumpEventQueue();
  }

  Future<void> receive(String text, {String? conversationId}) async {
    chat.receiveMessage(conversationId ?? kAnnConv, text);
    await pumpEventQueue();
  }

  Future<void> dispose() async {
    await center.dispose();
    await chat.dispose();
    await identity?.dispose();
    prefs.dispose();
    foreground.dispose();
  }
}

Future<Harness> harness({
  NotificationPlatform platform = NotificationPlatform.android,
  bool foreground = false,
  bool badgeSupported = true,
  S Function()? strings,
  StubIdentityService? identity,
}) async {
  final Harness h = Harness(
    platform: platform,
    foreground: foreground,
    badgeSupported: badgeSupported,
    strings: strings,
    identity: identity,
  );
  addTearDown(h.dispose);
  await h.start();
  return h;
}

/// The owner token a conversation screen claims with.
final Object screenA = Object();
final Object screenB = Object();

void main() {
  group('inbound messages', () {
    test(
      'late recording enriches existing message without another notification',
      () async {
        final h = await harness();
        final row = h.chat.receiveMessage(kAnnConv, 'CQ');
        await pumpEventQueue();
        expect(h.api.shown, hasLength(1));
        h.chat.attachRecording(row.id, KeyedRecording(durationsMs: [83]));
        await pumpEventQueue();
        expect(h.api.shown, hasLength(1));
        expect(
          (await h.chat.loadHistory(kAnnConv)).single.recording,
          isNotNull,
        );
      },
    );

    test('in the background posts title, text and Morse pattern', () async {
      final Harness h = await harness();
      await h.receive('CQ CQ DE ANN');

      expect(h.api.shown, hasLength(1));
      final NotificationRequest n = h.api.shown.single;
      expect(n.title, 'Ann');
      expect(n.body, contains('CQ CQ DE ANN'));
      expect(n.body, contains(kAnnPattern));
      expect(n.channel, NotificationChannelKind.messages);
      expect(n.payload, OpenConversationTarget(kAnnConv).encode());
      expect(n.groupKey, 'ditmesh.messages.$kAnnConv');
      expect(n.sound, isTrue);
      expect(n.id, stableNotificationId(n.payload));
    });

    test('foreground with the conversation open: no notification', () async {
      final Harness h = await harness(foreground: true);
      h.center.claimActiveConversation(kAnnConv, screenA);
      await h.receive('CQ');
      expect(h.api.shown, isEmpty);

      // Leaving the conversation re-arms it.
      h.center.releaseActiveConversation(screenA);
      await h.receive('CQ');
      expect(h.api.shown, hasLength(1));
    });

    test('an older screen going away keeps a newer claim', () async {
      final Harness h = await harness(foreground: true);
      h.center.claimActiveConversation(kAnnConv, screenA);
      h.center.claimActiveConversation(kAnnConv, screenB);
      h.center.releaseActiveConversation(screenA);
      await h.receive('CQ');
      expect(h.api.shown, isEmpty);
      h.center.releaseActiveConversation(screenB);
      await h.receive('K');
      expect(h.api.shown, hasLength(1));
    });

    test(
      'foreground with a different conversation open still notifies',
      () async {
        final Harness h = await harness(foreground: true);
        h.center.claimActiveConversation(kBobConv, screenA);
        await h.receive('CQ');
        expect(h.api.shown, hasLength(1));
      },
    );

    test('background with the conversation "open" still notifies', () async {
      // The screen may still be mounted while the app is paused; the user
      // cannot see it, so the OS banner is the only way to reach them.
      final Harness h = await harness(foreground: false);
      h.center.claimActiveConversation(kAnnConv, screenA);
      await h.receive('CQ');
      expect(h.api.shown, hasLength(1));
    });

    test('muted conversation never notifies', () async {
      final Harness h = await harness();
      h.prefs.setMuted(kAnnConv, true);
      await h.receive('CQ');
      expect(h.api.shown, isEmpty);

      h.prefs.setMuted(kAnnConv, false);
      await h.receive('CQ');
      expect(h.api.shown, hasLength(1));
    });

    test('disabled prefs suppress everything but the badge', () async {
      final Harness h = await harness();
      h.prefs.enabled = false;
      await h.receive('CQ');
      expect(h.api.shown, isEmpty);
      expect(h.badge.current, 1);
    });

    test('own messages and status updates never notify', () async {
      final Harness h = await harness();
      final ChatMessage sent = await h.chat.sendText(kAnnConv, 'K');
      expect(sent.status, MessageStatus.pending);
      h.chat.setFriendOnline(kAnn, true); // pending -> sent event
      await pumpEventQueue();
      expect(h.api.shown, isEmpty);
    });

    test('a burst becomes one notification with inbox lines', () async {
      final Harness h = await harness();
      await h.receive('CQ');
      await h.receive('K');
      expect(h.api.shown, hasLength(2));
      expect(h.api.active, hasLength(1)); // same id, replaced in place
      final NotificationRequest n = h.api.last!;
      expect(n.lines, hasLength(2));
      expect(n.lines.first, contains('CQ'));
      expect(n.lines.last, contains('K'));
      expect(n.summary, en.notificationNewMessages(2));
      expect(n.summary, '2 new messages');
    });

    test('inbox keeps only the newest five lines', () async {
      final Harness h = await harness();
      for (var i = 1; i <= 7; i++) {
        await h.receive('M$i');
      }
      final NotificationRequest n = h.api.last!;
      expect(n.lines, hasLength(NotificationComposer.maxInboxLines));
      expect(n.lines.first, contains('M3'));
      expect(n.lines.last, contains('M7'));
    });

    test('group message: title is the group, sender prefixed', () async {
      final Harness h = await harness();
      final Group g = h.chat.addFakeGroup(
        const Group(id: 'tox_1', name: 'Net', kind: GroupKind.group),
      );
      h.chat.receiveMessage(
        FakeChatService.groupConversationId(g.id),
        'QRL?',
        senderId: kBob,
        senderName: 'Bob',
      );
      await pumpEventQueue();
      final NotificationRequest n = h.api.shown.single;
      expect(n.title, 'Net');
      expect(n.body, startsWith('Bob: '));
      expect(n.body, contains('--.- .-. .-.. ..--..'));
      expect(n.lines, isEmpty); // single message: no inbox yet
    });

    test('blocking a group member withdraws a banner showing them', () async {
      final Harness h = await harness();
      final Group g = h.chat.addFakeGroup(
        const Group(id: 'tox_1', name: 'Net', kind: GroupKind.group),
      );
      h.chat.receiveMessage(
        FakeChatService.groupConversationId(g.id),
        'SPAM',
        senderId: kBob,
        senderName: 'Bob',
      );
      await pumpEventQueue();
      expect(h.api.active, hasLength(1));
      await h.chat.blockPeer(kBob);
      await pumpEventQueue();
      expect(h.api.active, isEmpty);
      h.chat.receiveMessage(
        FakeChatService.groupConversationId(g.id),
        'MORE SPAM',
        senderId: kBob,
      );
      await pumpEventQueue();
      expect(h.api.active, isEmpty, reason: 'filtered at the service');
    });

    test(
      'a new block takes down group banners a previous run posted',
      () async {
        final Harness h = await harness();
        h.chat.addFakeGroup(
          const Group(id: 'tox_9', name: 'Old net', kind: GroupKind.group),
        );
        await pumpEventQueue();
        final int before = h.api.cancelled.length;
        await h.chat.blockPeer(kBob);
        await pumpEventQueue();
        expect(
          h.api.cancelled.length,
          greaterThan(before),
          reason: 'untracked group banner (and the direct one) cancelled',
        );
      },
    );

    test(
      'blocking one member keeps the other lines, re-posted silently',
      () async {
        final Harness h = await harness();
        final Group g = h.chat.addFakeGroup(
          const Group(id: 'tox_1', name: 'Net', kind: GroupKind.group),
        );
        final String cid = FakeChatService.groupConversationId(g.id);
        h.chat.receiveMessage(cid, 'GM', senderId: kAnn, senderName: 'Ann');
        await pumpEventQueue();
        h.chat.receiveMessage(cid, 'SPAM', senderId: kBob, senderName: 'Bob');
        await pumpEventQueue();
        expect(h.api.active.single.lines, hasLength(2));
        await h.chat.blockPeer(kBob);
        await pumpEventQueue();
        final NotificationRequest n = h.api.active.single;
        expect(n.lines, isEmpty, reason: 'one line left: no inbox');
        expect(n.body, startsWith('Ann: '));
        expect(n.sound, isFalse, reason: 'blocking must not alert again');
        expect(n.silentUpdate, isTrue, reason: 'no banner or heads-up either');
      },
    );

    test(
      'group message from a nameless peer falls back to the short key',
      () async {
        final Harness h = await harness();
        final Group g = h.chat.addFakeGroup(
          const Group(id: 'tox_1', name: 'Net', kind: GroupKind.group),
        );
        h.chat.receiveMessage(
          FakeChatService.groupConversationId(g.id),
          'K',
          senderId: kBob,
        );
        await pumpEventQueue();
        expect(h.api.shown.single.body, startsWith('${'C' * 8}: '));
      },
    );

    test('no grouping keys on Linux / Windows', () async {
      final Harness h = await harness(platform: NotificationPlatform.linux);
      await h.receive('CQ');
      expect(h.api.shown.single.groupKey, isNull);
    });

    test('unsupported platform: nothing is posted, badge untouched', () async {
      final Harness h = await harness(
        platform: NotificationPlatform.unsupported,
      );
      await h.receive('CQ');
      expect(h.api.initialized, isFalse);
      expect(h.api.shown, isEmpty);
      expect(h.badge.writes, isEmpty);
    });
  });

  group('prefs shape the body', () {
    test('pattern only', () async {
      final Harness h = await harness();
      h.prefs.showText = false;
      await h.receive('CQ CQ DE ANN');
      expect(h.api.shown.single.body, kAnnPattern);
    });

    test('text only', () async {
      final Harness h = await harness();
      h.prefs.showPattern = false;
      await h.receive('CQ CQ DE ANN');
      expect(h.api.shown.single.body, 'CQ CQ DE ANN');
    });

    test('neither: neutral body, and sound follows prefs', () async {
      final Harness h = await harness();
      h.prefs
        ..showText = false
        ..showPattern = false
        ..sound = false;
      await h.receive('CQ');
      expect(h.api.shown.single.body, en.notificationNewMessage);
      expect(h.api.shown.single.body, 'New message');
      expect(h.api.shown.single.sound, isFalse);
    });
  });

  group('language', () {
    test('bodies and titles follow the strings resolver (zh)', () async {
      final Harness h = await harness(strings: () => zh);
      h.prefs
        ..showText = false
        ..showPattern = false;
      await h.receive('CQ');
      expect(h.api.shown.single.body, zh.notificationNewMessage);
      expect(h.api.shown.single.body, '新消息');

      h.chat.receiveFriendRequest(kBob, message: '');
      await pumpEventQueue();
      final NotificationRequest fr = h.api.shown.last;
      expect(fr.title, zh.notificationFriendRequestTitle);
      expect(fr.title, '新的好友请求');
      expect(fr.body, zh.notificationFriendRequestFrom('C' * 8));
      expect(fr.body, contains('好友请求'));
    });

    test('a language switch applies to the next notification', () async {
      S current = en;
      final Harness h = await harness(strings: () => current);
      h.prefs
        ..showText = false
        ..showPattern = false;
      await h.receive('CQ');
      expect(h.api.shown.last.body, 'New message');

      current = zh;
      await h.receive('K');
      expect(h.api.shown.last.body, '新消息');
      // The grouped summary is rendered in the new language too.
      expect(h.api.shown.last.summary, zh.notificationNewMessages(2));
    });
  });

  group('badge', () {
    test('follows the total unread across conversations', () async {
      final Harness h = await harness();
      expect(h.badge.current, 0); // replayed conversation list at start
      await h.receive('CQ');
      await h.receive('K');
      h.chat.addFakeFriend(Friend(publicKey: kBob, displayName: 'Bob'));
      await h.receive('CQ', conversationId: kBobConv);
      expect(h.badge.current, 3);

      await h.chat.markRead(kAnnConv);
      await pumpEventQueue();
      expect(h.badge.current, 1);
      // Reading Ann's conversation also took its banner down.
      expect(h.api.cancelled, contains(h.api.shown.first.id));
    });

    test('never writes the same total twice', () async {
      final Harness h = await harness();
      await h.receive('CQ');
      await h.chat.setPinned(
        kAnnConv,
        true,
      ); // conversation change, same unread
      await pumpEventQueue();
      expect(h.badge.writes, <int>[0, 1]);
    });

    test('unsupported launcher: probed once, never written', () async {
      final Harness h = await harness(badgeSupported: false);
      await h.receive('CQ');
      await h.receive('K');
      expect(h.badge.supportChecks, 1);
      expect(h.badge.writes, isEmpty);
    });

    test('platform without a badge never probes the plugin', () async {
      final Harness h = await harness(platform: NotificationPlatform.windows);
      await h.receive('CQ');
      expect(h.badge.supportChecks, 0);
    });
  });

  group('active conversation', () {
    test(
      'opening a conversation in the foreground dismisses its banner',
      () async {
        final Harness h = await harness();
        await h.receive('CQ');
        expect(h.api.active, hasLength(1));

        h.foreground.value = true;
        h.center.claimActiveConversation(kAnnConv, screenA);
        await pumpEventQueue();
        expect(h.api.active, isEmpty);
      },
    );

    test(
      'returning to the foreground on an open conversation dismisses it',
      () async {
        final Harness h = await harness();
        h.center.claimActiveConversation(kAnnConv, screenA);
        await h.receive('CQ');
        expect(h.api.active, hasLength(1));

        h.foreground.value = true;
        await pumpEventQueue();
        expect(h.api.active, isEmpty);
      },
    );
  });

  // No grant cached yet, so each post first runs the silent OS check: the
  // window in which the user can open or read the conversation.
  group('a post overtaken by the user reading the conversation', () {
    test('android: resumed and read while the permission check runs', () async {
      final Harness h = Harness();
      addTearDown(h.dispose);
      await h.start(grant: false);
      final Completer<bool> check = Completer<bool>();
      h.api.permissionCheckAnswer = check.future;
      // The screen stays mounted while the app is paused.
      h.center.claimActiveConversation(kAnnConv, screenA);
      await h.receive('CQ');
      expect(h.api.shown, isEmpty);

      h.foreground.value = true; // resume: the banner is cancelled
      await h.chat.markRead(kAnnConv);
      await pumpEventQueue();
      check.complete(true);
      await pumpEventQueue();
      expect(h.api.shown, isEmpty);
      expect(h.api.active, isEmpty);

      // Not over-suppressed: the next message in the background notifies.
      h.foreground.value = false;
      await h.receive('K');
      expect(h.api.shown, hasLength(1));
    });

    test(
      'foreground: opened and read while the permission check runs',
      () async {
        final Harness h = Harness(foreground: true);
        addTearDown(h.dispose);
        // The start-up ask was declined; the check later finds a grant.
        h.api
          ..permissionGranted = false
          ..grantOnRequest = false;
        await h.start(grant: false);
        final Completer<bool> check = Completer<bool>();
        h.api.permissionCheckAnswer = check.future;
        await h.receive('CQ');
        expect(h.api.shown, isEmpty);

        h.center.claimActiveConversation(kAnnConv, screenA);
        await h.chat.markRead(kAnnConv);
        await pumpEventQueue();
        check.complete(true);
        await pumpEventQueue();
        expect(h.api.shown, isEmpty);
        expect(h.api.active, isEmpty);
      },
    );

    test(
      'a delayed post read meanwhile never replaces a newer banner',
      () async {
        final Harness h = Harness();
        addTearDown(h.dispose);
        await h.start(grant: false);
        final Completer<bool> check = Completer<bool>();
        h.api.permissionCheckAnswer = check.future;
        await h.receive('M1');
        await h.chat.markRead(kAnnConv);
        await pumpEventQueue();
        await h.receive('M2'); // unread is above 0 again
        check.complete(true);
        await pumpEventQueue();
        expect(h.api.shown, hasLength(1));
        expect(h.api.shown.single.body, contains('M2'));
        expect(h.api.shown.single.body, isNot(contains('M1')));
      },
    );

    test('Linux: a listener opens and reads it during delivery', () async {
      final Harness h = await harness(
        platform: NotificationPlatform.linux,
        foreground: true,
      );
      // Subscribed after the center, like the conversation screen.
      final StreamSubscription<ChatMessage> sub = h.chat.messageEvents.listen((
        ChatMessage m,
      ) {
        h.center.claimActiveConversation(m.conversationId, screenA);
        unawaited(h.chat.markRead(m.conversationId));
      });
      addTearDown(sub.cancel);
      await h.receive('CQ');
      expect(h.api.active, isEmpty);
      expect(h.api.shown, isEmpty);
    });
  });

  group('friend requests and group invites', () {
    test('a new friend request notifies on its own channel', () async {
      final Harness h = await harness();
      h.chat.receiveFriendRequest(kBob, message: 'CQ CQ');
      await pumpEventQueue();
      final NotificationRequest n = h.api.shown.single;
      expect(n.channel, NotificationChannelKind.friendRequests);
      expect(n.title, en.notificationFriendRequestTitle);
      expect(n.title, 'New friend request');
      expect(n.body, en.notificationFriendRequestBody('C' * 8, 'CQ CQ'));
      expect(n.body, '${'C' * 8}: CQ CQ');
      expect(n.payload, FriendRequestTarget(kBob).encode());

      await h.chat.acceptFriendRequest(kBob);
      await pumpEventQueue();
      expect(h.api.active, isEmpty); // banner taken down once answered
    });

    test('requests pending at start are not re-announced', () async {
      final Harness h = Harness();
      addTearDown(h.dispose);
      h.chat.receiveFriendRequest(kBob);
      h.now = h.now.add(const Duration(minutes: 1));
      await h.start();
      expect(h.api.shown, isEmpty);
    });

    test(
      'requests the backend restores after start are not announced',
      () async {
        // The real backend publishes requests persisted by an earlier run only
        // after connecting, with their original arrival time.
        final Harness h = await harness();
        h.now = h.now.subtract(const Duration(days: 1));
        h.chat.receiveFriendRequest(kBob);
        await pumpEventQueue();
        expect(h.api.shown, isEmpty);
      },
    );

    test('with message text hidden, a request shows no wording', () async {
      final Harness h = await harness();
      h.prefs.showText = false;
      h.chat.receiveFriendRequest(kBob, message: 'click http://evil');
      await pumpEventQueue();
      expect(
        h.api.shown.single.body,
        en.notificationFriendRequestFrom('C' * 8),
      );
    });

    test('a friend request without a message names the requester', () async {
      final Harness h = await harness();
      h.chat.receiveFriendRequest(kBob, message: '');
      await pumpEventQueue();
      expect(
        h.api.shown.single.body,
        en.notificationFriendRequestFrom('C' * 8),
      );
      expect(h.api.shown.single.body, 'Friend request from ${'C' * 8}');
    });

    test('a group invite notifies with the group name', () async {
      final Harness h = await harness();
      final GroupInvite invite = h.chat.receiveGroupInvite(
        fromPublicKey: kAnn,
        groupName: 'Net',
      );
      await pumpEventQueue();
      final NotificationRequest n = h.api.shown.single;
      expect(n.channel, NotificationChannelKind.groupInvites);
      expect(n.title, en.notificationGroupInviteTitle('Net'));
      expect(n.title, 'Invite to Net');
      expect(n.body, en.notificationGroupInviteBody('Ann'));
      expect(n.body, 'Ann invited you');
      expect(n.payload, GroupInviteTarget(invite.inviteId).encode());
    });
  });

  group('taps', () {
    test('a tap is kept until the router takes it, then signalled', () async {
      final Harness h = await harness();
      final Future<NotificationTapTarget> signalled = h.center.tapTargets.first;
      h.api.tapTarget(OpenConversationTarget(kAnnConv));
      expect(await signalled, OpenConversationTarget(kAnnConv));
      expect(h.center.takePendingTap(), OpenConversationTarget(kAnnConv));
      expect(h.center.takePendingTap(), isNull);
    });

    test('a newer tap supersedes one nobody routed yet', () async {
      final Harness h = await harness();
      h.api.tapTarget(FriendRequestTarget(kBob));
      h.api.tap('garbage');
      h.api.tapTarget(OpenConversationTarget(kAnnConv));
      expect(h.center.takePendingTap(), OpenConversationTarget(kAnnConv));
    });

    test('a cold-start payload waits for a router mounted later', () async {
      // Nobody listens while the centre starts (the shell is built only once
      // the identity is ready): the tap must still be there afterwards.
      final Harness h = Harness();
      addTearDown(h.dispose);
      h.api.launchPayload = OpenConversationTarget(kAnnConv).encode();
      await h.start();
      expect(h.center.takePendingTap(), OpenConversationTarget(kAnnConv));
    });
  });

  group('review regressions', () {
    test(
      'hiding message content also hides lines already in the inbox',
      () async {
        final Harness h = await harness();
        await h.receive('SECRET ONE');
        h.prefs
          ..showText = false
          ..showPattern = false;
        await h.receive('SECRET TWO');
        final NotificationRequest n = h.api.last!;
        expect(n.lines.join(' '), isNot(contains('SECRET')));
        expect(n.body, isNot(contains('SECRET')));
      },
    );

    test(
      'a tap during the launch-payload read wins over the launch payload',
      () async {
        final Harness h = Harness();
        addTearDown(h.dispose);
        h.api
          ..launchPayload = FriendRequestTarget(kBob).encode()
          ..onTakeLaunchPayload = () =>
              h.api.tapTarget(OpenConversationTarget(kAnnConv));
        await h.start();
        expect(h.center.takePendingTap(), OpenConversationTarget(kAnnConv));
      },
    );

    test('a tap during plugin start-up wins over the launch payload', () async {
      final Harness h = Harness();
      addTearDown(h.dispose);
      h.api
        ..launchPayload = FriendRequestTarget(kBob).encode()
        ..onInitialize = () =>
            h.api.tapTarget(OpenConversationTarget(kAnnConv));
      await h.start();
      expect(h.center.takePendingTap(), OpenConversationTarget(kAnnConv));
    });

    test(
      'a stale cleanup does not withdraw the next identity\'s banners',
      () async {
        final StubIdentityService me = StubIdentityService(
          identity: Identity(toxId: 'A' * 76, displayName: 'A'),
        );
        final Harness h = Harness(identity: me);
        addTearDown(h.dispose);
        final Completer<void> hold = Completer<void>();
        h.api.holdActivePayloads = hold;
        await h.start(); // cleanup for A is waiting on the active list
        me.setIdentity(Identity(toxId: 'F' * 76, displayName: 'B'));
        await pumpEventQueue();
        await h.receive('CQ'); // B's banner
        hold.complete();
        await pumpEventQueue();
        expect(h.api.active, hasLength(1));
      },
    );

    test(
      'an identity already open at start withdraws foreign banners',
      () async {
        final StubIdentityService me = StubIdentityService();
        final Harness h = Harness(identity: me);
        addTearDown(h.dispose);
        final String other = 'A' * 16;
        final NotificationTapTarget t = OpenConversationTarget(
          kAnnConv,
          account: other,
        );
        await h.api.show(
          NotificationRequest(
            id: stableNotificationId(t.encode()),
            channel: NotificationChannelKind.messages,
            title: 't',
            body: 'b',
            payload: t.encode(),
          ),
        );
        await h.start();
        expect(h.api.active, isEmpty);
      },
    );

    test(
      'the first identity of a run withdraws another identity\'s banners',
      () async {
        final StubIdentityService me = StubIdentityService()..clearIdentity();
        final Harness h = Harness(identity: me);
        addTearDown(h.dispose);
        // Left over from an earlier run: one of A's, one untagged, one of B's.
        final String a = 'A' * 16;
        final String b = 'F' * 16;
        for (final NotificationTapTarget t in [
          OpenConversationTarget(kAnnConv, account: a),
          const OpenConversationTarget('c2c_x'),
          OpenConversationTarget(kBobConv, account: b),
        ]) {
          await h.api.show(
            NotificationRequest(
              id: stableNotificationId(t.encode()),
              channel: NotificationChannelKind.messages,
              title: 't',
              body: 'b',
              payload: t.encode(),
            ),
          );
        }
        await h.start();
        me.setIdentity(Identity(toxId: 'F' * 76, displayName: 'B'));
        await pumpEventQueue();
        final List<String> left = h.api.active.map((n) => n.payload).toList();
        expect(left, hasLength(2));
        expect(left.any((p) => p.endsWith('#$a')), isFalse);
      },
    );
  });

  group('identity scoping', () {
    test('payloads carry the account; a foreign one is ignored', () async {
      final StubIdentityService me = StubIdentityService();
      final Harness h = await harness(identity: me);
      await h.receive('CQ');
      final String account = 'F' * 16;
      expect(
        h.api.shown.single.payload,
        OpenConversationTarget(kAnnConv, account: account).encode(),
      );
      h.api.tapTarget(OpenConversationTarget(kAnnConv, account: 'E' * 16));
      expect(h.center.takePendingTap(), isNull);
      h.api.tapTarget(OpenConversationTarget(kAnnConv, account: account));
      expect(h.center.takePendingTap()?.account, account);
      // Payloads from before account tags are still accepted.
      h.api.tap('conv:$kAnnConv');
      expect(h.center.takePendingTap(), OpenConversationTarget(kAnnConv));
    });

    test('a new identity withdraws everything the old one posted', () async {
      final StubIdentityService me = StubIdentityService();
      final Harness h = await harness(identity: me);
      await h.receive('CQ');
      h.api.tapTarget(OpenConversationTarget(kAnnConv));
      me.setIdentity(Identity(toxId: 'E' * 76, displayName: 'Next'));
      await pumpEventQueue();
      expect(h.api.cancelAllCalls, 1);
      expect(h.center.takePendingTap(), isNull);
    });

    test('a post held across an identity switch is dropped', () async {
      final StubIdentityService me = StubIdentityService();
      final Harness h = Harness(identity: me);
      addTearDown(h.dispose);
      await h.start(grant: false);
      final Completer<bool> check = Completer<bool>();
      h.api.permissionCheckAnswer = check.future;
      h.chat.receiveFriendRequest(kBob, message: 'for the old identity');
      await pumpEventQueue();
      expect(h.api.shown, isEmpty);

      // The old identity's request goes away with it (the fake service is
      // shared, so drop it by hand), then the new identity gets one from
      // the same peer: the held post's key is "known" again.
      await h.chat.rejectFriendRequest(kBob);
      me.setIdentity(Identity(toxId: 'E' * 76, displayName: 'Next'));
      await pumpEventQueue();
      h.chat.receiveFriendRequest(kBob, message: 'for the new identity');
      await pumpEventQueue();
      check.complete(true);
      await pumpEventQueue();
      expect(
        h.api.shown.map((n) => n.body),
        isNot(contains(contains('for the old identity'))),
      );
    });
  });

  group('dispose', () {
    test(
      'releases every subscription and stream before its first await',
      () async {
        final Harness h = await harness();
        await h.receive('CQ');
        expect(h.api.shown, hasLength(1));

        // Deliberately NOT awaited yet: AppScope.dispose() cannot wait either,
        // and a cancelled broadcast subscription may resume in the root zone.
        final Future<void> done = h.center.dispose();

        // Subscriptions were cancelled synchronously: nothing else is posted.
        await h.receive('CQ DE BOB');
        expect(h.api.shown, hasLength(1));
        // Both outbound controllers were closed synchronously.
        expect(await h.center.tapTargets.isEmpty, isTrue);
        await done;
        await h.center.dispose(); // idempotent
      },
    );
  });

  group('permission', () {
    test('asked once in the foreground, never by a post', () async {
      final Harness h = Harness(foreground: true);
      addTearDown(h.dispose);
      await h.start(grant: false);
      expect(h.api.permissionRequests, 1);
      await h.receive('CQ');
      await h.receive('K');
      expect(h.api.permissionRequests, 1);
      expect(h.api.shown, hasLength(2));
    });

    test('started in the background: asked on the next resume', () async {
      // Android 13+ cannot show the dialog from a stopped activity, iOS
      // queues it out of context: the post is dropped after a silent check.
      final Harness h = Harness();
      addTearDown(h.dispose);
      h.api.permissionGranted = false;
      await h.start(grant: false);
      await h.receive('CQ');
      expect(h.api.permissionRequests, 0);
      expect(h.api.permissionChecks, 1);
      expect(h.api.shown, isEmpty);
      h.api.grantOnRequest = true;
      h.foreground.value = true;
      await pumpEventQueue();
      expect(h.api.permissionRequests, 1);
      h.foreground.value = false;
      await h.receive('K');
      expect(h.api.shown, hasLength(1));
      expect(h.api.permissionRequests, 1);
    });

    test(
      'a grant from an earlier run posts from the background silently',
      () async {
        final Harness h = Harness();
        addTearDown(h.dispose);
        await h.start(grant: false);
        await h.receive('CQ');
        await h.receive('K');
        expect(h.api.shown, hasLength(2));
        expect(h.api.permissionRequests, 0);
        // The grant is cached after the first check.
        expect(h.api.permissionChecks, 1);
        expect(await h.center.ensurePermission(), isTrue);
        expect(h.api.permissionRequests, 0);
      },
    );

    test(
      'denied permission suppresses posting; an explicit ask retries',
      () async {
        final Harness h = Harness(foreground: true);
        addTearDown(h.dispose);
        h.api.permissionGranted = false;
        await h.start(grant: false);
        await h.receive('CQ');
        expect(h.api.shown, isEmpty);
        expect(h.api.permissionRequests, 1);

        // The settings entry asks again (denials are not cached).
        h.api.permissionGranted = true;
        expect(await h.center.ensurePermission(), isTrue);
        await h.receive('K');
        expect(h.api.shown, hasLength(1));
      },
    );

    test(
      'a denial is not cached: a grant made in Settings is picked up',
      () async {
        final Harness h = Harness(foreground: true);
        addTearDown(h.dispose);
        h.api
          ..permissionGranted = false
          ..grantOnRequest = false;
        await h.start(grant: false);
        await h.receive('CQ');
        expect(h.api.shown, isEmpty);
        h.api.permissionGranted = true;
        await h.receive('73');
        expect(h.api.shown, hasLength(1));
        expect(h.api.permissionRequests, 1);
      },
    );

    test('Linux needs no permission and never asks', () async {
      final Harness h = await harness(platform: NotificationPlatform.linux);
      expect(await h.center.ensurePermission(), isTrue);
      await h.receive('CQ');
      expect(h.api.permissionRequests, 0);
      expect(h.api.shown, hasLength(1));
    });
  });

  group('refreshStrings', () {
    test('forwards a language change to the plugin once ready', () async {
      final Harness h = Harness();
      await h.start();
      await h.center.refreshStrings();
      expect(h.api.refreshStringsCalls, 1);
    });

    test('forwarded before start (the API defers it), not after dispose or '
        'on a platform without OS notifications', () async {
      final Harness h = Harness();
      await h.center.refreshStrings();
      expect(h.api.refreshStringsCalls, 1);
      await h.center.dispose();
      await h.center.refreshStrings();
      expect(h.api.refreshStringsCalls, 1);

      final Harness none = Harness(platform: NotificationPlatform.unsupported);
      await none.start();
      await none.center.refreshStrings();
      expect(none.api.refreshStringsCalls, 0);
    });
  });
}
