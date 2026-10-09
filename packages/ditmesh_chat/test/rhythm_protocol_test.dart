import 'dart:convert';
import 'package:ditmesh_chat/src/engine/rhythm_protocol.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final recording = KeyedRecording(durationsMs: [83, 113, 251]);
  test('out of order chunks bind to exact sender conversation and message', () {
    final protocol = RhythmPacketAssembler();
    final a = RhythmProtocol.packets('a' * 32, {
      'text': 'same',
      'recording': recording.toJson(),
    });
    final b = RhythmProtocol.packets('b' * 32, {
      'text': 'same',
      'recording': {
        'version': 1,
        'durationsMs': [199],
      },
    });
    Map<String, dynamic>? assembled;
    for (final packet in a.reversed) {
      assembled = protocol.add('sender', 'group-A', packet) ?? assembled;
    }
    expect(assembled?['recording'], recording.toJson());
    expect(protocol.add('other', 'group-A', b.single)?['recording'], {
      'version': 1,
      'durationsMs': [199],
    });
    expect(protocol.add('sender', 'group-B', b.single)?['text'], 'same');
  });
  test('large recordings fit native packet budget and cannot mix chunks', () {
    final a = RhythmProtocol.packets('a' * 32, {
      'text': 'CQ' * 600,
      'recording': KeyedRecording(durationsMs: List.filled(511, 100)).toJson(),
    });
    expect(a.length, greaterThan(1));
    expect(a.every((packet) => utf8.encode(packet).length <= 1300), isTrue);
    final assembler = RhythmPacketAssembler();
    expect(assembler.add('sender', '', a.first), isNull);
    final corrupt = jsonDecode(a.first) as Map<String, dynamic>;
    corrupt['body'] = base64Encode(utf8.encode('different'));
    expect(assembler.add('sender', '', jsonEncode(corrupt)), isNull);
    expect(assembler.add('sender', '', a.last), isNull);
    expect(
      assembler.add('sender', '', '{"ditmesh":1,"kind":"chunk","total":99999}'),
      isNull,
    );
  });
}
