@Tags(['needs-native'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_library_manager.dart';

import 'helpers/real_peer_store.dart';

/// Run with helpers/run_real_peers.py. Tim2Tox owns a singleton per process,
/// so the runner starts two workers. Files coordinate bootstrap endpoints and
/// barriers only: every asserted message travels through the native network.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final role = Platform.environment['DITMESH_REAL_PEER_ROLE'];
  final root = Platform.environment['DITMESH_REAL_PEER_ROOT'];
  final library = Platform.environment['TIM2TOX_FFI_LIB'];
  final enabled =
      (role == 'alice' || role == 'bob') &&
      root != null &&
      library != null &&
      File(library).existsSync();
  test(
    'real peers deliver DM, NGC and durable queued messages across restart',
    () async {
      setNativeLibraryPath(library!);
      final peer = _Peer(role!, Directory(root!), library);
      try {
        await peer.run();
        await peer.mark('complete');
      } catch (error, stack) {
        await peer.mark('failure', {'error': '$error', 'stack': '$stack'});
        rethrow;
      } finally {
        await peer.close();
      }
    },
    skip: enabled ? null : 'Opt in through test/helpers/run_real_peers.py',
    timeout: const Timeout(Duration(minutes: 12)),
  );
}

class _Peer {
  _Peer(this.role, this.root, this.library);

  final String role;
  final Directory root;
  final String library;
  final secure = MemorySecureStore();
  late RealPeerStore store;
  late Tim2ToxEngine engine;
  DitmeshChatBackend? active;
  late Identity identity;
  late String remoteKey;
  late String groupChatId;
  String? queuedId;
  String? lastMembers;

  String get other => role == 'alice' ? 'bob' : 'alice';
  IdentityPaths get paths => IdentityPaths('${root.path}/$role/identity');
  ChatService get chat => active!.chat;
  String get dm => 'c2c_$remoteKey';
  File file(String owner, String name) => File('${root.path}/$owner.$name');

  Future<void> mark(String name, [Map<String, Object?> data = const {}]) async {
    final destination = file(role, name);
    final staging = File('${destination.path}.tmp');
    await staging.writeAsString(jsonEncode(data), flush: true);
    await staging.rename(destination.path);
  }

  Future<Map<String, dynamic>> read(String owner, String name) async {
    await wait('$owner.$name', () => file(owner, name).exists());
    return jsonDecode(await file(owner, name).readAsString())
        as Map<String, dynamic>;
  }

  Future<void> wait(
    String description,
    FutureOr<bool> Function() ready, {
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!await ready()) {
      if (await file(other, 'failure').exists()) {
        throw StateError(
          'Other peer failed: ${await file(other, 'failure').readAsString()}',
        );
      }
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException(
          '$role: $description; connection=${active?.identity.connectionStatus}; '
          'friends=${active?.chat.friends.map((f) => '${f.publicKey}:${f.online}').toList()}; '
          'groups=${active?.chat.groups.map((g) => '${g.id}:${g.chatId}:${g.memberCount}').toList()}',
          timeout,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> barrier(String phase) async {
    await mark(phase);
    await read(other, phase);
    await note('passed $phase');
  }

  Future<void> note(String message) =>
      File('${root.path}/$role.phases.log').writeAsString(
        '${DateTime.now().toIso8601String()} $message\n',
        mode: FileMode.append,
        flush: true,
      );

  Future<void> open({required bool fresh}) async {
    store = RealPeerStore(File('${root.path}/$role/preferences.json'));
    // No public seeds: this harness must connect using only the explicitly
    // exchanged localhost endpoints, even when production auto mode changes.
    if (fresh) await store.setString('bootstrap_node_mode', 'manual');
    final logger = CallbackChatLogger((record) {
      File(
        '${root.path}/$role.backend.log',
      ).writeAsStringSync('$record\n', mode: FileMode.append);
    });
    engine = Tim2ToxEngine(
      store: store,
      logger: logger,
      libraryPathOverride: library,
    );
    active = await DitmeshChatBackend.create(
      paths: paths,
      store: store,
      secureStore: secure,
      engine: engine,
      logger: logger,
      nativeLibraryPathOverride: library,
      pollInterval: const Duration(milliseconds: 100),
    );
    if (fresh) {
      expect(await active!.identity.inspect(), IdentityState.none);
      identity = await active!.identity.create(
        displayName: role.toUpperCase(),
        password: 'local peer regression',
      );
    } else {
      expect(await active!.identity.inspect(), IdentityState.locked);
      final reopened = await active!.identity.unlock('local peer regression');
      expect(reopened.toxId, identity.toxId);
    }
    await active!.identity.connect();
    await wait('chat session', () => chat.hasSession);
  }

  Future<void> bootstrap(int generation) async {
    final svc = engine.service!;
    final port = svc.getUdpPort();
    final dht = svc.getDhtId();
    expect(port, greaterThan(0));
    expect(dht, matches(RegExp(r'^[0-9A-Fa-f]{64}$')));
    await mark('endpoint.$generation', {
      'toxId': identity.toxId,
      'udpPort': port,
      'dhtId': dht,
    });
    final remote = await read(other, 'endpoint.$generation');
    remoteKey = (remote['toxId'] as String).substring(0, 64);
    expect(remoteKey, isNot(identity.publicKey));
    expect(remote['udpPort'], isNot(port));
    expect(
      await svc.tryBootstrapNode(
        '127.0.0.1',
        remote['udpPort'] as int,
        remote['dhtId'] as String,
      ),
      isTrue,
    );
    await wait(
      'native network online',
      () => active!.identity.connectionStatus == ConnectionStatus.online,
    );
    await note(
      'native online, UDP local=$port remote=${remote['udpPort']} generation=$generation',
    );
  }

  Future<void> friendOnline() => wait(
    'friend online',
    () => chat.friends.any(
      (friend) => friend.publicKey == remoteKey && friend.online,
    ),
  );

  Future<void> incoming(String conversation, String text) => wait(
    'receive "$text" in $conversation',
    () async => (await chat.loadHistory(
      conversation,
    )).any((message) => !message.isMine && message.text == text),
  );

  Group? get group {
    for (final candidate in chat.groups) {
      if (candidate.chatId?.toUpperCase() == groupChatId.toUpperCase()) {
        return candidate;
      }
    }
    return null;
  }

  Future<void> groupOnline() => wait(
    'NGC has online self and remote members',
    () async {
      if (group == null) return false;
      final members = await chat.groupMembers(group!.id);
      final snapshot = members
          .map(
            (member) => '${member.isSelf ? 'self' : 'remote'}:${member.online}',
          )
          .join(',');
      if (snapshot != lastMembers) {
        lastMembers = snapshot;
        await note('native group member status $snapshot');
      }
      return members.any((member) => member.isSelf && member.online) &&
          members.any((member) => !member.isSelf && member.online);
    },
    timeout: Duration(
      seconds:
          int.tryParse(
            Platform.environment['DITMESH_REAL_PEER_GROUP_TIMEOUT_SECONDS'] ??
                '',
          ) ??
          90,
    ),
  );

  Future<void> exchange(String conversation, String own, String remote) async {
    final row = await chat.sendText(conversation, own);
    await incoming(conversation, remote);
    await wait(
      'sent status for "$own"',
      () async => (await chat.loadHistory(conversation)).any(
        (message) =>
            message.id == row.id && message.status == MessageStatus.sent,
      ),
    );
  }

  Future<void> run() async {
    await open(fresh: true);
    await bootstrap(1);
    if (role == 'alice') {
      final remote = await read(other, 'endpoint.1');
      await chat.addFriend(remote['toxId'] as String);
    } else {
      await wait(
        'friend request',
        () => chat.friendRequests.any(
          (request) => request.publicKey == remoteKey,
        ),
      );
      await chat.acceptFriendRequest(remoteKey);
    }
    await friendOnline();
    await barrier('friends');
    await exchange(
      dm,
      'CQ DE ${role.toUpperCase()}',
      'CQ DE ${other.toUpperCase()}',
    );
    await barrier('direct-delivery');

    if (role == 'alice') {
      final created = await chat.createGroup('Local Morse Net');
      groupChatId = created.chatId!;
      await mark('group', {'chatId': groupChatId});
      await chat.inviteToGroup(created.id, remoteKey);
    } else {
      final descriptor = await read('alice', 'group');
      groupChatId = descriptor['chatId'] as String;
      await wait('group invite', () => chat.groupInvites.isNotEmpty);
      await chat.acceptGroupInvite(chat.groupInvites.first.inviteId);
    }
    await groupOnline();
    await barrier('group-joined');
    await exchange(
      'group_${group!.id}',
      'CQ NET ${role.toUpperCase()}',
      'CQ NET ${other.toUpperCase()}',
    );
    await barrier('group-delivery');
    await restart();
    await bootstrap(2);
    await friendOnline();
    if (role == 'bob') {
      await incoming(dm, 'CQ AFTER RESTART');
      expect(
        (await chat.loadHistory(
          dm,
        )).where((row) => !row.isMine && row.text == 'CQ AFTER RESTART'),
        hasLength(1),
      );
    } else {
      await wait(
        'durable queue drain',
        () async => (await chat.loadHistory(
          dm,
        )).any((row) => row.id == queuedId && row.status == MessageStatus.sent),
      );
      await (active!.identity as PersistentIdentityService).persist();
      expect(
        await File(paths.offlineQueueFile).readAsString(),
        isNot(contains('CQ AFTER RESTART')),
      );
      final conversation = chat.conversations.firstWhere(
        (value) => value.id == dm,
      );
      expect(conversation.pinned, isTrue);
      expect(conversation.draft, 'DE ALICE');
    }
    await barrier('durable-queue-delivery');
    await groupOnline();
    await barrier('group-rejoined');
    await exchange(
      'group_${group!.id}',
      'R NET ${role.toUpperCase()}',
      'R NET ${other.toUpperCase()}',
    );
    await barrier('group-restart-delivery');
  }

  Future<void> restart() async {
    if (role == 'bob') {
      await close();
      await mark('offline');
      await read('alice', 'reopened');
      await open(fresh: false);
    } else {
      await read('bob', 'offline');
      await wait(
        'friend offline',
        () => chat.friends.any(
          (friend) => friend.publicKey == remoteKey && !friend.online,
        ),
      );
      await wait('NGC remote offline or removed', () async {
        final members = await chat.groupMembers(group!.id);
        return !members.any((member) => !member.isSelf && member.online);
      });
      await note('native group remote offline or removed');
      final queued = await chat.sendText(dm, 'CQ AFTER RESTART');
      expect(queued.status, MessageStatus.pending);
      queuedId = queued.id;
      await chat.setPinned(dm, true);
      await chat.setDraft(dm, 'DE ALICE');
      await close();
      expect(
        Tim2ToxProfileCrypto().isEncrypted(
          await File(paths.profileFile).readAsBytes(),
        ),
        isTrue,
      );
      expect(
        await File(paths.offlineQueueFile).readAsString(),
        contains('CQ AFTER RESTART'),
      );
      await open(fresh: false);
      final row = (await chat.loadHistory(
        dm,
      )).singleWhere((row) => row.id == queuedId);
      expect(row.status, MessageStatus.pending);
      expect(row.text, 'CQ AFTER RESTART');
      await mark('reopened');
    }
    await note('encrypted identity and disk preferences reopened');
  }

  Future<void> close() async {
    final backend = active;
    if (backend == null) return;
    active = null;
    await (backend.identity as PersistentIdentityService).persist();
    await backend.dispose().timeout(const Duration(seconds: 20));
    await store.flush();
  }
}
