import 'dart:convert';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

/// Optional local metadata carried by both durable history and queue items.
abstract final class RecordingMetadata {
  static String? encode(KeyedRecording? recording) => recording == null
      ? null
      : jsonEncode({'ditmeshRhythm': recording.toJson()});

  static KeyedRecording? decode(String? data) {
    if (data == null || data.length > 8192) return null;
    try {
      final decoded = jsonDecode(data);
      return decoded is Map
          ? KeyedRecording.fromJson(decoded['ditmeshRhythm'])
          : null;
    } on FormatException {
      return null;
    }
  }
}
