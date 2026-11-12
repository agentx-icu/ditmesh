import 'dart:convert';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:test/test.dart';

void main() {
  test('decodes the exact Toxee location envelope', () {
    final location = ChatLocation.tryDecode(
      '__location__:{"desc":"Station","longitude":116.4074,"latitude":39.9042}',
    );
    expect(location, isNotNull);
    expect(location!.latitude, 39.9042);
    expect(location.longitude, 116.4074);
    expect(location.description, 'Station');
    final encoded =
        jsonDecode(location.encode().substring(ChatLocation.prefix.length))
            as Map;
    expect(encoded, {
      'desc': 'Station',
      'longitude': 116.4074,
      'latitude': 39.9042,
    });
  });

  test(
    'rejects malformed, non-finite, out-of-range and oversized coordinates',
    () {
      for (final text in [
        '39.9, 116.4',
        '__location__:{"latitude":39,"longitude":116,"desc":"${'中' * 500}"}',
        '__location__:[]',
        '__location__:{',
        '__location__:{"latitude":"39","longitude":116}',
        '__location__:{"latitude":91,"longitude":116}',
        '__location__:{"latitude":39,"longitude":181}',
        '__location__:{"latitude":1e999,"longitude":116}',
        '__location__:{"latitude":39,"longitude":116,"desc":[]}',
        '__location__:{"latitude":39,"longitude":116,"desc":"${'x' * 1400}"}',
      ]) {
        expect(
          ChatLocation.tryDecode(text),
          isNull,
          reason: text.substring(0, text.length.clamp(0, 80)),
        );
      }
      expect(
        () => const ChatLocation(latitude: double.nan, longitude: 0).encode(),
        throwsArgumentError,
      );
    },
  );

  test(
    'location content is identified even when invalid, and survives message copies',
    () {
      const wire = '__location__:{"desc":null,"latitude":0,"longitude":0}';
      final row = ChatMessage(
        id: 'location',
        conversationId: 'c2c_peer',
        senderId: 'peer',
        text: wire,
        timestamp: DateTime(2026),
        status: MessageStatus.received,
        isMine: false,
      );
      expect(row.isLocation, isTrue);
      expect(row.location!.latitude, 0);
      expect(
        row.copyWith(status: MessageStatus.delivered).location!.longitude,
        0,
      );
      expect(row.copyWith().text, wire);
    },
  );

  test('peer description is text and cannot inject direction controls', () {
    final location = ChatLocation.tryDecode(
      '__location__:{"desc":"Station\\u202e\\nA","latitude":1,"longitude":2}',
    );
    expect(location!.description, 'Station A');
  });
}
