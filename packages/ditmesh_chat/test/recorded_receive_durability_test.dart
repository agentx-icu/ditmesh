import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ditmesh_chat/src/engine/ditmesh_ffi_chat_service.dart';
import 'package:ditmesh_chat/src/engine/rhythm_protocol.dart';
import 'package:ditmesh_chat/src/engine/rhythm_transport.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart' show KeyedRecording;
import 'package:flutter_test/flutter_test.dart';
import 'package:tim2tox_dart/models/chat_message.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';
import 'package:tim2tox_dart/utils/message_history_persistence.dart';

import 'helpers/fakes.dart';
import 'rhythm_service_test.dart' show PacketFfi;

Future<void> _until(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue, reason: 'asynchronous receive must settle');
  await pumpEventQueue();
}

List<String> _incoming(FfiChatService service, PacketFfi native) {
  service.consumeCustomExtension(
    kPeerKey,
    RhythmProtocol.control('hello', {'nonce': 'a' * 32, 'session': 'b' * 32}),
  );
  final localSession = (jsonDecode(native.packets.last) as Map)['session'];
  native.packets.clear();
  return RhythmProtocol.packets('d' * 32, {
    'version': 1,
    'id': 'c' * 32,
    'transferId': 'd' * 32,
    'session': localSession,
    'authorSession': 'b' * 32,
    'text': 'E',
    'contentKind': 'normal',
    'recording': KeyedRecording(durationsMs: [83]).toJson(),
  });
}

void _deliver(FfiChatService service, List<String> packets) {
  for (final packet in packets) {
    expect(service.consumeCustomExtension(kPeerKey, packet), isTrue);
  }
}

class _HeldSaveStore extends MessageHistoryPersistence {
  _HeldSaveStore(Directory root) : super(historyDirectory: root.path);

  final entered = Completer<void>();
  final release = Completer<void>();
  bool _held = false;

  @override
  Future<void> saveHistory(String conversationId, List<ChatMessage> messages) {
    // Keep the production write token/lock, but hold its caller's completion.
    // This models teardown/clear racing a pending receive persistence await.
    final save = super.saveHistory(conversationId, messages);
    if (_held) return save;
    _held = true;
    entered.complete();
    return save.then((_) => release.future);
  }
}

class _ScopedReceiver extends FfiChatService {
  _ScopedReceiver(_HeldSaveStore store, PacketFfi native)
    : super(messageHistoryPersistence: store, ffiForTesting: native);

  late final _rhythm = RhythmTransport(this);

  @override
  bool consumeCustomExtension(String peer, String payload, {String? groupId}) =>
      _rhythm.consume(peer, payload, groupId: groupId);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'failed recorded receive retries durability before one arrival and ACK',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'ditmesh_failed_receive_',
      );
      // A regular file where the history directory belongs reliably prevents
      // writes even when the test runner can bypass ordinary chmod permissions.
      final blocked = File('${root.path}/history')
        ..writeAsStringSync('blocked');
      final native = PacketFfi();
      final service =
          DitmeshFfiChatService(
              ffiForTesting: native,
              historyDirectory: blocked.path,
            )
            ..debugBeginSessionForTest()
            ..debugSetSelfId(kSelfKey);
      final events = <ChatMessage>[];
      var failures = 0;
      final arrivals = service.messages.listen(events.add);
      final writes = service.messageHistoryPersistence.writeFailures.listen((
        _,
      ) {
        failures++;
      });
      try {
        final packets = _incoming(service, native);
        _deliver(service, packets);
        await _until(() => failures > 0);
        expect(service.getHistory(kPeerKey), hasLength(1));
        expect(native.packets, isEmpty);
        expect(events, isEmpty);
        expect(service.lastMessages[kPeerKey], isNull);

        final beforeRetry = failures;
        _deliver(service, packets);
        await pumpEventQueue();
        expect(
          native.packets,
          isEmpty,
          reason: 'a cache-only duplicate is not durable and cannot ACK',
        );
        await _until(() => failures > beforeRetry);
        expect(events, isEmpty);
        expect(service.lastMessages[kPeerKey], isNull);

        blocked.deleteSync();
        Directory(blocked.path).createSync();
        _deliver(service, packets);
        await _until(() => native.packets.isNotEmpty);
        final ack = jsonDecode(native.packets.single) as Map;
        expect(ack['id'], 'c' * 32);
        expect(ack['session'], 'b' * 32);
        expect(events, hasLength(1));
        expect(events.single.msgID, 'dmr:${'c' * 32}');
        expect(service.lastMessages[kPeerKey]?.msgID, events.single.msgID);
        expect(service.getUnreadOf(kPeerKey), 1);

        _deliver(service, packets);
        await _until(() => native.packets.length == 2);
        expect(events, hasLength(1));
        expect(service.getHistory(kPeerKey), hasLength(1));
        expect(service.getUnreadOf(kPeerKey), 1);

        // Read the persisted file through a fresh service before disposing the
        // receiver: teardown must not be what finally makes the ACK truthful.
        final reopened =
            DitmeshFfiChatService(
                ffiForTesting: PacketFfi(),
                historyDirectory: blocked.path,
              )
              ..debugBeginSessionForTest()
              ..debugSetSelfId(kSelfKey);
        try {
          await reopened.messageHistoryPersistence.loadHistory(kPeerKey);
          expect(reopened.getHistory(kPeerKey), hasLength(1));
          expect(
            reopened.getHistory(kPeerKey).single.msgID,
            events.single.msgID,
          );
          expect(
            reopened.getHistory(kPeerKey).single.cloudCustomData,
            events.single.cloudCustomData,
          );
        } finally {
          await reopened.dispose();
        }
      } finally {
        if (blocked.existsSync()) blocked.deleteSync();
        Directory(blocked.path).createSync(recursive: true);
        await writes.cancel();
        await arrivals.cancel();
        await service.dispose();
        await root.delete(recursive: true);
      }
    },
  );

  for (final reopen in [false, true]) {
    test(
      'held receive cannot publish or ACK after session close (reopen=$reopen)',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'ditmesh_rx_session_',
        );
        final store = _HeldSaveStore(root);
        final native = PacketFfi();
        final service = _ScopedReceiver(store, native)
          ..debugBeginSessionForTest()
          ..debugSetSelfId(kSelfKey);
        final events = <ChatMessage>[];
        final arrivals = service.messages.listen(events.add);
        try {
          _deliver(service, _incoming(service, native));
          await store.entered.future;
          if (reopen) {
            service.debugCloseSessionForTest();
            service.debugBeginSessionForTest();
          } else {
            await service.dispose();
          }
          store.release.complete();
          await pumpEventQueue();
          expect(events, isEmpty);
          expect(service.lastMessages[kPeerKey], isNull);
          expect(native.packets, isEmpty);
        } finally {
          if (!store.release.isCompleted) store.release.complete();
          await arrivals.cancel();
          await service.dispose();
          await root.delete(recursive: true);
        }
      },
    );
  }

  test(
    'conversation clear invalidates an in-flight receive receipt scope',
    () async {
      final root = await Directory.systemTemp.createTemp('ditmesh_rx_clear_');
      final store = _HeldSaveStore(root);
      final native = PacketFfi();
      final service = _ScopedReceiver(store, native)
        ..debugBeginSessionForTest()
        ..debugSetSelfId(kSelfKey);
      final events = <ChatMessage>[];
      final arrivals = service.messages.listen(events.add);
      try {
        final packets = _incoming(service, native);
        _deliver(service, packets);
        await store.entered.future;
        await store.clearHistory(kPeerKey);
        store.release.complete();
        await pumpEventQueue();
        expect(events, isEmpty);
        expect(service.getHistory(kPeerKey), isEmpty);
        expect(service.lastMessages[kPeerKey], isNull);
        expect(native.packets, isEmpty);

        // A new delivery after the deliberate clear owns a fresh token.
        _deliver(service, packets);
        await _until(() => native.packets.isNotEmpty);
        expect(events, hasLength(1));
        expect(service.getHistory(kPeerKey), hasLength(1));
      } finally {
        if (!store.release.isCompleted) store.release.complete();
        await arrivals.cancel();
        await service.dispose();
        await root.delete(recursive: true);
      }
    },
  );

  test(
    'unpublished capacity rejects before append and retains retry publication',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'ditmesh_rx_capacity_',
      );
      final blocked = File('${root.path}/history')
        ..writeAsStringSync('blocked');
      final service =
          DitmeshFfiChatService(
              ffiForTesting: PacketFfi(),
              historyDirectory: blocked.path,
            )
            ..debugBeginSessionForTest()
            ..debugSetSelfId(kSelfKey);
      final events = <ChatMessage>[];
      final arrivals = service.messages.listen(events.add);
      String alias(int index) =>
          'dmr:${index.toRadixString(16).padLeft(32, '0')}';
      try {
        final pending = [
          for (var i = 0; i < 128; i++)
            service
                .receiveExtensionText(kPeerKey, alias(i), 'E')
                .then<Object?>((_) => null, onError: (Object error) => error),
        ];
        await expectLater(
          service.receiveExtensionText(kPeerKey, alias(128), 'E'),
          throwsStateError,
        );
        final outcomes = await Future.wait(pending);
        expect(outcomes, everyElement(isA<FileSystemException>()));
        expect(service.getHistory(kPeerKey), hasLength(128));
        expect(
          service.getHistory(kPeerKey).any((row) => row.msgID == alias(128)),
          isFalse,
        );
        expect(events, isEmpty);

        blocked.deleteSync();
        Directory(blocked.path).createSync();
        expect(
          await service.receiveExtensionText(kPeerKey, alias(0), 'E'),
          isTrue,
        );
        await pumpEventQueue();
        expect(events, hasLength(1));
        expect(events.single.msgID, alias(0));
        expect(
          await service.receiveExtensionText(kPeerKey, alias(128), 'E'),
          isTrue,
        );
        await pumpEventQueue();
        expect(events, hasLength(2));
        expect(service.getHistory(kPeerKey), hasLength(129));
      } finally {
        if (blocked.existsSync()) blocked.deleteSync();
        Directory(blocked.path).createSync(recursive: true);
        await arrivals.cancel();
        await service.dispose();
        await root.delete(recursive: true);
      }
    },
  );

  for (final keepOtherPeer in [false, true]) {
    test(
      'clear frees expired capacity and retains other peer (other=$keepOtherPeer)',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'ditmesh_rx_clear_capacity_',
        );
        final blocked = File('${root.path}/history')
          ..writeAsStringSync('blocked');
        final service =
            DitmeshFfiChatService(
                ffiForTesting: PacketFfi(),
                historyDirectory: blocked.path,
              )
              ..debugBeginSessionForTest()
              ..debugSetSelfId(kSelfKey);
        final events = <ChatMessage>[];
        final arrivals = service.messages.listen(events.add);
        final otherPeer = '3' * 64;
        String alias(int index) =>
            'dmr:${index.toRadixString(16).padLeft(32, '0')}';
        try {
          final outcomes = await Future.wait([
            for (var i = 0; i < 128; i++)
              service
                  .receiveExtensionText(
                    keepOtherPeer && i == 127 ? otherPeer : kPeerKey,
                    alias(i),
                    'E',
                  )
                  .then<Object?>((_) => null, onError: (Object error) => error),
          ]);
          expect(outcomes, everyElement(isA<FileSystemException>()));
          expect(events, isEmpty);

          blocked.deleteSync();
          Directory(blocked.path).createSync();
          await service.messageHistoryPersistence.clearHistory(kPeerKey);
          expect(service.getHistory(kPeerKey), isEmpty);
          expect(
            await service.receiveExtensionText(kPeerKey, alias(128), 'T'),
            isTrue,
          );
          await pumpEventQueue();
          expect(events, hasLength(1));
          expect(events.single.msgID, alias(128));
          expect(service.getHistory(kPeerKey), hasLength(1));

          if (keepOtherPeer) {
            expect(
              await service.receiveExtensionText(otherPeer, alias(127), 'E'),
              isTrue,
              reason:
                  'a valid failed arrival must retain its publication marker',
            );
            await pumpEventQueue();
            expect(events, hasLength(2));
            expect(events.last.fromUserId, otherPeer);
            expect(service.getHistory(otherPeer), hasLength(1));
            expect(
              await service.receiveExtensionText(otherPeer, alias(127), 'E'),
              isFalse,
            );
            await pumpEventQueue();
            expect(events, hasLength(2));
          }
        } finally {
          if (blocked.existsSync()) blocked.deleteSync();
          Directory(blocked.path).createSync(recursive: true);
          await arrivals.cancel();
          await service.dispose();
          await root.delete(recursive: true);
        }
      },
    );
  }
}
