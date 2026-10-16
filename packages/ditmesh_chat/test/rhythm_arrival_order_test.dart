import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/src/engine/ditmesh_ffi_chat_service.dart';
import 'package:ditmesh_chat/src/engine/rhythm_protocol.dart';
import 'package:ditmesh_chat/src/engine/rhythm_transport.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:tim2tox_dart/models/chat_message.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';
import 'helpers/fakes.dart';

/// Captures every extension packet the service puts on the wire.
class _PacketFfi extends FakeTim2ToxFfi {
  final List<String> packets = [];
  @override
  int Function(ffi.Pointer<Utf8>, ffi.Pointer<ffi.Uint8>, int, int)
  get sendC2CControlNative => (_, data, count, route) {
    final decoded = jsonDecode(utf8.decode(data.asTypedList(count))) as Map;
    packets.add(
      utf8.decode(base64Decode((decoded['msgID'] as String).substring(5))),
    );
    return 1;
  };
}

/// Two recorded messages from one peer must be stored in the order they
/// arrived, even when storing the first one takes longer: the receive path
/// stamps and appends a row only after awaiting disk work.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'direct recorded arrivals from one peer are received in order',
    () async {
      final dir = await Directory.systemTemp.createTemp('ditmesh_order_');
      final native = _PacketFfi()
        ..friends.add((userId: kPeerKey, nick: 'Bob', online: true));
      final svc =
          DitmeshFfiChatService(
              ffiForTesting: native,
              historyDirectory: dir.path,
            )
            ..debugBeginSessionForTest()
            ..debugSetSelfId(kSelfKey);
      final started = <String>[];
      final finished = <String>[];
      final slowFirst = Completer<void>();
      final transport = RhythmTransport(
        svc,
        receiveText:
            (
              sender,
              alias,
              text, {
              metadata,
              kind = ChatMessageContentKind.normal,
            }) async {
              started.add(text);
              if (text == 'ONE') await slowFirst.future;
              finished.add(text);
              return true;
            },
      );
      try {
        // Our hello carries the session the peer must address envelopes to.
        transport.presence(kPeerKey, true);
        final hello = jsonDecode(native.packets.last) as Map<String, dynamic>;
        final session = hello['session'] as String;

        List<String> envelope(String text) {
          final id = RhythmProtocol.freshId();
          return RhythmProtocol.packets(id, {
            'version': 1,
            'id': RhythmProtocol.freshId(),
            'transferId': id,
            'session': session,
            'authorSession': 'e' * 32,
            'text': text,
            'contentKind': 'normal',
            'recording': KeyedRecording(durationsMs: [80, 80, 240]).toJson(),
          });
        }

        for (final text in ['ONE', 'TWO']) {
          for (final packet in envelope(text)) {
            expect(transport.consume(kPeerKey, packet), isTrue);
          }
        }
        await pumpEventQueue();
        expect(started, ['ONE'], reason: 'TWO waits for ONE to be stored');

        slowFirst.complete();
        await pumpEventQueue();
        expect(started, ['ONE', 'TWO']);
        expect(finished, ['ONE', 'TWO']);

        // The chain is released: a later arrival is received at once.
        for (final packet in envelope('THREE')) {
          transport.consume(kPeerKey, packet);
        }
        await pumpEventQueue();
        expect(finished, ['ONE', 'TWO', 'THREE']);
      } finally {
        await svc.dispose();
        await dir.delete(recursive: true);
      }
    },
  );

  test('a failed arrival does not block the next one', () async {
    final dir = await Directory.systemTemp.createTemp('ditmesh_order_');
    final native = _PacketFfi()
      ..friends.add((userId: kPeerKey, nick: 'Bob', online: true));
    final svc =
        DitmeshFfiChatService(ffiForTesting: native, historyDirectory: dir.path)
          ..debugBeginSessionForTest()
          ..debugSetSelfId(kSelfKey);
    final finished = <String>[];
    final transport = RhythmTransport(
      svc,
      receiveText:
          (
            sender,
            alias,
            text, {
            metadata,
            kind = ChatMessageContentKind.normal,
          }) async {
            if (text == 'BAD') throw StateError('disk full');
            finished.add(text);
            return true;
          },
    );
    try {
      transport.presence(kPeerKey, true);
      final session =
          (jsonDecode(native.packets.last) as Map<String, dynamic>)['session']
              as String;
      for (final text in ['BAD', 'GOOD']) {
        final id = RhythmProtocol.freshId();
        for (final packet in RhythmProtocol.packets(id, {
          'version': 1,
          'id': RhythmProtocol.freshId(),
          'transferId': id,
          'session': session,
          'authorSession': 'e' * 32,
          'text': text,
          'contentKind': 'normal',
          'recording': KeyedRecording(durationsMs: [80]).toJson(),
        })) {
          transport.consume(kPeerKey, packet);
        }
      }
      await pumpEventQueue();
      expect(finished, ['GOOD']);
    } finally {
      await svc.dispose();
      await dir.delete(recursive: true);
    }
  });

  test(
    'a clear while an arrival waits drops it unstored and unACKed',
    () async {
      final rig = await _Rig.open(persist: true);
      final hold = rig.holds['ONE'] = Completer<void>();
      try {
        final one = rig.deliver('ONE');
        final two = rig.deliver('TWO');
        await _until(() => rig.stored.contains('ONE'));
        await rig.svc.clearC2CHistory(kPeerKey);
        hold.complete();
        await pumpEventQueue();
        expect(rig.received, ['ONE'], reason: 'TWO arrived before the clear');
        expect(rig.svc.getHistory(kPeerKey), isEmpty);
        // ONE was durable before the clear, so its sender still gets a receipt.
        expect(rig.acked, [one]);
        expect(rig.acked, isNot(contains(two)));
      } finally {
        await rig.close();
      }
    },
  );

  test('a session change while an arrival waits drops it unACKed', () async {
    final rig = await _Rig.open(persist: true);
    final hold = rig.holds['ONE'] = Completer<void>();
    try {
      rig
        ..deliver('ONE')
        ..deliver('TWO');
      await _until(() => rig.stored.contains('ONE'));
      rig.svc
        ..debugCloseSessionForTest()
        ..debugBeginSessionForTest();
      hold.complete();
      await pumpEventQueue();
      expect(rig.received, ['ONE'], reason: 'TWO belongs to the old session');
      expect(rig.acked, isEmpty);
    } finally {
      await rig.close();
    }
  });

  test('admitted arrivals are bounded while one is stalled', () async {
    final rig = await _Rig.open();
    final hold = rig.holds['FIRST'] = Completer<void>();
    try {
      rig.deliver('FIRST');
      for (var i = 1; i <= 129; i++) {
        rig.deliver('N$i');
      }
      await pumpEventQueue();
      expect(rig.received, ['FIRST']);
      hold.complete();
      await pumpEventQueue();
      expect(rig.received, hasLength(128));
      expect(rig.received.last, 'N127');
      expect(
        rig.acked,
        hasLength(128),
        reason: 'dropped arrivals stay unACKed',
      );
      // Finished arrivals release their places.
      final later = rig.deliver('LATER');
      await pumpEventQueue();
      expect(rig.received.last, 'LATER');
      expect(rig.acked.last, later);
    } finally {
      await rig.close();
    }
  });

  test('a duplicate of a waiting arrival is not queued again', () async {
    final rig = await _Rig.open();
    final hold = rig.holds['FIRST'] = Completer<void>();
    try {
      rig.deliver('FIRST');
      final id = RhythmProtocol.freshId();
      rig
        ..deliver('DUP', id: id)
        ..deliver('DUP', id: id);
      hold.complete();
      await pumpEventQueue();
      expect(rig.received, ['FIRST', 'DUP']);
      expect(rig.acked.where((acked) => acked == id), hasLength(1));
    } finally {
      await rig.close();
    }
  });
}

Future<void> _until(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue, reason: 'asynchronous receive must settle');
}

/// A service and transport whose receiver records each call and can hold a
/// text's receive open; with [persist] it first stores through the service.
class _Rig {
  _Rig._(this.dir, this.persist) {
    transport.presence(kPeerKey, true);
    session =
        (jsonDecode(native.packets.last) as Map<String, dynamic>)['session']
            as String;
  }

  static Future<_Rig> open({bool persist = false}) async =>
      _Rig._(await Directory.systemTemp.createTemp('ditmesh_order_'), persist);

  final Directory dir;
  final bool persist;
  late final native = _PacketFfi()
    ..friends.add((userId: kPeerKey, nick: 'Bob', online: true));
  late final svc =
      DitmeshFfiChatService(ffiForTesting: native, historyDirectory: dir.path)
        ..debugBeginSessionForTest()
        ..debugSetSelfId(kSelfKey);
  late final transport = RhythmTransport(svc, receiveText: _receive);
  late final String session;
  final received = <String>[];
  final stored = <String>[];
  final holds = <String, Completer<void>>{};

  Future<bool> _receive(
    String sender,
    String alias,
    String text, {
    String? metadata,
    ChatMessageContentKind kind = ChatMessageContentKind.normal,
  }) async {
    received.add(text);
    final published =
        !persist ||
        await svc.receiveExtensionText(
          sender,
          alias,
          text,
          metadata: metadata,
          kind: kind,
        );
    stored.add(text);
    await holds[text]?.future;
    return published;
  }

  /// Delivers one complete envelope and returns its message ID.
  String deliver(String text, {String? id}) {
    final messageId = id ?? RhythmProtocol.freshId();
    final transferId = RhythmProtocol.freshId();
    for (final packet in RhythmProtocol.packets(transferId, {
      'version': 1,
      'id': messageId,
      'transferId': transferId,
      'session': session,
      'authorSession': 'e' * 32,
      'text': text,
      'contentKind': 'normal',
      'recording': KeyedRecording(durationsMs: [80]).toJson(),
    })) {
      expect(transport.consume(kPeerKey, packet), isTrue);
    }
    return messageId;
  }

  /// Message IDs acknowledged so far, in order.
  List<String> get acked => [
    for (final packet in native.packets)
      if (jsonDecode(packet) case {'kind': 'ack', 'id': final String id}) id,
  ];

  Future<void> close() async {
    for (final hold in holds.values) {
      if (!hold.isCompleted) hold.complete();
    }
    await svc.dispose();
    await dir.delete(recursive: true);
  }
}
