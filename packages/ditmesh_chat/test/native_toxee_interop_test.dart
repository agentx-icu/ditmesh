@Tags(['needs-native', 'network'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tencent_cloud_chat_sdk/native_im/bindings/native_library_manager.dart';
import 'package:tim2tox_dart/ffi/tim2tox_ffi.dart';

// This native integration fixture exercises the app's actual protocol.
// ignore: avoid_relative_lib_imports
import '../../../apps/ditmesh/lib/nearby/geohash.dart';
// This native integration fixture exercises the app's actual protocol.
// ignore: avoid_relative_lib_imports
import '../../../apps/ditmesh/lib/nearby/location_source.dart';
// This native integration fixture exercises the app's actual protocol.
// ignore: avoid_relative_lib_imports
import '../../../apps/ditmesh/lib/nearby/nearby_service.dart';
import 'helpers/real_peer_store.dart';

/// Alice is the real DitMesh backend and discovery implementation; Bob is
/// Toxee's SDK/UIkit worker. Only phase markers and bootstrap endpoints use
/// files. Presence, encrypted intents, friend requests and messages use UDP.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = Platform.environment['DITMESH_TOXEE_EXCHANGE'];
  final library = Platform.environment['TIM2TOX_FFI_LIB'];
  final enabled = root != null && library != null && File(library).existsSync();
  test(
    'DitMesh interoperates with Toxee nearby and location messages',
    () async {
      setNativeLibraryPath(library!);
      final peer = _DitmeshPeer(Directory(root!), library);
      try {
        await peer.run();
      } catch (error, stack) {
        await peer.mark('failed', {'error': '$error', 'stack': '$stack'});
        rethrow;
      } finally {
        await peer.close();
      }
    },
    skip: enabled ? null : 'Use tool/test_nearby_toxee.py',
    timeout: const Timeout(Duration(minutes: 6)),
  );
}

class _Position implements LocationSource {
  const _Position(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
  @override
  Future<LocationPermissionState> permissionState() async =>
      LocationPermissionState.granted;
  @override
  Future<LocationPermissionState> requestPermission() async =>
      LocationPermissionState.granted;
  @override
  Future<bool> openSettings() async => true;
  @override
  Future<LocationFix?> currentFix({
    Duration timeout = const Duration(seconds: 15),
  }) async => LocationFix(
    latitude: latitude,
    longitude: longitude,
    accuracyM: 5,
    at: DateTime.now(),
  );
}

class _DitmeshPeer {
  _DitmeshPeer(this.root, this.library);
  final Directory root;
  final String library;
  final String? realLocationFile =
      Platform.environment['DITMESH_REAL_LOCATION_FILE'];
  DitmeshChatBackend? backend;
  Tim2ToxEngine? engine;
  NearbyService? nearby;
  StreamSubscription<RendezvousEvent>? packets;
  int nativePackets = 0;
  final received = <ChatMessage>[];
  StreamSubscription<ChatMessage>? messages;
  ChatService get chat => backend!.chat;
  String get address => backend!.identity.current!.toxId;
  String remoteAddress = '';
  String get remoteKey => remoteAddress.substring(0, 64).toUpperCase();
  String get dm => 'c2c_$remoteKey';

  Future<void> mark(String step, [Map<String, Object?> data = const {}]) async {
    if (realLocationFile != null) {
      const hidden = {
        'latitude',
        'longitude',
        'desc',
        'text',
        'error',
        'stack',
      };
      data = {
        for (final entry in data.entries)
          if (!hidden.contains(entry.key)) entry.key: entry.value,
        if (data.containsKey('latitude')) 'coordinatesMatched': true,
      };
    }
    final destination = File('${root.path}/alice.$step.json');
    final staging = File('${destination.path}.pending');
    await staging.writeAsString(jsonEncode(data), flush: true);
    await staging.rename(destination.path);
  }

  Future<Map<String, dynamic>> read(String step) async {
    final file = File('${root.path}/bob.$step.json');
    await wait('Bob/$step', file.existsSync);
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  }

  Future<void> wait(
    String description,
    FutureOr<bool> Function() ready, {
    Duration timeout = const Duration(seconds: 100),
  }) async {
    final watch = Stopwatch()..start();
    while (!await ready()) {
      final failure = File('${root.path}/bob.failed.json');
      if (failure.existsSync()) throw StateError(await failure.readAsString());
      if (watch.elapsed > timeout) {
        throw TimeoutException(
          '$description; status=${nearby?.status}, '
          'cells=${nearby?.joinedCells}, peers=${nearby?.peers.length}, '
          'friends=${chat.friends.map((f) => '${f.publicKey}:${f.online}').toList()}',
          timeout,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> run() async {
    final profileRoot = Directory('${root.path}/ditmesh-profile');
    final store = RealPeerStore(File('${profileRoot.path}/preferences.json'));
    await store.setString('bootstrap_node_mode', 'manual');
    final logger = CallbackChatLogger((record) {
      if (realLocationFile != null) return;
      File(
        '${root.path}/alice.backend.log',
      ).writeAsStringSync('$record\n', mode: FileMode.append);
    });
    final node = Tim2ToxEngine(
      store: store,
      logger: logger,
      libraryPathOverride: library,
    );
    engine = node;
    backend = await DitmeshChatBackend.create(
      paths: IdentityPaths(profileRoot.path),
      store: store,
      secureStore: MemorySecureStore(),
      engine: node,
      logger: logger,
      nativeLibraryPathOverride: library,
      pollInterval: const Duration(milliseconds: 100),
    );
    await backend!.identity.create(
      displayName: 'verify-alice',
      password: 'disposable native peer',
    );
    await backend!.identity.connect();
    await wait('DitMesh session', () => chat.hasSession);
    messages = chat.messageEvents.listen(received.add);
    final svc = node.service!;
    await mark('endpoint', {
      'port': svc.getUdpPort(),
      'dht': svc.getDhtId(),
      'address': address,
      'pid': pid,
    });
    final remote = await read('endpoint');
    remoteAddress = remote['address'] as String;
    expect(
      await svc.tryBootstrapNode(
        '127.0.0.1',
        remote['port'] as int,
        remote['dht'] as String,
      ),
      isTrue,
    );
    await wait(
      'native DHT online',
      () => backend!.identity.connectionStatus == ConnectionStatus.online,
    );
    await mark('connected');

    final transport = (chat as NearbyTransportProvider).nearbyTransport!;
    packets = transport.events.listen((event) {
      if (event is RendezvousPacket) {
        nativePackets++;
        // Metadata only: keep the native regression diagnosable without
        // logging a presence payload or location coordinates.
        stdout.writeln(
          '[VERIFY] alice: packet cell=${event.chatIdHex} '
          'peer=${event.peerPkHex} private=${event.isPrivate} '
          'bytes=${event.payload.length}',
        );
      }
    });
    final cell = Geohash.encode(0, -140, 5);
    final bounds = Geohash.bounds(cell);
    final center = Geohash.decode(cell);
    final position = _Position(
      bounds.latMax - 0.0005 + 0.00005,
      center.longitude,
    );
    var visible = true;
    final discovery = NearbyService(
      transport: transport,
      location: position,
      selfAddress: () async => address,
      displayName: () => 'verify-alice',
      canRun: () async => visible,
    );
    nearby = discovery;
    discovery.addListener(() {
      stdout.writeln(
        '[VERIFY] alice: nearby cells=${discovery.joinedCells} '
        'routes=${discovery.peers.map((p) => p.cells.length).toList()} '
        'dropped=${discovery.droppedRecords}',
      );
    });
    await discovery.start();
    await mark('session', {'sk': discovery.sessionKeys!.skHex});
    await wait(
      'DitMesh founds both real native geocells',
      () => discovery.joinedCells.length >= 2,
    );
    await mark('founded');
    final remoteSession = await read('session');
    NearbyPeer? peer() => discovery.peers
        .where((p) => p.skHex == remoteSession['sk'])
        .firstOrNull;
    await wait(
      'both remote cell routes',
      () => (peer()?.cells.length ?? 0) >= 2,
      // The second native cell can connect inside the peer-join throttle.
      // The remote's 60 s fix timer may then need two ticks to reach its
      // next presence broadcast. Keep the production cadence in this test.
      timeout: const Duration(seconds: 180),
    );
    final discovered = peer()!;
    expect(discovered.cells.map(discovered.peerKeyForCell).toSet().length, 2);
    expect(discovery.distanceTo(discovered), lessThan(200));
    expect(
      chat.groups,
      isEmpty,
      reason: 'Discovery cells never become ordinary groups',
    );
    expect(chat.conversations.every((c) => c.isSelf), isTrue);
    await mark('discovered', {
      'routes': discovered.cells.length,
      'packets': nativePackets,
    });
    await read('discovered');
    expect(transport.leave(peer()!.cellChatIdHex!), isTrue);
    await wait('local cell route fallback', () => peer()?.cells.length == 1);
    await mark('fallback');
    await read('fallback-observed');
    final result = await discovery.sendIntent(peer()!, 'Native nearby hello');
    expect(result, isA<PendingIntent>());
    final pending = result as PendingIntent;
    await mark('intent-sent', {'nonce': pending.nonceHex});
    await wait(
      'Toxee friend application',
      () => chat.friendRequests.any((r) => r.publicKey == remoteKey),
    );
    final application = chat.friendRequests.firstWhere(
      (r) => r.publicKey == remoteKey,
    );
    expect(
      discovery.matchFriendApplication(application.message)?.nonceHex,
      pending.nonceHex,
    );
    await chat.acceptFriendRequest(application.publicKey);
    await mark('friend-confirmed');
    await wait(
      'friend online',
      () => chat.friends.any((f) => f.publicKey == remoteKey && f.online),
    );
    await mark('friend-connected');
    await read('friend-connected');

    final messagePosition = realLocationFile == null
        ? position
        : _readRealPosition();
    final payload = ChatLocation(
      latitude: messagePosition.latitude,
      longitude: messagePosition.longitude,
      description: _description(messagePosition),
    ).encode();
    await chat.sendText(dm, payload);
    await mark('location-sent');
    await wait(
      'Toxee C2C location',
      () => received.any(
        (m) =>
            !m.isMine &&
            m.conversationId == dm &&
            m.text.startsWith('__location__:'),
      ),
    );
    final location = received.firstWhere(
      (m) =>
          !m.isMine &&
          m.conversationId == dm &&
          m.text.startsWith('__location__:'),
    );
    final expectedLatitude = realLocationFile == null
        ? bounds.latMax - 0.0005 - 0.00005
        : messagePosition.latitude;
    final body = _verifyLocation(
      location,
      expectedLatitude,
      messagePosition.longitude,
    );
    await mark('location-received', {...body, 'nativePackets': nativePackets});
    await read('location-received');

    if (realLocationFile != null) {
      // Real coordinates go only to the explicitly paired encrypted C2C
      // peer. Discovery uses synthetic positions; no real-location group.
      await discovery.stop();
      await mark('passed', {'pid': pid, 'nativePackets': nativePackets});
      return;
    }

    final group = await chat.createGroup('Native location verification');
    await wait(
      'group identity',
      () => chat.groups.any((g) => g.id == group.id && g.chatId != null),
    );
    final chatId = chat.groups
        .firstWhere((g) => g.id == group.id)
        .chatId!
        .toLowerCase();
    await mark('group-created', {'groupId': group.id, 'chatId': chatId});
    await chat.inviteToGroup(group.id, remoteKey);
    await read('group-joined');
    await wait('group confirmed remote member', () async {
      final members = await chat.groupMembers(group.id);
      return members.any((m) => m.isSelf && m.online) &&
          members.any((m) => !m.isSelf && m.online);
    });
    await mark('group-ready', {'groupId': group.id, 'chatId': chatId});
    await read('group-ready');
    final groupConversation = 'group_${group.id}';
    await chat.sendText(groupConversation, payload);
    final authorKey = Tim2ToxFfi.open()
        .lastGroupSendSelfKey()
        .toDartString()
        .toLowerCase();
    expect(authorKey, matches(RegExp(r'^[0-9a-f]{64}$')));
    await mark('group-location-sent', {'authorKey': authorKey});
    final remoteGroupSend = await read('group-location-sent');
    await wait(
      'Toxee group location',
      () => received.any(
        (m) =>
            !m.isMine &&
            m.conversationId == groupConversation &&
            m.text.startsWith('__location__:'),
      ),
    );
    final groupMessage = received.firstWhere(
      (m) =>
          !m.isMine &&
          m.conversationId == groupConversation &&
          m.text.startsWith('__location__:'),
    );
    final groupBody = _verifyLocation(
      groupMessage,
      expectedLatitude,
      position.longitude,
    );
    expect(groupMessage.senderId.toLowerCase(), remoteGroupSend['authorKey']);
    await mark('group-location-received', {
      ...groupBody,
      'chatId': chatId,
      'sender': groupMessage.senderId,
      'groupId': group.id,
    });
    await read('group-location-received');
    visible = false;
    await discovery.refresh();
    expect(discovery.running, isFalse);
    expect(discovery.joinedCells, isEmpty);
    await mark('nearby-stopped');
    await read('stop-observed');
    expect(nativePackets, greaterThan(0));
    await mark('passed', {'pid': pid, 'nativePackets': nativePackets});
  }

  static String _description(_Position position) =>
      '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';

  _Position _readRealPosition() {
    final data = jsonDecode(File(realLocationFile!).readAsStringSync()) as Map;
    final age = DateTime.now().toUtc().difference(
      DateTime.parse(data['capturedAtUtc'] as String),
    );
    expect(
      age.inMinutes >= -1 && age.inMinutes < 10,
      isTrue,
      reason: 'The real OS snapshot must remain fresh during discovery.',
    );
    return _Position(
      (data['latitude'] as num).toDouble(),
      (data['longitude'] as num).toDouble(),
    );
  }

  Map<String, Object?> _verifyLocation(
    ChatMessage message,
    double latitude,
    double longitude,
  ) {
    final location = message.location;
    expect(message.isLocation, isTrue);
    expect(location, isNotNull);
    expect(location!.latitude, closeTo(latitude, 0.000001));
    expect(location.longitude, closeTo(longitude, 0.000001));
    expect(
      location.description,
      '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
    );
    final body = {
      'latitude': location.latitude,
      'longitude': location.longitude,
      'desc': location.description,
    };
    return {
      'latitude': body['latitude'],
      'longitude': body['longitude'],
      'desc': body['desc'],
    };
  }

  Future<void> close() async {
    await nearby?.stop();
    nearby?.dispose();
    await packets?.cancel();
    await messages?.cancel();
    await backend?.dispose();
  }
}
