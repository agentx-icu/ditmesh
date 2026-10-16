import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/prefs_adapter.dart';
import 'package:ditmesh_chat/src/chat/conversation_meta_store.dart';
import 'package:ditmesh_chat/src/chat/send_intents.dart';
import 'package:ditmesh_chat/src/engine/ditmesh_ffi_chat_service.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:tim2tox_dart/models/chat_message.dart' as t2t;
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import 'helpers/fakes.dart';

/// Tim2Tox with a hook between the commit of a C2C text and its return.
class _HookedSend extends DitmeshFfiChatService {
  _HookedSend({
    super.preferencesService,
    super.historyDirectory,
    super.queueFilePath,
    super.fileRecvPath,
    super.avatarsPath,
    super.ffiForTesting,
  });

  Future<void> Function()? afterSend;

  /// Runs when a conversation's history is loaded, before it is.
  Future<void> Function()? onLoadHistory;

  @override
  Future<void> loadHistory(String id) async {
    await onLoadHistory?.call();
    return super.loadHistory(id);
  }

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
}

/// The store as a process killed at this instant leaves it.
HoldingKeyValueStore _snapshot(KeyValueStore from) {
  final to = HoldingKeyValueStore();
  T? read<T>(T? Function(String) get, String key) {
    try {
      return get(key);
    } on TypeError {
      return null;
    }
  }

  for (final key in from.keys()) {
    final s = read(from.getString, key);
    final l = read(from.getStringList, key);
    final b = read(from.getBool, key);
    final i = read(from.getInt, key);
    if (s != null) {
      unawaited(to.setString(key, s));
    } else if (l != null) {
      unawaited(to.setStringList(key, l));
    } else if (b != null) {
      unawaited(to.setBool(key, b));
    } else if (i != null) {
      unawaited(to.setInt(key, i));
    }
  }
  return to;
}

/// A send commits its row before the composer can clear the draft it was
/// made from. Killed in between, the next start used to restore the sent
/// text as the draft while the outbox still delivered the message: sending
/// it again sent it twice (doc/VALIDATION.md "D1, draft after kill").
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  const prefix = '1111111111111111';
  const dm = 'c2c_$kPeerKey';

  late Directory tempRoot;
  late FakeTim2ToxFfi ffi;
  late HoldingKeyValueStore store;
  late _HookedSend engineService;
  late FakeChatEngine engine;
  late FakeIdentityService identity;
  late Tim2ToxChatService chat;
  final List<FfiChatService> extra = [];

  Future<_HookedSend> newService(KeyValueStore kv) async {
    final paths = IdentityPaths('${tempRoot.path}/identity');
    await paths.ensureDirectories();
    return _HookedSend(
        ffiForTesting: ffi,
        preferencesService: Tim2ToxPreferencesAdapter(
          kv,
          accountPrefix: prefix,
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
    tempRoot = await Directory.systemTemp.createTemp('ditmesh_intent_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (_) async => tempRoot.path);
    ffi = FakeTim2ToxFfi();
    store = HoldingKeyValueStore();
    engineService = await newService(store);
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
    ffi.friends.add((userId: kPeerKey, nick: 'W1AW', online: false));
    engine.bind(engineService);
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 80));
  });

  tearDown(() async {
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

  /// The next start over [kv]: the old session is gone (its history writes
  /// with it when [dropHistory]), a new one loads the same files.
  Future<_HookedSend> restart(
    KeyValueStore kv, {
    bool dropHistory = false,
  }) async {
    engine.bind(null);
    await pumpEventQueue();
    await engineService.dispose();
    final history = Directory(
      IdentityPaths('${tempRoot.path}/identity').historyDirectory,
    );
    if (dropHistory && history.existsSync()) {
      await history.delete(recursive: true);
    }
    final next = await newService(kv);
    extra.add(next);
    // What init does before the session can start (FfiChatService.init).
    await next.offlineMessageQueuePersistence.loadQueue(clearOnLoad: false);
    return next;
  }

  test('a queued send killed before the draft was cleared does not come '
      'back as the draft, also without its history row', () async {
    await chat.setDraft(dm, 'CQ DE W1AW');
    final sent = await chat.sendText(dm, 'CQ DE W1AW');
    expect(sent.status, MessageStatus.pending);
    // Killed here: sendText returned, the composer has not cleared yet.
    final disk = _snapshot(store);
    final meta = ConversationMetaStore(disk, accountPrefix: prefix);
    expect(meta.draft(dm), 'CQ DE W1AW');
    expect(meta.sendIntent(dm)?.id, sent.id);

    final next = await restart(disk, dropHistory: true);
    expect(
      next.offlineMessageQueuePersistence
          .getMessages(kPeerKey)
          .map((m) => m.msgID),
      [sent.id],
      reason: 'the message is still delivered',
    );
    await reconcileSendIntents(meta, next);
    expect(meta.draft(dm), '', reason: 'sending it again would send it twice');
    expect(meta.sendIntent(dm), isNull);
  });

  test('a delivered send is recognised by its history row', () async {
    ffi.friends
      ..clear()
      ..add((userId: kPeerKey, nick: 'W1AW', online: true));
    await chat.setDraft(dm, 'TNX');
    final sent = await chat.sendText(dm, 'TNX');
    await engineService.flushPendingHistory();
    final disk = _snapshot(store);
    final next = await restart(disk);
    expect(next.offlineMessageQueuePersistence.getMessages(kPeerKey), isEmpty);
    final meta = ConversationMetaStore(disk, accountPrefix: prefix);
    expect(meta.sendIntent(dm)?.id, sent.id);
    await reconcileSendIntents(meta, next);
    expect(meta.draft(dm), '');
  });

  test('a draft write while recovery loads the history supersedes the '
      'intent', () async {
    ffi.friends
      ..clear()
      ..add((userId: kPeerKey, nick: 'W1AW', online: true));
    await chat.setDraft(dm, 'TNX');
    await chat.sendText(dm, 'TNX');
    await engineService.flushPendingHistory();
    final disk = _snapshot(store);
    final next = await restart(disk);
    final meta = ConversationMetaStore(disk, accountPrefix: prefix);
    // Keyed again while the engine starts: drafts work without a session.
    next.onLoadHistory = () => meta.setDraft(dm, 'TNX');
    await reconcileSendIntents(meta, next);
    expect(meta.draft(dm), 'TNX');
    expect(meta.sendIntent(dm), isNull);
  });

  test('a draft write still in flight when recovery checks supersedes the '
      'intent', () async {
    ffi.friends
      ..clear()
      ..add((userId: kPeerKey, nick: 'W1AW', online: true));
    await chat.setDraft(dm, 'TNX');
    await chat.sendText(dm, 'TNX');
    await engineService.flushPendingHistory();
    final disk = _snapshot(store);
    final next = await restart(disk);
    final meta = ConversationMetaStore(disk, accountPrefix: prefix);
    Future<void>? keyed;
    next.onLoadHistory = () async {
      // Keyed again; its draft write has not completed when recovery
      // looks at the intent.
      disk
        ..holdOnlyKeyContaining = 'ditmesh_draft'
        ..holdSetString = Completer<void>();
      keyed = meta.setDraft(dm, 'TNX');
    };
    await reconcileSendIntents(meta, next);
    disk.holdSetString!.complete();
    disk.holdSetString = null;
    await keyed;
    expect(meta.draft(dm), 'TNX');
    expect(meta.sendIntent(dm), isNull);
  });

  test('flush waits for draft writes still queued behind a slow one', () async {
    store
      ..holdOnlyKeyContaining = 'ditmesh_draft'
      ..holdSetString = Completer<void>();
    final first = chat.setDraft(dm, 'A');
    await store.heldString.future;
    final second = chat.setDraft(dm, 'B');
    var flushed = false;
    final flush = chat.flush().then((_) => flushed = true);
    await pumpEventQueue();
    expect(flushed, isFalse);
    store.holdSetString!.complete();
    store.holdSetString = null;
    await flush;
    final meta = ConversationMetaStore(store, accountPrefix: prefix);
    expect(meta.draft(dm), 'B', reason: 'the barrier covers the queued write');
    await Future.wait([first, second]);
  });

  test('a send that never committed keeps its draft', () async {
    final meta = ConversationMetaStore(store, accountPrefix: prefix);
    await meta.setDraft(dm, 'CQ');
    await meta.setSendIntent(dm, 'dmt:never-queued');
    final next = await restart(store);
    await reconcileSendIntents(meta, next);
    expect(meta.draft(dm), 'CQ');
    expect(meta.sendIntent(dm), isNull);
  });

  test(
    'a draft written after the send supersedes it, even the same text',
    () async {
      await chat.setDraft(dm, 'QRZ');
      await chat.sendText(dm, 'QRZ');
      // Keyed again (away and back): a new revision of the draft.
      await chat.setDraft(dm, 'QRZ');
      final disk = _snapshot(store);
      final meta = ConversationMetaStore(disk, accountPrefix: prefix);
      expect(meta.sendIntent(dm), isNull);
      final next = await restart(disk);
      await reconcileSendIntents(meta, next);
      expect(meta.draft(dm), 'QRZ');
    },
  );

  test('a kill between a newer draft and the intent removal keeps the newer '
      'draft', () async {
    await chat.setDraft(dm, 'QRZ');
    final sent = await chat.sendText(dm, 'QRZ');
    final disk = _snapshot(store);
    // The newer draft's own write landed, its intent removal did not.
    await disk.setString('ditmesh_draft_${dm}_$prefix', 'QRZ?');
    final meta = ConversationMetaStore(disk, accountPrefix: prefix);
    expect(meta.sendIntent(dm)?.id, sent.id);
    final next = await restart(disk, dropHistory: true);
    await reconcileSendIntents(meta, next);
    expect(meta.draft(dm), 'QRZ?');
    expect(meta.sendIntent(dm), isNull);
  });

  test(
    'the intent waits for an older draft write and records its result',
    () async {
      store
        ..holdOnlyKeyContaining = 'ditmesh_draft'
        ..holdSetString = Completer<void>();
      final older = chat.setDraft(dm, 'CQ CQ');
      await store.heldString.future;
      final send = chat.sendText(dm, 'CQ CQ');
      await pumpEventQueue();
      store.holdSetString!.complete();
      store.holdSetString = null;
      await older;
      final sent = await send;
      final meta = ConversationMetaStore(store, accountPrefix: prefix);
      expect(
        meta.sendIntent(dm),
        (id: sent.id, draft: 'CQ CQ'),
        reason: 'the older write must neither remove nor follow the intent',
      );
    },
  );

  test(
    'a draft write started during the send lands after its intent',
    () async {
      final send = chat.sendText(dm, 'AGN');
      final edit = chat.setDraft(dm, 'AGN?');
      await Future.wait([send, edit]);
      final meta = ConversationMetaStore(store, accountPrefix: prefix);
      expect(meta.sendIntent(dm), isNull);
      expect(meta.draft(dm), 'AGN?');
    },
  );

  test('a committed send returns its row although the session detached '
      'meanwhile', () async {
    engineService.afterSend = () async {
      engine.bind(null);
      await pumpEventQueue();
    };
    final sent = await chat.sendText(dm, 'QRT');
    expect(sent.text, 'QRT');
    expect(sent.isMine, isTrue);
    expect(sent.conversationId, dm);
    expect(
      engineService.offlineMessageQueuePersistence
          .getMessages(kPeerKey)
          .map((m) => m.msgID),
      [sent.id],
    );
  });

  test('a failing unhide does not fail a committed send', () async {
    final meta = ConversationMetaStore(store, accountPrefix: prefix);
    await meta.hide(dm);
    store
      ..holdOnlyKeyContaining = 'ditmesh_hidden'
      ..holdSetStringList = Completer<void>();
    // The unhide write after the commit fails (the hide before did not).
    store.holdSetStringList!.future.ignore();
    engineService.afterSend = () async {
      store.holdSetStringList!.completeError(StateError('disk full'));
    };
    final sent = await chat.sendText(dm, 'QSL');
    expect(sent.text, 'QSL');
  });

  test('plain text sends carry their own durable id', () async {
    final sent = await chat.sendText(dm, 'CQ');
    expect(sent.id, startsWith('dmt:'));
  });
}
