import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/prefs_adapter.dart';
import 'package:ditmesh_chat/src/engine/ditmesh_ffi_chat_service.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import 'helpers/fakes.dart';

/// Blocking (App Review 1.2) over the real `FfiChatService` Dart layer and
/// a binding fake: what Tim2Tox filters itself (C2C, case-insensitively via
/// [DitmeshFfiChatService]) and what [Tim2ToxChatService] filters on top
/// (requests, invites, group rows, previews, unread counts).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  const String member =
      '3333333333333333333333333333333333333333333333333333333333333333';
  const String other =
      '4444444444444444444444444444444444444444444444444444444444444444';

  late Directory tempRoot;
  late FakeTim2ToxFfi ffi;
  late HoldingKeyValueStore store;
  late FfiChatService engineService;
  late FakeChatEngine engine;
  late FakeIdentityService identity;
  late Tim2ToxChatService chat;
  var invites = <PendingGroupInvite>[];

  Future<FfiChatService> newService(String dir) async {
    final paths = IdentityPaths('${tempRoot.path}/$dir');
    await paths.ensureDirectories();
    return DitmeshFfiChatService(
        ffiForTesting: ffi,
        preferencesService: Tim2ToxPreferencesAdapter(
          store,
          accountPrefix: '1111111111111111',
        ),
        historyDirectory: paths.historyDirectory,
        queueFilePath: paths.offlineQueueFile,
        fileRecvPath: paths.fileRecvDirectory,
        avatarsPath: paths.avatarsDirectory,
      )
      ..debugBeginSessionForTest()
      ..debugNativePendingInvitesOverride = () => invites;
  }

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ditmesh_block_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (_) async => tempRoot.path);
    ffi = FakeTim2ToxFfi();
    invites = [];
    store = HoldingKeyValueStore();
    engineService = await newService('identity');
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

  Matcher throwsCode(String code) =>
      throwsA(isA<ChatException>().having((e) => e.code, 'code', code));

  test('blocking a friend removes them and their conversation', () async {
    ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: true));
    await bind();
    engineService.ingestC2cText(peer: kPeerKey, text: 'CQ', isSelf: false);
    await pumpEventQueue();
    expect(chat.conversations.map((c) => c.id), contains('c2c_$kPeerKey'));

    await chat.blockPeer(kPeerKey.toLowerCase());

    expect(chat.blockedPeers, {kPeerKey});
    expect(ffi.deletedFriends, [kPeerKey]);
    expect(
      chat.conversations.map((c) => c.id),
      isNot(contains('c2c_$kPeerKey')),
    );
    expect(await chat.blockedPeerChanges.first, {kPeerKey});
  });

  test('Tim2Tox drops a blocked C2C sender in any letter case', () async {
    await bind();
    await chat.blockPeer(kPeerKey);
    final events = <ChatMessage>[];
    final sub = chat.messageEvents.listen(events.add);
    expect(
      engineService.ingestC2cText(
        peer: kPeerKey.toLowerCase(),
        text: 'spam',
        isSelf: false,
      ),
      isFalse,
    );
    expect(
      engineService.ingestC2cText(peer: kPeerKey, text: 'spam', isSelf: false),
      isFalse,
    );
    await pumpEventQueue();
    expect(events, isEmpty);
    await sub.cancel();
  });

  test(
    'friend requests and group invites from a blocked key are hidden',
    () async {
      ffi.applications.add((userId: member, wording: 'hi'));
      ffi.applications.add((userId: other, wording: 'CQ'));
      invites = [
        PendingGroupInvite(
          id: 'inv_1',
          inviterUserId: member.toLowerCase(),
          kind: 'group',
          groupName: 'spam net',
          receivedAt: DateTime(2026, 10, 5),
        ),
      ];
      await bind();
      expect(chat.friendRequests.map((r) => r.publicKey), contains(member));
      expect(chat.groupInvites, hasLength(1));

      await chat.blockPeer(member);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(chat.friendRequests.map((r) => r.publicKey), [other]);
      expect(chat.groupInvites, isEmpty);
    },
  );

  test('a blocked group member is hidden from history, search, previews and '
      'unread counts, and an unblock shows the rows again', () async {
    engineService.debugAddKnownGroupForTest('tox_1');
    await bind();
    engineService.ingestInboundGroupText(gid: 'tox_1', from: other, text: 'GM');
    engineService.ingestInboundGroupText(
      gid: 'tox_1',
      from: member,
      text: 'spam',
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));
    const id = 'group_tox_1';
    expect((await chat.loadHistory(id)).map((m) => m.text), ['GM', 'spam']);

    await chat.blockPeer(member);
    final events = <ChatMessage>[];
    final sub = chat.messageEvents.listen(events.add);
    engineService.ingestInboundGroupText(
      gid: 'tox_1',
      from: member,
      text: 'more',
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(events, isEmpty, reason: 'live rows of a blocked member');
    expect((await chat.loadHistory(id)).map((m) => m.text), ['GM']);
    final visible = await chat.loadHistory(id);
    expect((await chat.loadAround(id, visible.single.id)).map((m) => m.text), [
      'GM',
    ]);
    final hits = await chat.searchMessages(
      id,
      const MessageSearchQuery(text: 'spam'),
    );
    expect(hits.results, isEmpty);
    final row = chat.conversations.singleWhere((c) => c.id == id);
    expect(row.lastMessage?.text, 'GM');
    expect(row.unreadCount, 1);

    await chat.unblockPeer(member);
    expect(chat.blockedPeers, isEmpty);
    expect((await chat.loadHistory(id)).map((m) => m.text), [
      'GM',
      'spam',
      'more',
    ]);
    await sub.cancel();
  });

  test('a blocked key cannot be added back without unblocking', () async {
    await bind();
    await chat.blockPeer(kPeerKey);
    expect(() => chat.addFriend(kPeerToxId), throwsCode('peer_blocked'));
    expect(ffi.addedFriends, isEmpty, reason: 'refused before Tox');
    await chat.unblockPeer(kPeerKey);
    expect(chat.blockedPeers, isEmpty);
  });

  test(
    'own and malformed keys are refused; no session means not_connected',
    () async {
      expect(() => chat.blockPeer(kPeerKey), throwsCode('not_connected'));
      await bind();
      // Through the Future, like the fake.
      await expectLater(chat.blockPeer(kSelfKey), throwsCode('own_id'));
      await expectLater(chat.blockPeer('nope'), throwsCode('invalid_tox_id'));
      expect(chat.blockedPeers, isEmpty);
    },
  );

  test(
    'the blacklist survives a restart and is in place before any event',
    () async {
      await bind();
      await chat.blockPeer(member);
      engine.bind(null);
      await pumpEventQueue();
      expect(chat.blockedPeers, isEmpty, reason: 'detached');

      final restarted = await newService('identity');
      await restarted.refreshBlockedUsers(); // what login does
      // What the list holds the moment the session is published, before any
      // refresh tick or event listener runs.
      final atBind = <Set<String>>[];
      final sub = chat.sessionChanges.listen((up) {
        if (up) atBind.add(chat.blockedPeers);
      });
      engine.bind(restarted);
      await pumpEventQueue();
      expect(atBind, [
        {member},
      ], reason: 'seeded at bind');
      await sub.cancel();
      expect(
        restarted.ingestC2cText(
          peer: member.toLowerCase(),
          text: 'x',
          isSelf: false,
        ),
        isFalse,
      );
      await restarted.dispose();
    },
  );

  test('concurrent blocks are serialised and both persist', () async {
    await bind();
    await Future.wait([chat.blockPeer(member), chat.blockPeer(other)]);
    expect(chat.blockedPeers, {member, other});
    final stored = await Tim2ToxPreferencesAdapter(
      store,
      accountPrefix: '1111111111111111',
    ).getBlackList(kSelfToxId);
    expect(stored, {member, other});
  });

  test('a detach during a block never publishes into the next view', () async {
    await bind();
    store.holdOnlyKeyContaining = 'black_list';
    store.holdSetStringList = Completer<void>();
    final pending = expectLater(
      chat.blockPeer(member),
      throwsCode('not_connected'),
    );
    await store.heldStringList.future;
    engine.bind(null);
    await pumpEventQueue();
    store.holdSetStringList!.complete();
    store.holdSetStringList = null;
    await pending;
    expect(chat.blockedPeers, isEmpty, reason: 'detached view stays empty');
  });

  test(
    'a friend not published yet is still removed, and never listed',
    () async {
      await bind();
      // Native knows the friend; the published list is refreshed only on the
      // next tick.
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: true));
      expect(chat.friends, isEmpty);
      await chat.blockPeer(kPeerKey);
      expect(ffi.deletedFriends, [kPeerKey]);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(chat.friends, isEmpty, reason: 'blocked keys are filtered');
    },
  );
}
