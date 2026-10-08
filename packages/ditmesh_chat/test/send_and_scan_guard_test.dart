import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/prefs_adapter.dart';
import 'package:ditmesh_chat/src/engine/ditmesh_ffi_chat_service.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:tim2tox_dart/models/chat_message.dart' as t2t;
import 'package:tim2tox_dart/models/send_control_result.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import 'helpers/fakes.dart';

/// Tim2Tox whose next [failCancels] withdrawals cannot be persisted.
class _FlakyCancel extends DitmeshFfiChatService {
  _FlakyCancel({
    super.preferencesService,
    super.historyDirectory,
    super.queueFilePath,
    super.fileRecvPath,
    super.avatarsPath,
    super.ffiForTesting,
  });

  int failCancels = 0;

  /// The next cancels answer notApplicable and leave the row queued, as
  /// while another cancel of it is still persisting.
  int busyCancels = 0;

  /// Runs after a C2C text is queued, before the send returns.
  Future<void> Function()? afterSend;

  @override
  Future<t2t.ChatMessage> sendTextWithResult(
    String peerId,
    String text, {
    String? cloudCustomData,
    String? clientMessageID,
  }) async {
    final row = await super.sendTextWithResult(
      peerId,
      text,
      cloudCustomData: cloudCustomData,
      clientMessageID: clientMessageID,
    );
    await afterSend?.call();
    return row;
  }

  @override
  Future<SendControlResult> cancelQueuedMessage(
    String conversation,
    String msgID, {
    bool isGroup = false,
  }) async {
    if (failCancels > 0) {
      failCancels--;
      return SendControlResult.persistFailed;
    }
    if (busyCancels > 0) {
      busyCancels--;
      return SendControlResult.notApplicable;
    }
    return super.cancelQueuedMessage(conversation, msgID, isGroup: isGroup);
  }
}

/// A store whose list writes to keys containing [failKey] fail (nothing
/// is written, as SharedPreferences reloads its cache after a failure).
class _FailingStore extends HoldingKeyValueStore {
  String? failKey;

  @override
  Future<void> setStringList(String key, List<String> value) {
    final fail = failKey;
    if (fail != null && key.contains(fail)) {
      return Future<void>.error(StateError('fake: write failed'));
    }
    return super.setStringList(key, value);
  }
}

/// M1: a C2C send needs a friend (native list) who is not blocked, and a
/// removal that races the send leaves nothing queued. M4: a history search
/// stays bound to its session and the blacklist through its filtering
/// phase, not only through the scan that maps the rows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  const String member =
      '3333333333333333333333333333333333333333333333333333333333333333';
  const String other =
      '4444444444444444444444444444444444444444444444444444444444444444';
  const String dm = 'c2c_$kPeerKey';

  late Directory tempRoot;
  late FakeTim2ToxFfi ffi;
  late _FailingStore store;
  late FfiChatService engineService;
  late FakeChatEngine engine;
  late FakeIdentityService identity;
  late Tim2ToxChatService chat;
  final List<FfiChatService> extra = [];

  Future<FfiChatService> newService(String dir, {bool flaky = false}) async {
    final paths = IdentityPaths('${tempRoot.path}/$dir');
    await paths.ensureDirectories();
    final make = flaky ? _FlakyCancel.new : DitmeshFfiChatService.new;
    return make(
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
      ..debugNativePendingInvitesOverride = () => const [];
  }

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ditmesh_guard_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (_) async => tempRoot.path);
    ffi = FakeTim2ToxFfi();
    store = _FailingStore();
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
    Tim2ToxChatService.debugScanYield = null;
    await chat.dispose();
    await engine.dispose();
    await identity.dispose();
    await engineService.dispose();
    for (final s in extra) {
      await s.dispose();
    }
    extra.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, null);
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  Future<void> bind() async {
    engine.bind(engineService);
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  Matcher throwsCode(String code) =>
      throwsA(isA<ChatException>().having((e) => e.code, 'code', code));

  List<Object?> queued() =>
      engineService.offlineMessageQueuePersistence.getMessages(kPeerKey);

  group('sendText target (M1)', () {
    test(
      'a key that was never a friend is refused and nothing is queued',
      () async {
        await bind();
        await expectLater(chat.sendText(dm, 'CQ'), throwsCode('not_friend'));
        expect(queued(), isEmpty);
        expect(ffi.sentTextPeers, isEmpty);
        expect(await chat.loadHistory(dm), isEmpty);
        expect(chat.pendingOutbox()?.count, 0);
      },
    );

    test('a removed friend is refused', () async {
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
      await bind();
      await chat.removeFriend(kPeerKey);
      ffi.friends.clear(); // what native lists after the delete
      await expectLater(chat.sendText(dm, 'CQ'), throwsCode('not_friend'));
      expect(queued(), isEmpty);
    });

    test('the native list decides, not the published one (an outgoing '
        'request, or the first tick not run yet)', () async {
      await bind();
      ffi.friends.add((userId: kPeerKey, nick: '', online: false));
      expect(chat.friends, isEmpty, reason: 'no refresh tick yet');
      final row = await chat.sendText(dm, 'CQ');
      expect(row.status, MessageStatus.pending);
      expect(queued(), hasLength(1));
    });

    test('a blocked key is refused with peer_blocked', () async {
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
      await bind();
      await chat.blockPeer(kPeerKey);
      await expectLater(chat.sendText(dm, 'CQ'), throwsCode('peer_blocked'));
      expect(queued(), isEmpty);
    });

    test('a removal racing the send leaves nothing queued', () async {
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
      await bind();
      final send = chat.sendText(dm, 'CQ');
      ffi.friends.clear();
      final removal = chat.removeFriend(kPeerKey);
      await expectLater(send, throwsCode('not_friend'));
      await removal;
      expect(queued(), isEmpty);
      expect(chat.pendingOutbox()?.count, 0);
    });

    test('a send started while a removal is running is refused', () async {
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
      await bind();
      final removal = chat.removeFriend(kPeerKey);
      // Native still lists the friend until the delete lands.
      await expectLater(chat.sendText(dm, 'CQ'), throwsCode('not_friend'));
      ffi.friends.clear();
      await removal;
      expect(queued(), isEmpty);
    });

    test('a withdrawal that cannot be persisted fails the send and is '
        'retried in the background', () async {
      final flaky = await newService('flaky', flaky: true) as _FlakyCancel;
      extra.add(flaky);
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
      engine.bind(flaky);
      await pumpEventQueue();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      flaky.failCancels = 1;
      // The friend is removed after the row was queued, before the send
      // returned: the post-send check has to withdraw it.
      Future<void>? removal;
      flaky.afterSend = () async {
        ffi.friends.clear();
        removal = chat.removeFriend(kPeerKey);
      };
      await expectLater(chat.sendText(dm, 'CQ'), throwsCode('send_failed'));
      final queue = flaky.offlineMessageQueuePersistence;
      expect(queue.getMessages(kPeerKey), hasLength(1));
      // The next refresh rounds withdraw it (the native delete is still
      // running: Tim2Tox's removeFriend takes over half a second).
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(queue.getMessages(kPeerKey), isEmpty);
      await removal;
    });

    test('a pending withdrawal survives a disconnect and is finished in the '
        'next session of the identity', () async {
      final flaky = await newService('flaky2', flaky: true) as _FlakyCancel;
      extra.add(flaky);
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
      engine.bind(flaky);
      await pumpEventQueue();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      flaky.failCancels = 1 << 20; // the outbox keeps refusing
      Future<void>? removal;
      flaky.afterSend = () async {
        ffi.friends.clear();
        removal = chat.removeFriend(kPeerKey);
      };
      await expectLater(chat.sendText(dm, 'CQ'), throwsCode('send_failed'));
      await removal?.catchError((Object _) {});
      final queue = flaky.offlineMessageQueuePersistence;
      expect(queue.getMessages(kPeerKey), hasLength(1));
      engine.bind(null);
      await pumpEventQueue();
      flaky.failCancels = 0;
      engine.bind(flaky);
      await pumpEventQueue();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(queue.getMessages(kPeerKey), isEmpty);
    });

    /// Binds a [_FlakyCancel] session and refuses a send to a friend
    /// removed while it was being queued, with the first [failures]
    /// withdrawals unable to persist.
    Future<_FlakyCancel> refusedSend(String dir, int failures) async {
      final flaky = await newService(dir, flaky: true) as _FlakyCancel;
      extra.add(flaky);
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
      engine.bind(flaky);
      await pumpEventQueue();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      flaky.failCancels = failures;
      Future<void>? removal;
      flaky.afterSend = () async {
        ffi.friends.clear();
        removal = chat.removeFriend(kPeerKey);
      };
      await expectLater(chat.sendText(dm, 'CQ'), throwsCode('send_failed'));
      unawaited(removal?.catchError((Object _) {}));
      return flaky;
    }

    List<String> recorded() =>
        store.getStringList('ditmesh_pending_withdrawals_1111111111111111') ??
        const [];

    test('a withdrawal whose record cannot be written either is kept in '
        'memory and finished once storage recovers', () async {
      store.failKey = 'ditmesh_pending_withdrawals';
      final flaky = await refusedSend('flaky3', 1 << 20);
      final queue = flaky.offlineMessageQueuePersistence;
      expect(recorded(), isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(queue.getMessages(kPeerKey), hasLength(1));
      store.failKey = null;
      flaky.failCancels = 0;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(queue.getMessages(kPeerKey), isEmpty);
      expect(recorded(), isEmpty);
    });

    test('a cancel that answers notApplicable while the row is still '
        'queued keeps the record', () async {
      final flaky = await refusedSend('flaky4', 1);
      flaky.busyCancels = 3;
      final queue = flaky.offlineMessageQueuePersistence;
      expect(recorded(), hasLength(1));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(queue.getMessages(kPeerKey), hasLength(1));
      expect(recorded(), hasLength(1));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(queue.getMessages(kPeerKey), isEmpty);
      expect(recorded(), isEmpty);
    });

    test(
      'removing a friend withdraws what was already queued for them',
      () async {
        ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
        await bind();
        final row = await chat.sendText(dm, 'CQ');
        expect(row.status, MessageStatus.pending);
        expect(queued(), hasLength(1));
        ffi.friends.clear();
        await chat.removeFriend(kPeerKey);
        expect(queued(), isEmpty);
        expect(chat.pendingOutbox()?.count, 0);
      },
    );

    test(
      'blocking a friend withdraws what was already queued for them',
      () async {
        ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
        await bind();
        await chat.sendText(dm, 'CQ');
        await chat.blockPeer(kPeerKey);
        expect(queued(), isEmpty);
      },
    );

    test('a removal whose withdrawal cannot persist finishes it in the '
        'background', () async {
      final flaky = await newService('flaky5', flaky: true) as _FlakyCancel;
      extra.add(flaky);
      ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
      engine.bind(flaky);
      await pumpEventQueue();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await chat.sendText(dm, 'CQ');
      flaky.failCancels = 1;
      ffi.friends.clear();
      await chat.removeFriend(kPeerKey);
      final queue = flaky.offlineMessageQueuePersistence;
      expect(recorded(), hasLength(1));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(queue.getMessages(kPeerKey), isEmpty);
      expect(recorded(), isEmpty);
    });

    test('the note to self needs no friend', () async {
      await bind();
      final row = await chat.sendText(chat.selfConversationId!, 'note');
      expect(row.status, MessageStatus.sent);
    });
  });

  group('search filtering phase (M4)', () {
    const String gid = 'group_tox_1';

    Future<void> seed() async {
      engineService.debugAddKnownGroupForTest('tox_1');
      await bind();
      // Over one 500-row chunk, so the filter phase yields mid-way.
      for (var i = 0; i < 620; i++) {
        engineService.ingestInboundGroupText(
          gid: 'tox_1',
          from: i.isEven ? other : member,
          text: 'CQ $i',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    test(
      'a peer blocked while the matches are filtered is not returned',
      () async {
        await seed();
        var blocked = false;
        Tim2ToxChatService.debugScanYield = (phase) async {
          if (phase == 'filter' && !blocked) {
            blocked = true;
            await chat.blockPeer(member);
          }
        };
        final page = await chat.searchMessages(
          gid,
          const MessageSearchQuery(text: 'CQ'),
          limit: 1000,
        );
        expect(blocked, isTrue, reason: 'the hook ran in the filter phase');
        expect(page.results, isNotEmpty);
        expect(page.results.where((m) => m.senderId == member), isEmpty);
      },
    );

    test('a detach while the matches are filtered fails the search', () async {
      await seed();
      var detached = false;
      Tim2ToxChatService.debugScanYield = (phase) async {
        if (phase == 'filter' && !detached) {
          detached = true;
          engine.bind(null);
          await pumpEventQueue();
        }
      };
      await expectLater(
        chat.searchMessages(gid, const MessageSearchQuery(text: 'CQ')),
        throwsCode('not_connected'),
      );
      expect(detached, isTrue);
    });

    test(
      'a rebind to another session while filtering fails the search',
      () async {
        await seed();
        final next = await newService('identity2');
        extra.add(next);
        var rebound = false;
        Tim2ToxChatService.debugScanYield = (phase) async {
          if (phase == 'filter' && !rebound) {
            rebound = true;
            engine.bind(next);
            await pumpEventQueue();
          }
        };
        await expectLater(
          chat.searchMessages(gid, const MessageSearchQuery(text: 'CQ')),
          throwsCode('not_connected'),
        );
        expect(rebound, isTrue);
      },
    );
  });
}
