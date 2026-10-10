@Tags(['needs-native'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/engine/ditmesh_ffi_chat_service.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_library_manager.dart';

import 'helpers/real_peer_store.dart';
import 'helpers/real_peer_rhythm.dart';

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
  KeyedRecording rhythm(String sender, String text) =>
      realPeerRhythm(sender, text);

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
    // N11: the production session leaves the 50 ms shared-instance poll.
    expect(svc, isA<DitmeshFfiChatService>());
    expect(svc.pollDefaultInstanceAsShared, isFalse);
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

  /// [friendOnline] for the peer that stayed up while the other left: its
  /// only DHT link went with it, and one bootstrap call to the returning
  /// peer is not always enough on a two-node network. Repeated every 5 s.
  Future<void> friendOnlineRebootstrapping(int generation) async {
    final remote = await read(other, 'endpoint.$generation');
    var attempts = 1;
    var next = DateTime.now().add(const Duration(seconds: 5));
    await wait('friend online (re-bootstrapping)', () async {
      if (chat.friends.any((f) => f.publicKey == remoteKey && f.online)) {
        return true;
      }
      if (DateTime.now().isAfter(next)) {
        attempts++;
        next = DateTime.now().add(const Duration(seconds: 5));
        await engine.service!.tryBootstrapNode(
          '127.0.0.1',
          remote['udpPort'] as int,
          remote['dhtId'] as String,
        );
      }
      return false;
    });
    await note('friend online after $attempts bootstrap call(s)');
  }

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
    final row = await chat.sendText(
      conversation,
      own,
      recording: rhythm(role, own),
    );
    await incoming(conversation, remote);
    await wait(
      'received exact original rhythm for "$remote"',
      () async => (await chat.loadHistory(conversation)).any(
        (message) =>
            !message.isMine &&
            message.text == remote &&
            message.recording == rhythm(other, remote),
      ),
    );
    await wait(
      'confirmed received status for "$own"',
      () async => (await chat.loadHistory(conversation)).any(
        (message) =>
            message.id == row.id && message.status == MessageStatus.delivered,
      ),
    );
  }

  /// Delivery across a rejoin. gc_rejoin_group drops every peer connection
  /// of the group and builds them again; meanwhile a send either fails
  /// natively (TOX_ERR_GROUP_SEND_MESSAGE_FAIL_SEND -> `send_failed`) or is
  /// accepted and never arrives (handed to a connection being torn down).
  /// So each side keeps sending fresh numbered payloads until it has seen
  /// one of the other's AND the other has seen one of its own; the files
  /// carry only that "seen" marker.
  Future<void> exchangeAcrossRejoin(String conversation, String tag) async {
    final own = '$tag ${role.toUpperCase()}';
    final remote = '$tag ${other.toUpperCase()}';
    final deadline = DateTime.now().add(const Duration(seconds: 120));
    var sent = 0;
    var refused = 0;
    var seen = false;
    while (!seen || !await file(other, 'seen.$tag').exists()) {
      if (await file(other, 'failure').exists()) {
        throw StateError(
          'Other peer failed: ${await file(other, 'failure').readAsString()}',
        );
      }
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException(
          '$role: $tag across a rejoin; sent=$sent refused=$refused seen=$seen',
        );
      }
      if (!await file(other, 'seen.$tag').exists()) {
        try {
          await chat.sendText(conversation, '$own #${sent + 1}');
          sent++;
        } on ChatException catch (e) {
          if (e.code != 'send_failed') rethrow;
          refused++;
        }
      }
      if (!seen &&
          (await chat.loadHistory(conversation)).any(
            (m) => !m.isMine && m.text.startsWith('$remote #'),
          )) {
        seen = true;
        await mark('seen.$tag');
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    await note(
      '$tag across the rejoin: $sent sent, $refused refused (send_failed)',
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
    await repeatedDirectRhythms();

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
      final received = (await chat.loadHistory(
        dm,
      )).where((row) => !row.isMine && row.text == 'CQ AFTER RESTART').toList();
      expect(received, hasLength(1));
      expect(received.single.recording, rhythm(other, 'CQ AFTER RESTART'));
    } else {
      await wait(
        'durable queue drain',
        () async => (await chat.loadHistory(dm)).any(
          (row) => row.id == queuedId && row.status == MessageStatus.delivered,
        ),
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
    await rejoin();
  }

  /// `rejoinGroup` on real toxcore: a group we hold is joined again by our
  /// own group id (the retry the app offers after a refused reconnect).
  /// Tim2Tox has no API to give an NGC group a password or a peer limit,
  /// so a real refusal cannot be produced here; what is proven is that
  /// rejoining a held group succeeds (never `already_joined`), keeps one
  /// binding, and the group carries fresh traffic afterwards, with the
  /// founder online and while it is away.
  ///
  /// Measured here too (2026-10-08): the same rejoin WITH a password, of
  /// this passwordless group, never reconnects (online or away; 120 s of
  /// resends). gc_rejoin_group keeps the password as the group's local one,
  /// and a peer that believes the group has a password sends and expects
  /// password fields its peers do not. The app therefore asks for a
  /// password only after a password refusal (`groupJoinRetryAsksPassword`).
  Future<void> rejoin() async {
    // A second group: its native slot is 1, so tox_group_join's status 0
    // (what it returns for a held chat id) cannot pass for its number.
    if (role == 'alice') {
      final created = await chat.createGroup('Rejoin Net');
      groupChatId = created.chatId!;
      await mark('group2', {'chatId': groupChatId});
      await chat.inviteToGroup(created.id, remoteKey);
    } else {
      groupChatId = (await read('alice', 'group2'))['chatId'] as String;
      await wait('second group invite', () => chat.groupInvites.isNotEmpty);
      await chat.acceptGroupInvite(chat.groupInvites.first.inviteId);
    }
    await groupOnline();
    await barrier('group2-joined');
    await exchange(
      'group_${group!.id}',
      'RJ0 ${role.toUpperCase()}',
      'RJ0 ${other.toUpperCase()}',
    );
    await barrier('group2-delivery');

    Future<void> rejoinHeld({String? password}) async {
      final id = group!.id;
      await chat.rejoinGroup(id, password: password);
      expect(group!.id, id);
      expect(
        chat.groups.where(
          (g) => g.chatId?.toUpperCase() == groupChatId.toUpperCase(),
        ),
        hasLength(1),
        reason: 'one binding for the group',
      );
      await note('rejoined held group $id (password: ${password != null})');
    }

    if (role == 'bob') await rejoinHeld();
    await barrier('rejoin-online');
    await exchangeAcrossRejoin('group_${group!.id}', 'RJ1');
    await barrier('rejoin-online-delivery');

    // The founder leaves the network; bob rejoins while it is away; the
    // founder comes back.
    if (role == 'alice') {
      await close();
      await mark('away');
      await read('bob', 'rejoined-away');
      await open(fresh: false);
    } else {
      await read('alice', 'away');
      await wait(
        'founder offline',
        () => chat.friends.any(
          (friend) => friend.publicKey == remoteKey && !friend.online,
        ),
      );
      await rejoinHeld();
      await mark('rejoined-away');
    }
    await bootstrap(3);
    await friendOnlineRebootstrapping(3);
    await barrier('rejoin-away-returned');
    await exchangeAcrossRejoin('group_${group!.id}', 'RJ2');
    await barrier('rejoin-away-delivery');
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
      final queued = await chat.sendText(
        dm,
        'CQ AFTER RESTART',
        recording: rhythm(role, 'CQ AFTER RESTART'),
      );
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
      expect(row.recording, rhythm(role, 'CQ AFTER RESTART'));
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

  Future<void> repeatedDirectRhythms() async {
    final first = realPeerRhythm('alice', 'CQ SAME');
    final second = realPeerRhythm('alice', 'CQ SAME', second: true);
    if (role == 'alice') {
      final a = await chat.sendText(dm, 'CQ SAME', recording: first);
      final b = await chat.sendText(dm, 'CQ SAME', recording: second);
      expect(a.id, isNot(b.id));
      await wait(
        'both repeated texts have distinct confirmed delivery',
        () async {
          final rows = await chat.loadHistory(dm);
          return [a.id, b.id].every(
            (id) => rows.any(
              (row) => row.id == id && row.status == MessageStatus.delivered,
            ),
          );
        },
      );
    } else {
      await wait(
        'repeated text recordings remain attached to distinct identities',
        () async {
          final rows = (await chat.loadHistory(
            dm,
          )).where((row) => !row.isMine && row.text == 'CQ SAME').toList();
          return rows.length == 2 &&
              rows[0].recording == first &&
              rows[1].recording == second &&
              chat.conversations.singleWhere((c) => c.id == dm).unreadCount ==
                  3;
        },
      );
      expect(chat.conversations.singleWhere((c) => c.id == dm).unreadCount, 3);
    }
    await barrier('repeated-direct-rhythms');
  }
}
