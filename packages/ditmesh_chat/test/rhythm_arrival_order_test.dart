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
}
