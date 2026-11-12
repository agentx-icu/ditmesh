import 'dart:convert';
import 'dart:typed_data';

import 'nearby_canonical_json.dart';
import 'nearby_crypto.dart';

part 'nearby_intent_records.dart';

/// The two records of the nearby protocol (`toxee/nearby/v1`, plan §3.4):
/// the broadcast **presence** and the private **intent**. Codecs plus the
/// receiver-side validation table. Signatures cover the canonical bytes of
/// the record without its `sig` member.
///
/// Limits are protocol constants; changing one is a protocol bump.
class NearbyLimits {
  NearbyLimits._();

  /// Whole frame (6-byte tim2tox header + payload).
  static const int maxFrameBytes = 1200;
  static const int frameHeaderBytes = 6;
  static const int maxPayloadBytes = maxFrameBytes - frameHeaderBytes;

  static const int presenceTtlSeconds = 180;
  static const int presenceAcceptPastSeconds = 60;
  static const int presenceAcceptFutureSeconds = 240;
  static const int intentTtlSeconds = 600;
  static const int intentAcceptFutureSeconds = 900;

  static const int nameMaxCodePoints = 32;
  static const int nameMaxBytes = 96;
  static const int messageMaxCodePoints = 140;
  // The frame budget binds first for non-ASCII text: the sealed body is hex
  // on the wire, so every message byte costs two frame bytes. In practice
  // ~220 UTF-8 bytes fit; the sender measures the frame before sending.
  static const int messageMaxBytes = 280;
  static const int maxCells = 8;
  static const int cellMaxLength = 12;
  static const int nonceBytes = 16;
  static const int addressHexLength = 76;

  /// Friend-request wording prefix that carries the intent nonce.
  static const String requestTag = 'toxee-nearby:';
}

/// A broadcast presence record.
class PresenceRecord {
  const PresenceRecord({
    required this.skHex,
    required this.ekHex,
    required this.seq,
    required this.exp,
    required this.name,
    required this.avatarHex,
    required this.latE3,
    required this.lonE3,
    required this.cells,
  });

  final String skHex;
  final String ekHex;
  final int seq;

  /// Unix seconds.
  final int exp;
  final String name;

  /// SHA-256 hex of the avatar, or empty.
  final String avatarHex;

  /// Milli-degrees (rounded to ~111 m).
  final int latE3;
  final int lonE3;

  /// Sorted geohash cells the sender is in.
  final List<String> cells;

  double get latitude => latE3 / 1000.0;
  double get longitude => lonE3 / 1000.0;

  Map<String, Object> toUnsigned() => {
    'avatar': avatarHex,
    'cells': List<String>.from(cells)..sort(),
    'ek': ekHex,
    'exp': exp,
    'lat_e3': latE3,
    'lon_e3': lonE3,
    'name': name,
    'seq': seq,
    'sk': skHex,
    't': 'presence',
    'v': 1,
  };

  /// Signed canonical bytes, ready to broadcast. Null when the record breaks a
  /// limit (the UI must shorten the name) or the frame budget.
  static Future<Uint8List?> encode(
    PresenceRecord record,
    NearbySessionKeys keys,
  ) async {
    final unsigned = record.toUnsigned();
    if (!_validPresenceFields(unsigned)) return null;
    final sig = await NearbyCrypto.sign(
      NearbyCanonicalJson.encode(unsigned),
      keys.signing,
    );
    final signed = Map<String, Object>.from(unsigned)
      ..['sig'] = NearbyCrypto.hex(sig);
    final bytes = NearbyCanonicalJson.encode(signed);
    if (bytes.length > NearbyLimits.maxPayloadBytes) return null;
    return bytes;
  }

  /// Parses and verifies a received presence payload: canonical form, field
  /// limits, signature under its own `sk`, expiry window around [nowSeconds].
  /// Returns null with the reason in [reason] (for diagnostics only).
  static Future<PresenceRecord?> decode(
    Uint8List payload,
    int nowSeconds, {
    List<String>? reason,
  }) async {
    void fail(String r) => reason?.add(r);
    if (payload.length > NearbyLimits.maxPayloadBytes) {
      fail('too large');
      return null;
    }
    final object = NearbyCanonicalJson.decodeObject(payload);
    if (object == null) {
      fail('not canonical');
      return null;
    }
    if (object['t'] != 'presence' || object['v'] != 1) {
      fail('type');
      return null;
    }
    final sigHex = object['sig'];
    if (sigHex is! String) {
      fail('sig');
      return null;
    }
    final unsigned = Map<String, Object>.from(object)..remove('sig');
    if (!_validPresenceFields(unsigned)) {
      fail('fields');
      return null;
    }
    final sig = NearbyCrypto.unhex(sigHex, length: NearbyCrypto.signatureBytes);
    final sk = NearbyCrypto.unhex(
      unsigned['sk'] as String,
      length: NearbyCrypto.keyBytes,
    );
    if (sig == null || sk == null) {
      fail('hex');
      return null;
    }
    final exp = unsigned['exp'] as int;
    if (exp <= nowSeconds - NearbyLimits.presenceAcceptPastSeconds ||
        exp > nowSeconds + NearbyLimits.presenceAcceptFutureSeconds) {
      fail('expiry');
      return null;
    }
    if (!await NearbyCrypto.verify(
      NearbyCanonicalJson.encode(unsigned),
      sig,
      sk,
    )) {
      fail('signature');
      return null;
    }
    return PresenceRecord(
      skHex: unsigned['sk'] as String,
      ekHex: unsigned['ek'] as String,
      seq: unsigned['seq'] as int,
      exp: exp,
      name: unsigned['name'] as String,
      avatarHex: unsigned['avatar'] as String,
      latE3: unsigned['lat_e3'] as int,
      lonE3: unsigned['lon_e3'] as int,
      cells: List<String>.from(unsigned['cells'] as List),
    );
  }

  static bool _validPresenceFields(Map<String, Object> m) {
    const keys = {
      'avatar',
      'cells',
      'ek',
      'exp',
      'lat_e3',
      'lon_e3',
      'name',
      'seq',
      'sk',
      't',
      'v',
    };
    if (m.keys.toSet().length != keys.length || !m.keys.every(keys.contains)) {
      return false;
    }
    final avatar = m['avatar'],
        cells = m['cells'],
        ek = m['ek'],
        exp = m['exp'];
    final lat = m['lat_e3'], lon = m['lon_e3'], name = m['name'];
    final seq = m['seq'], sk = m['sk'];
    if (avatar is! String ||
        !(avatar.isEmpty || NearbyCrypto.isLowerHex(avatar, length: 32))) {
      return false;
    }
    if (ek is! String || !NearbyCrypto.isLowerHex(ek, length: 32)) return false;
    if (sk is! String || !NearbyCrypto.isLowerHex(sk, length: 32)) return false;
    if (exp is! int || exp <= 0) return false;
    if (seq is! int || seq < 0 || seq > 0xFFFFFFFF) return false;
    if (lat is! int || lat < -90000 || lat > 90000) return false;
    if (lon is! int || lon < -180000 || lon >= 180000) return false;
    if (name is! String ||
        name.runes.length > NearbyLimits.nameMaxCodePoints ||
        utf8.encode(name).length > NearbyLimits.nameMaxBytes ||
        name.runes.any((r) => r < 0x20)) {
      return false;
    }
    if (cells is! List ||
        cells.isEmpty ||
        cells.length > NearbyLimits.maxCells) {
      return false;
    }
    String? previous;
    for (final c in cells) {
      if (c is! String || c.isEmpty || c.length > NearbyLimits.cellMaxLength) {
        return false;
      }
      if (!c.codeUnits.every(_isGeohashUnit)) return false;
      if (previous != null && c.compareTo(previous) <= 0) {
        return false; // sorted, unique
      }
      previous = c;
    }
    return true;
  }

  static bool _isGeohashUnit(int u) =>
      '0123456789bcdefghjkmnpqrstuvwxyz'.codeUnits.contains(u);
}

/// The plaintext of an intent box.
