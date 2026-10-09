import 'dart:convert';
import 'dart:math';

/// Versioned extension on Tox's authenticated custom transport. Chunk identity
/// is scoped by the native sender and conversation, never by text equality.
abstract final class RhythmProtocol {
  static const maxEnvelopeBytes = 8192;
  static const maxParts = 24;
  static const chunkBytes = 352;
  static final _id = RegExp(r'^[a-f0-9]{32}$');

  static bool validId(Object? id) => id is String && _id.hasMatch(id);
  static String freshId() => List.generate(
    16,
    (_) => Random.secure().nextInt(256),
  ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  static String control(String kind, Map<String, Object?> data) =>
      jsonEncode({'ditmesh': 1, 'kind': kind, ...data});

  static Map<String, dynamic>? parse(String payload) {
    if (payload.length > 1300) return null;
    try {
      final value = jsonDecode(payload);
      return value is Map<String, dynamic> && value['ditmesh'] == 1
          ? value
          : null;
    } on FormatException {
      return null;
    }
  }

  static List<String> packets(String id, Map<String, Object?> envelope) {
    final bytes = utf8.encode(jsonEncode(envelope));
    if (!validId(id) || bytes.length > maxEnvelopeBytes) {
      throw ArgumentError('Invalid timing envelope');
    }
    final total = (bytes.length / chunkBytes).ceil();
    return [
      for (var i = 0; i < total; i++)
        control('chunk', {
          'id': id,
          'index': i,
          'total': total,
          'body': base64Encode(
            bytes.sublist(
              i * chunkBytes,
              min(bytes.length, (i + 1) * chunkBytes),
            ),
          ),
        }),
    ];
  }
}

class _Assembly {
  _Assembly(this.total, this.expires);
  final int total;
  final DateTime expires;
  final Map<int, List<int>> parts = {};
  int size = 0;
}

final class RhythmPacketAssembler {
  RhythmPacketAssembler({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  final Map<String, _Assembly> _pending = {};
  final Map<String, DateTime> _rejected = {};

  Map<String, dynamic>? add(
    String sender,
    String conversation,
    String payload,
  ) {
    final value = RhythmProtocol.parse(payload);
    if (value == null || value['kind'] != 'chunk') return null;
    final id = value['id'];
    final total = value['total'];
    final index = value['index'];
    final body = value['body'];
    if (!RhythmProtocol.validId(id) ||
        total is! int ||
        index is! int ||
        total <= 0 ||
        total > RhythmProtocol.maxParts ||
        index < 0 ||
        index >= total ||
        body is! String ||
        body.length > 1024) {
      return null;
    }
    final now = _clock();
    _pending.removeWhere((_, v) => v.expires.isBefore(now));
    _rejected.removeWhere((_, expires) => expires.isBefore(now));
    final key = '$sender\u0000$conversation\u0000$id';
    if (_rejected.containsKey(key)) return null;
    if (!_pending.containsKey(key) && _pending.length >= 32) {
      _pending.remove(_pending.keys.first);
    }
    final state = _pending.putIfAbsent(
      key,
      () => _Assembly(total, now.add(const Duration(seconds: 30))),
    );
    try {
      final bytes = base64Decode(body);
      final previous = state.parts[index];
      if (state.total != total ||
          bytes.length > RhythmProtocol.chunkBytes ||
          (previous != null && base64Encode(previous) != body)) {
        _reject(key, now);
        return null;
      }
      if (previous == null) {
        state.parts[index] = bytes;
        state.size += bytes.length;
      }
      if (state.size > RhythmProtocol.maxEnvelopeBytes) {
        _reject(key, now);
        return null;
      }
      if (state.parts.length != total) return null;
      _pending.remove(key);
      final decoded = jsonDecode(
        utf8.decode([for (var i = 0; i < total; i++) ...state.parts[i]!]),
      );
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      _reject(key, now);
      return null;
    }
  }

  void _reject(String key, DateTime now) {
    _pending.remove(key);
    if (_rejected.length >= 64) _rejected.remove(_rejected.keys.first);
    _rejected[key] = now.add(const Duration(seconds: 30));
  }
}
