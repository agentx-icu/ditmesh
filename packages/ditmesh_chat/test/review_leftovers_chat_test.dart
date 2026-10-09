import 'dart:async';
import 'dart:io';

import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/prefs_adapter.dart';
import 'package:ditmesh_chat/src/engine/ditmesh_ffi_chat_service.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import 'helpers/fakes.dart';

/// Low findings of the 2026-10-08 chat review in [Tim2ToxChatService] (L14,
/// L15, L17, L18) and the test gaps it listed: dispose with work in flight
/// and the reconnect drain, over the real `FfiChatService` Dart layer.

const _other =
    '4444444444444444444444444444444444444444444444444444444444444444';

/// A session whose friend-list reads, friend removals and invite reads can
/// be held or failed by the test.
class _HeldService extends DitmeshFfiChatService {
  _HeldService({
    required super.preferencesService,
    required super.historyDirectory,
    required super.queueFilePath,
    required super.fileRecvPath,
    required super.avatarsPath,
    required super.ffiForTesting,
  });

  /// One-shot: the next friend-list read takes its snapshot, then waits.
  Completer<void>? holdFriendList;
  final Completer<void> friendListHeld = Completer<void>();

  Completer<void>? holdRemove;
  final Completer<void> removeHeld = Completer<void>();
  bool failRemove = false;

  bool failInvites = false;
  final StreamController<void> invitesChanged =
      StreamController<void>.broadcast();

  @override
  Future<List<({String userId, String nickName, String status, bool online})>>
  getFriendList() async {
    final raw = await super.getFriendList();
    final hold = holdFriendList;
    if (hold != null) {
      holdFriendList = null;
      if (!friendListHeld.isCompleted) friendListHeld.complete();
      await hold.future;
    }
    return raw;
  }

  @override
  Future<void> removeFriend(String userId) async {
    final hold = holdRemove;
    if (hold != null) {
      holdRemove = null;
      if (!removeHeld.isCompleted) removeHeld.complete();
      await hold.future;
    }
    if (failRemove) throw StateError('native removal failed');
    await super.removeFriend(userId);
  }

  @override
  List<PendingGroupInvite> getPendingGroupInvites() {
    if (failInvites) throw StateError('invite read failed');
    return super.getPendingGroupInvites();
  }

  @override
  Stream<void> get pendingGroupInvitesChanged => invitesChanged.stream;

  @override
  Future<void> dispose() async {
    await invitesChanged.close();
    await super.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  const cid = 'c2c_$kPeerKey';

  late Directory tempRoot;
  late FakeTim2ToxFfi ffi;
  late HoldingKeyValueStore store;
  late _HeldService svc;
  late FakeChatEngine engine;
  late FakeIdentityService identity;
  late Tim2ToxChatService chat;
  late List<ChatLogRecord> logs;
  var invites = <PendingGroupInvite>[];
  var chatDisposed = false;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ditmesh_leftovers_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (_) async => tempRoot.path);
    ffi = FakeTim2ToxFfi();
    invites = [];
    logs = [];
    chatDisposed = false;
    store = HoldingKeyValueStore();
    final paths = IdentityPaths('${tempRoot.path}/identity');
    await paths.ensureDirectories();
    svc =
        _HeldService(
            preferencesService: Tim2ToxPreferencesAdapter(
              store,
              accountPrefix: '1111111111111111',
            ),
            historyDirectory: paths.historyDirectory,
            queueFilePath: paths.offlineQueueFile,
            fileRecvPath: paths.fileRecvDirectory,
            avatarsPath: paths.avatarsDirectory,
            ffiForTesting: ffi,
          )
          ..debugBeginSessionForTest()
          ..debugNativePendingInvitesOverride = () => invites;
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
      logger: CallbackChatLogger(logs.add),
      pollInterval: const Duration(milliseconds: 50),
    );
  });

  tearDown(() async {
    if (!chatDisposed) await chat.dispose();
    await engine.dispose();
    await identity.dispose();
    await svc.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, null);
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  Future<void> bind() async {
    engine.bind(svc);
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  Future<void> ticks([int n = 3]) =>
      Future<void>.delayed(Duration(milliseconds: 60 * n));

  Matcher throwsCode(String code) =>
      throwsA(isA<ChatException>().having((e) => e.code, 'code', code));

  Future<void> disposeChat() {
    chatDisposed = true;
    return chat.dispose();
  }

  test('L14 a failing invite refresh after a change is logged', () async {
    await bind();
    svc.failInvites = true;
    svc.invitesChanged.add(null);
    await pumpEventQueue();
    svc.failInvites = false;
    expect(
      logs.map((r) => r.message),
      contains('[Chat] invite refresh after a change failed'),
    );
  });

  group('L15 a stale friend snapshot never resurrects a removed friend', () {
    setUp(() {
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: true));
    });

    test('snapshot taken before the removal started', () async {
      await bind();
      expect(chat.friends.map((f) => f.publicKey), [kPeerKey]);
      final seen = <List<String>>[];
      final sub = chat.friendChanges.listen(
        (l) => seen.add(l.map((f) => f.publicKey).toList()),
      );
      final release = Completer<void>();
      svc.holdFriendList = release;
      await svc.friendListHeld.future; // a tick holds a snapshot with them
      ffi.friends.clear();
      await chat.removeFriend(kPeerKey);
      expect(chat.friends, isEmpty);
      seen.clear();
      release.complete();
      await ticks();
      expect(seen, everyElement(isEmpty));
      expect(chat.friends, isEmpty);
      await sub.cancel();
    });

    test('snapshot taken while the native removal ran', () async {
      await bind();
      final seen = <List<String>>[];
      final sub = chat.friendChanges.listen(
        (l) => seen.add(l.map((f) => f.publicKey).toList()),
      );
      final removal = Completer<void>();
      svc.holdRemove = removal;
      final removing = chat.removeFriend(kPeerKey);
      await svc.removeHeld.future;
      final snapshot = Completer<void>();
      svc.holdFriendList = snapshot;
      await svc.friendListHeld.future; // read during the removal
      ffi.friends.clear();
      removal.complete();
      await removing;
      expect(chat.friends, isEmpty);
      seen.clear();
      snapshot.complete();
      await ticks();
      expect(seen, everyElement(isEmpty));
      expect(chat.friends, isEmpty);
      await sub.cancel();
    });
  });

  test('L17 equal titles keep one order across rebuilds', () async {
    final keys = [
      for (var i = 0; i < 40; i++)
        (i + 0x50).toRadixString(16).toUpperCase().padLeft(2, '0') * 32,
    ];
    for (final k in keys) {
      ffi.friends.add((userId: k, nick: 'SAME', online: false));
    }
    await bind();
    await ticks();
    final first = chat.conversations.map((c) => c.id).toList();
    expect(first, hasLength(keys.length + 1)); // + the note to self
    var emissions = 0;
    final sub = chat.conversationChanges.listen((_) => emissions++);
    final friendSub = chat.friendChanges.listen((_) => emissions++);
    await pumpEventQueue(); // both streams replay their current value
    emissions = 0;
    final reversed = ffi.friends.reversed.toList();
    ffi.friends
      ..clear()
      ..addAll(reversed);
    await ticks(4);
    expect(chat.conversations.map((c) => c.id).toList(), first);
    expect(emissions, 0, reason: 'nothing changed, nothing republished');
    await sub.cancel();
    await friendSub.cancel();
  });

  test(
    'L18 a failed block cleanup still hides them from every view',
    () async {
      ffi.applications.add((userId: _other, wording: 'hi'));
      invites = [
        PendingGroupInvite(
          id: 'inv_1',
          inviterUserId: _other.toLowerCase(),
          kind: 'group',
          groupName: 'spam net',
          receivedAt: DateTime(2026, 10, 8),
        ),
      ];
      await bind();
      expect(chat.friendRequests.map((r) => r.publicKey), [_other]);
      expect(chat.groupInvites.map((i) => i.inviteId), ['inv_1']);
      // A persistent read failure: the cleanup and the request refresh
      // both fail.
      ffi.failApplications = true;
      await expectLater(chat.blockPeer(_other), throwsStateError);
      expect(chat.blockedPeers, {_other});
      expect(chat.friendRequests, isEmpty);
      expect(chat.groupInvites, isEmpty);
      ffi.failApplications = false;
    },
  );

  test(
    'L18 blocking a request only the store remembers still dismisses it',
    () async {
      ffi.applications.add((userId: _other, wording: 'hi'));
      await bind();
      expect(chat.friendRequests.map((r) => r.publicKey), [_other]);
      // Native forgot it (a restart); the store still lists it.
      ffi.applications.clear();
      await ticks();
      expect(chat.friendRequests.map((r) => r.publicKey), [_other]);
      await chat.blockPeer(_other);
      expect(chat.friendRequests, isEmpty);
      await chat.unblockPeer(_other);
      // The same sender asks again: still dismissed.
      ffi.applications.add((userId: _other, wording: 'hi again'));
      await ticks();
      expect(chat.friendRequests, isEmpty);
    },
  );

  group('dispose with work in flight', () {
    test('a refresh round in flight publishes nothing after close', () async {
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
      await bind();
      final after = <Object>[];
      final release = Completer<void>();
      svc.holdFriendList = release;
      await svc.friendListHeld.future;
      ffi.friends[0] = (userId: kPeerKey, nick: 'RENAMED', online: true);
      final subs = [
        chat.friendChanges.listen((v) => chatDisposed ? after.add(v) : null),
        chat.conversationChanges.listen(
          (v) => chatDisposed ? after.add(v) : null,
        ),
      ];
      await pumpEventQueue(); // the replays of the current values
      await disposeChat();
      release.complete();
      await ticks();
      expect(after, isEmpty, reason: '$after');
      for (final s in subs) {
        await s.cancel();
      }
    });

    test('a serialised request answer ends not_connected', () async {
      ffi.applications.add((userId: _other, wording: 'hi'));
      await bind();
      store
        ..holdOnlyKeyContaining = 'ditmesh_dismissed_friend_requests'
        ..holdSetStringList = Completer<void>();
      final rejecting = chat.rejectFriendRequest(_other);
      await store.heldStringList.future;
      final disposing = disposeChat();
      store.holdSetStringList!.complete();
      store.holdSetStringList = null;
      await expectLater(rejecting, throwsCode('not_connected'));
      await disposing;
    });

    test('a block parked in its store write ends not_connected', () async {
      await bind();
      final after = <Set<String>>[];
      final sub = chat.blockedPeerChanges.listen(
        (v) => chatDisposed ? after.add(v) : null,
      );
      store
        ..holdOnlyKeyContaining = 'black_list'
        ..holdSetStringList = Completer<void>();
      final blocking = chat.blockPeer(_other);
      await store.heldStringList.future;
      final disposing = disposeChat();
      store.holdSetStringList!.complete();
      store.holdSetStringList = null;
      await expectLater(blocking, throwsCode('not_connected'));
      await disposing;
      expect(after, isEmpty);
      await sub.cancel();
    });
  });

  test('reconnect drain: the queued row is sent once, sent emitted', () async {
    ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
    await bind();
    final events = <ChatMessage>[];
    final sub = chat.messageEvents.listen(events.add);
    final row = await chat.sendText(cid, 'QRV?');
    expect(row.status, MessageStatus.pending);
    await ticks();
    expect(ffi.sentTextPeers, isEmpty);
    // The native presence flag flips (not debugSetFriendOnline): the next
    // refresh round's friend-list read drives Tim2Tox's came-online drain.
    ffi.friends[0] = (userId: kPeerKey, nick: 'W1AW', online: true);
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!events.any(
          (e) => e.id == row.id && e.status == MessageStatus.sent,
        ) ||
        svc.offlineMessageQueuePersistence.getMessages(kPeerKey).isNotEmpty) {
      if (DateTime.now().isAfter(deadline)) fail('queued row never drained');
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(ffi.sentTextPeers, [kPeerKey]);
    await ticks(4); // more completed rounds send nothing more
    expect(ffi.sentTextPeers, [kPeerKey]);
    final history = await chat.loadHistory(cid);
    expect(history.single.id, row.id);
    expect(history.single.status, MessageStatus.sent);
    await sub.cancel();
  });
}
