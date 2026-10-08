import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/prefs_adapter.dart';
import 'package:ditmesh_chat/src/chat/friend_request_store.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import 'helpers/fakes.dart';

class _FailingReplacementStore implements IdentityDataStore {
  @override
  Future<void> flush() async {}

  @override
  Future<void> prepareForReplacement() async =>
      throw StateError('cannot replace');
}

/// Drives the real `FfiChatService` (Tim2Tox's Dart layer: history, offline
/// queue, unread barrier) over a binding fake, the way toxee's
/// `ffi_chat_service_*_test.dart` files do. Nothing here needs the native
/// library.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');

  late Directory tempRoot;
  late FakeTim2ToxFfi ffi;
  late HoldingKeyValueStore store;
  late FfiChatService engineService;
  late FakeChatEngine engine;
  late FakeIdentityService identity;
  late Tim2ToxChatService chat;

  const prefix = '1111111111111111';

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ditmesh_chat_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (_) async => tempRoot.path);
    ffi = FakeTim2ToxFfi();
    store = HoldingKeyValueStore();
    engineService = await newEngineService(ffi, store, tempRoot, 'identity');
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

  Future<void> bind() async {
    engine.bind(engineService);
    await pumpEventQueue();
    // Let the first refresh tick run.
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  Matcher throwsCode(String code) =>
      throwsA(isA<ChatException>().having((e) => e.code, 'code', code));

  test(
    'before connect: reads are empty, mutations throw not_connected',
    () async {
      expect(chat.friends, isEmpty);
      expect(chat.conversations, isEmpty);
      expect(chat.groups, isEmpty);
      expect(chat.maxMessageBytes, 1322);
      expect(
        () => chat.sendText('c2c_$kPeerKey', 'hi'),
        throwsCode('not_connected'),
      );
      expect(() => chat.addFriend(kPeerToxId), throwsCode('not_connected'));
      expect(
        () => chat.loadHistory('c2c_$kPeerKey'),
        throwsCode('not_connected'),
      );
      // Streams replay the current (empty) value to late listeners.
      expect(await chat.friendChanges.first, isEmpty);
    },
  );

  test('the outbox is unknown while detached and read from the bound queue', () async {
    expect(chat.pendingOutbox(), isNull);
    await bind();
    expect(chat.pendingOutbox(), PendingOutboxSummary.empty);
    engine.bind(null);
    await pumpEventQueue();
    expect(chat.pendingOutbox(), isNull, reason: 'a detached identity');
  });

  test(
    'friends and requests are derived from the engine on each tick',
    () async {
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
      ffi.applications.add((userId: 'a' * 64, wording: 'CQ?'));
      await bind();
      expect(chat.friends, hasLength(1));
      expect(chat.friends.single.publicKey, kPeerKey);
      expect(chat.friends.single.displayName, 'W1AW');
      expect(chat.friends.single.online, isFalse);
      expect(chat.friendRequests.single.publicKey, 'A' * 64);
      expect(chat.friendRequests.single.message, 'CQ?');
      // A friend with no history still yields a conversation.
      expect(_peers(chat).map((c) => c.id), ['c2c_$kPeerKey']);
      expect(_peers(chat).single.title, 'W1AW');
      expect(_peers(chat).single.lastMessage, isNull);
    },
  );

  test('pending friend requests survive a fresh native session', () async {
    ffi.applications.add((userId: 'a' * 64, wording: 'CQ?'));
    await bind();
    final seen = chat.friendRequests.single.receivedAt;
    await chat.dispose();
    engine.bind(null);
    ffi.applications.clear(); // Native application queue is process memory.
    chat = Tim2ToxChatService(
      engine: engine,
      identity: identity,
      store: store,
      pollInterval: const Duration(milliseconds: 50),
    );
    await bind();
    expect(chat.friendRequests, hasLength(1));
    expect(chat.friendRequests.single.publicKey, 'A' * 64);
    expect(chat.friendRequests.single.message, 'CQ?');
    expect(chat.friendRequests.single.receivedAt, seen);
    await chat.rejectFriendRequest('A' * 64);
    expect(chat.friendRequests, isEmpty);
    await chat.dispose();
    chat = Tim2ToxChatService(engine: engine, identity: identity, store: store);
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(chat.friendRequests, isEmpty);
  });

  test('a rejected sender stays out of the inbox when rewording', () async {
    ffi.applications.add((userId: 'a' * 64, wording: 'CQ?'));
    await bind();
    await chat.rejectFriendRequest('A' * 64);
    expect(chat.friendRequests, isEmpty);
    ffi.applications
      ..clear()
      ..add((userId: 'a' * 64, wording: 'PLEASE ADD ME'));
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(chat.friendRequests, isEmpty);
  });

  test('remembered requests are capped; native ones always stay', () async {
    final base = DateTime.utc(2026);
    await FriendRequestStore(store, accountPrefix: prefix).save([
      for (var i = 0; i < 120; i++)
        FriendRequest(
          publicKey: i.toRadixString(16).padLeft(64, '0').toUpperCase(),
          message: 'old $i',
          receivedAt: base.add(Duration(minutes: i)),
        ),
    ]);
    ffi.applications.add((userId: 'f' * 64, wording: 'live'));
    await bind();
    expect(chat.friendRequests, hasLength(100));
    expect(chat.friendRequests.map((r) => r.message), contains('live'));
    // The newest remembered ones survive, the oldest are dropped.
    expect(chat.friendRequests.map((r) => r.message), contains('old 119'));
    expect(chat.friendRequests.map((r) => r.message), isNot(contains('old 0')));
  });

  test(
    'flush checkpoints friend requests received between polling ticks',
    () async {
      await bind();
      ffi.applications.add((userId: 'a' * 64, wording: 'before suspension'));
      await chat.flush();
      expect(
        store.getStringList('ditmesh_pending_friend_requests_$prefix'),
        contains(contains('before suspension')),
      );
    },
  );

  test(
    'aborted replacement rebinds chat to the preserved live engine',
    () async {
      final realIdentity = Tim2ToxIdentityService(
        paths: IdentityPaths('${tempRoot.path}/identity'),
        engine: engine,
        crypto: FakeProfileCrypto(),
        verifier: PasswordVerifier(MemorySecureStore(), iterations: 10),
        store: store,
      );
      final guardedChat = Tim2ToxChatService(
        engine: engine,
        identity: realIdentity,
        store: store,
      );
      try {
        await realIdentity.create(displayName: 'CQ');
        engine.serviceToStart = engineService;
        await realIdentity.connect();
        await pumpEventQueue();
        realIdentity.registerDataStore(_FailingReplacementStore());
        await expectLater(realIdentity.deleteIdentity(), throwsStateError);
        await pumpEventQueue();
        await realIdentity.connect(); // Already started: no new session event.
        expect(await guardedChat.loadHistory('c2c_$kPeerKey'), isEmpty);
      } finally {
        await guardedChat.dispose();
        await realIdentity.disconnect();
        await realIdentity.dispose();
      }
    },
  );

  test(
    'sendText to an offline friend queues a pending row and updates the list',
    () async {
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
      await bind();
      final events = <ChatMessage>[];
      final sub = chat.messageEvents.listen(events.add);

      final row = await chat.sendText('c2c_$kPeerKey', 'CQ CQ DE ME');
      expect(row.status, MessageStatus.pending);
      expect(row.isMine, isTrue);
      expect(row.conversationId, 'c2c_$kPeerKey');
      expect(row.senderId, kSelfKey);
      expect(row.senderName, 'me');
      expect(row.text, 'CQ CQ DE ME');
      await pumpEventQueue();
      expect(events.map((e) => e.id), contains(row.id));
      expect(events.single.status, MessageStatus.pending);

      final conv = _peers(chat).single;
      expect(conv.lastMessage?.id, row.id);
      expect(conv.lastMessage?.status, MessageStatus.pending);
      expect(conv.unreadCount, 0);

      final history = await chat.loadHistory('c2c_$kPeerKey');
      expect(history.map((m) => m.id), [row.id]);
      await sub.cancel();
    },
  );

  test(
    'sendText enforces the Tox byte budget and rejects empty text',
    () async {
      await bind();
      expect(
        () => chat.sendText('c2c_$kPeerKey', 'ä' * 700), // 1400 bytes
        throwsCode('message_too_long'),
      );
      expect(
        () => chat.sendText('c2c_$kPeerKey', '   '),
        throwsCode('empty_message'),
      );
      // 1322 bytes exactly is allowed.
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
      final row = await chat.sendText('c2c_$kPeerKey', 'x' * 1322);
      expect(row.status, MessageStatus.pending);
    },
  );

  test(
    'inbound messages surface as received rows with unread counts',
    () async {
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: true));
      await bind();
      final events = <ChatMessage>[];
      final sub = chat.messageEvents.listen(events.add);
      engineService.ingestC2cText(peer: kPeerKey, text: 'QRZ?', isSelf: false);
      await pumpEventQueue();
      expect(events, hasLength(1));
      expect(events.single.status, MessageStatus.received);
      expect(events.single.isMine, isFalse);
      expect(events.single.senderId, kPeerKey);
      expect(events.single.senderName, 'W1AW');
      expect(events.single.conversationId, 'c2c_$kPeerKey');
      expect(_peers(chat).single.unreadCount, 1);

      await chat.markRead('c2c_$kPeerKey');
      expect(_peers(chat).single.unreadCount, 0);
      await sub.cancel();
    },
  );

  test('pinned, draft, delete and hidden-until-next-message', () async {
    ffi.friends
      ..add((userId: kPeerKey, nick: 'W1AW', online: false))
      ..add((userId: 'b' * 64, nick: 'Bob', online: false));
    await bind();
    engineService.ingestC2cText(peer: kPeerKey, text: 'newest', isSelf: false);
    await pumpEventQueue();
    expect(_peers(chat).first.id, 'c2c_$kPeerKey', reason: 'newest first');

    await chat.setPinned('c2c_${'B' * 64}', true);
    expect(_peers(chat).first.id, 'c2c_${'B' * 64}', reason: 'pinned first');
    expect(_peers(chat).first.pinned, isTrue);
    await chat.setDraft('c2c_${'B' * 64}', 'de me k');
    expect(_peers(chat).first.draft, 'de me k');

    await chat.deleteConversation('c2c_$kPeerKey');
    expect(_peers(chat).map((c) => c.id), ['c2c_${'B' * 64}']);
    expect(await chat.loadHistory('c2c_$kPeerKey'), isEmpty);
    // A new message brings the conversation back.
    engineService.ingestC2cText(peer: kPeerKey, text: 'again', isSelf: false);
    await pumpEventQueue();
    expect(_peers(chat).map((c) => c.id), contains('c2c_$kPeerKey'));

    // Metadata survives a new service instance over the same store.
    final again = Tim2ToxChatService(
      engine: engine,
      identity: identity,
      store: store,
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(
      again.conversations.firstWhere((c) => c.id == 'c2c_${'B' * 64}').pinned,
      isTrue,
    );
    await again.dispose();
  });

  test(
    'groups map from Tim2Tox known groups + local name/kind records',
    () async {
      final prefs = Tim2ToxPreferencesAdapter(store, accountPrefix: prefix);
      await prefs.setGroupName('tox_1', 'Net 40m');
      await prefs.setGroupType('tox_1', 'conference');
      await prefs.setGroupName('tox_2', 'NGC room');
      engineService
        ..debugAddKnownGroupForTest('tox_1')
        ..debugAddKnownGroupForTest('tox_2');
      await bind();
      expect(chat.groups.map((g) => g.id), ['tox_1', 'tox_2']);
      final conf = chat.groups.first;
      expect(conf.name, 'Net 40m');
      expect(conf.kind, GroupKind.conference);
      expect(conf.chatId, isNull);
      final ngc = chat.groups.last;
      expect(ngc.kind, GroupKind.group, reason: 'default kind is NGC');
      expect(ngc.name, 'NGC room');
      expect(_peers(chat).map((c) => c.id).toSet(), {
        'group_tox_1',
        'group_tox_2',
      });
      expect(
        chat.conversations.firstWhere((c) => c.id == 'group_tox_1').kind,
        ConversationKind.group,
      );
      expect(
        chat.conversations.firstWhere((c) => c.id == 'group_tox_1').title,
        'Net 40m',
      );
      expect(chat.groupInvites, isEmpty);
      expect(() => chat.groupMembers('tox_404'), throwsCode('group_not_found'));
      expect(
        () => chat.inviteToGroup('tox_404', kPeerKey),
        throwsCode('group_not_found'),
      );
    },
  );

  test('inviting an offline friend is queued locally, not sent', () async {
    ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
    engineService.debugAddKnownGroupForTest('tox_1');
    await bind();
    await chat.inviteToGroup('tox_1', kPeerToxId);
    final meta = ConversationMetaStoreProbe(store, prefix);
    expect(meta.queuedGroupsFor(kPeerKey), ['tox_1']);
  });

  test('addFriend validates before touching Tox', () async {
    await bind();
    expect(() => chat.addFriend('nope'), throwsCode('invalid_tox_id'));
    expect(() => chat.addFriend(kSelfToxId), throwsCode('own_id'));
    ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(() => chat.addFriend(kPeerToxId), throwsCode('already_friend'));
  });

  test(
    'detaching the session empties the lists and blocks mutations',
    () async {
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
      await bind();
      expect(chat.friends, isNotEmpty);
      engine.bind(null);
      await pumpEventQueue();
      expect(chat.friends, isEmpty);
      expect(chat.conversations, isEmpty);
      expect(
        () => chat.sendText('c2c_$kPeerKey', 'x'),
        throwsCode('not_connected'),
      );
    },
  );

  // The next four tests park a real `await` (Tim2Tox's nickname cache write
  // inside getFriendList, or our own meta-store writes) with
  // HoldingKeyValueStore, detach or rebind underneath it, then release it.

  test('a refresh still in flight at detach publishes nothing', () async {
    ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
    store.holdSetString = Completer<void>();
    engine.bind(engineService);
    await pumpEventQueue();
    expect(
      chat.friends,
      isEmpty,
      reason: 'tick is parked inside getFriendList',
    );
    engine.bind(null);
    await pumpEventQueue();
    store.holdSetString!.complete();
    store.holdSetString = null;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(chat.friends, isEmpty);
    expect(chat.conversations, isEmpty);
    expect(await chat.friendChanges.first, isEmpty);
  });

  test(
    'a rebind refreshes at once while the old session tick is parked',
    () async {
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
      store.holdSetString = Completer<void>();
      engine.bind(engineService);
      await pumpEventQueue();
      expect(chat.friends, isEmpty, reason: 'old tick is parked');

      final ffi2 = FakeTim2ToxFfi()
        ..friends.add((userId: '3' * 64, nick: 'K1AA', online: false));
      final service2 = await newEngineService(
        ffi2,
        MemoryKeyValueStore(),
        tempRoot,
        'identity2',
      );
      engine.bind(service2);
      await pumpEventQueue();
      expect(
        chat.friends.map((f) => f.displayName),
        ['K1AA'],
        reason: 'the new session must not wait for the old tick',
      );

      store.holdSetString!.complete();
      store.holdSetString = null;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        chat.friends.map((f) => f.displayName),
        ['K1AA'],
        reason: 'the old session result is discarded',
      );
      expect(_peers(chat).map((c) => c.title), ['K1AA']);
      engine.bind(null);
      await pumpEventQueue();
      await service2.dispose();
    },
  );

  test(
    'a mutation that outlives the session throws not_connected and stops',
    () async {
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
      await bind();
      store.holdSetStringList = Completer<void>();
      // clearC2CHistory (file IO) runs, then setPinned parks on the hold.
      final pending = expectLater(
        chat.deleteConversation('c2c_$kPeerKey'),
        throwsCode('not_connected'),
      );
      await store.heldStringList.future;
      engine.bind(null);
      await pumpEventQueue();
      store.holdSetStringList!.complete();
      store.holdSetStringList = null;
      await pending;
      final meta = ConversationMetaStoreProbe(store, prefix);
      expect(meta.hidden, isEmpty, reason: 'hide() must not run after detach');
      expect(store.stringListWrites, lessThanOrEqualTo(1));
    },
  );

  test(
    'an answer queued behind a refresh throws not_connected after detach',
    () async {
      await bind();
      ffi.applications.add((userId: kPeerKey, wording: 'CQ?'));
      store.holdSetStringList = Completer<void>();
      // The tick's request refresh parks on the hold while saving the new
      // request; the accept queues behind it.
      await store.heldStringList.future;
      final accepted = expectLater(
        chat.acceptFriendRequest(kPeerKey),
        throwsCode('not_connected'),
      );
      engine.bind(null);
      await pumpEventQueue();
      store.holdSetStringList!.complete();
      store.holdSetStringList = null;
      await accepted;
    },
  );

  test(
    'flush (and so delete/import) survives a failing request refresh',
    () async {
      await bind();
      ffi.failApplications = true;
      await chat.flush();
      await chat.prepareForReplacement();
      expect(chat.conversations, isEmpty);
    },
  );

  test(
    'queued-invite flush stops at detach instead of editing the queue',
    () async {
      await store.setStringList('ditmesh_queued_group_invites_$prefix', [
        'tox_x\t$kPeerKey',
        'tox_y\t$kPeerKey',
      ]);
      // Neither group is known, so each iteration only dequeues (no native
      // invite); the first dequeue parks on the hold.
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: true));
      store.holdSetStringList = Completer<void>();
      engine.bind(engineService);
      await store.heldStringList.future;
      engine.bind(null);
      await pumpEventQueue();
      store.holdSetStringList!.complete();
      store.holdSetStringList = null;
      await pumpEventQueue();
      final meta = ConversationMetaStoreProbe(store, prefix);
      expect(
        meta.queuedGroupsFor(kPeerKey),
        ['tox_y'],
        reason: 'the loop must re-check the session before the next entry',
      );
    },
  );

  test('a slow queued-invite flush does not stall the refresh rounds', () async {
    await store.setStringList('ditmesh_queued_group_invites_$prefix', [
      'tox_x\t$kPeerKey',
    ]);
    ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: true));
    // Only the queue write parks; the request store keeps saving.
    store
      ..holdOnlyKeyContaining = 'queued_group_invites'
      ..holdSetStringList = Completer<void>();
    engine.bind(engineService);
    await store.heldStringList.future;
    ffi.applications.add((userId: 'a' * 64, wording: 'CQ?'));
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(chat.friendRequests.map((r) => r.message), ['CQ?']);
    store.holdSetStringList!.complete();
    store
      ..holdSetStringList = null
      ..holdOnlyKeyContaining = null;
    await pumpEventQueue();
    expect(
      ConversationMetaStoreProbe(store, prefix).queuedGroupsFor(kPeerKey),
      isEmpty,
    );
  });

  test(
    'forgetting a removed friend stops between its writes at detach',
    () async {
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
      await bind();
      final id = 'c2c_$kPeerKey';
      await store.setStringList('ditmesh_hidden_conversations_$prefix', [id]);
      await store.setString('ditmesh_draft_${id}_$prefix', 'CQ');
      // Tim2Tox's own local-friends write goes through; forget()'s first
      // write (the pinned set) parks on the hold.
      store.holdOnlyKeyContaining = 'ditmesh_pinned';
      store.holdSetStringList = Completer<void>();
      final pending = expectLater(
        chat.removeFriend(kPeerKey),
        throwsCode('not_connected'),
      );
      await store.heldStringList.future;
      engine.bind(null);
      await pumpEventQueue();
      store.holdSetStringList!.complete();
      store.holdSetStringList = null;
      await pending;
      expect(ffi.deletedFriends, [kPeerKey]);
      final meta = ConversationMetaStoreProbe(store, prefix);
      expect(meta.pinned, isEmpty);
      expect(meta.draft(id), 'CQ', reason: 'draft write must not follow');
      expect(meta.hidden, [id], reason: 'unhide must not follow the detach');
    },
  );
}

/// Reads the queued-invite slot the way `ConversationMetaStore` writes it.
class ConversationMetaStoreProbe {
  ConversationMetaStoreProbe(this._store, this._prefix);
  final KeyValueStore _store;
  final String _prefix;

  List<String> get hidden =>
      _store.getStringList('ditmesh_hidden_conversations_$_prefix') ?? [];

  List<String> get pinned =>
      _store.getStringList('ditmesh_pinned_conversations_$_prefix') ?? [];

  String? draft(String conversationId) =>
      _store.getString('ditmesh_draft_${conversationId}_$_prefix');

  List<String> queuedGroupsFor(String friendKey) => [
    for (final e
        in _store.getStringList('ditmesh_queued_group_invites_$_prefix') ?? [])
      if (e.endsWith('\t$friendKey')) e.substring(0, e.indexOf('\t')),
  ];
}

/// Every conversation but the always-present note to self.
List<Conversation> _peers(ChatService chat) =>
    chat.conversations.where((c) => !c.isSelf).toList();
