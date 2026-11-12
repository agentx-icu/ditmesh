part of 'nearby_records.dart';

class IntentBody {
  const IntentBody({
    required this.address,
    required this.nonceHex,
    required this.message,
    required this.exp,
  });

  /// 76-hex Tox address of the initiator.
  final String address;

  /// 16-byte nonce, lower-case hex; echoed in the friend request wording.
  final String nonceHex;
  final String message;
  final int exp;

  Map<String, Object> toJson() => {
    'addr': address,
    'exp': exp,
    'msg': message,
    'n': nonceHex,
  };

  static bool validMessage(String msg) =>
      msg.runes.length <= NearbyLimits.messageMaxCodePoints &&
      utf8.encode(msg).length <= NearbyLimits.messageMaxBytes &&
      !msg.runes.any((r) => r < 0x20 && r != 0x0a);

  /// Bytes the message costs inside the sealed body (canonical-JSON escaped
  /// UTF-8). What the UI counter shows.
  static int messageWireBytes(String msg) =>
      NearbyCanonicalJson.encode(<String, Object>{'m': msg}).length - 8;

  /// The largest [messageWireBytes] an intent can carry: the frame budget
  /// minus every other byte of the record (body members addr/exp/n, the
  /// 16-byte tag, the hex doubling of the box, the outer record's fixed
  /// members). Pinned by test against [IntentRecord.encode]; the frame
  /// budget binds before [NearbyLimits.messageMaxBytes].
  static const int maxMessageWireBytes =
      (NearbyLimits.maxPayloadBytes - 778) ~/ 2;

  static bool fitsFrame(String msg) =>
      messageWireBytes(msg) <= maxMessageWireBytes;

  /// The friend-request wording that carries the nonce.
  String requestWording() => '${NearbyLimits.requestTag}$nonceHex $message';

  /// Extracts the nonce from a friend-request wording, or null.
  static String? nonceFromWording(String? wording) {
    if (wording == null || !wording.startsWith(NearbyLimits.requestTag)) {
      return null;
    }
    final rest = wording.substring(NearbyLimits.requestTag.length);
    final end = rest.indexOf(' ');
    final n = end < 0 ? rest : rest.substring(0, end);
    return NearbyCrypto.isLowerHex(n, length: NearbyLimits.nonceBytes)
        ? n
        : null;
  }
}

/// A sealed intent as sent on the wire.
class IntentRecord {
  const IntentRecord({
    required this.fromSkHex,
    required this.toEkHex,
    required this.epkHex,
    required this.nonce24Hex,
    required this.boxHex,
  });

  final String fromSkHex;
  final String toEkHex;
  final String epkHex;
  final String nonce24Hex;
  final String boxHex;

  /// The associated data: the header fields with values.
  static Map<String, Object> aadOf(String from, String to, String epk) => {
    'epk': epk,
    'from': from,
    't': 'intent',
    'to': to,
    'v': 1,
  };

  /// Builds, seals and signs an intent. Null when the message breaks a limit
  /// or the frame budget (the UI shortens the message).
  static Future<Uint8List?> encode({
    required NearbySessionKeys keys,
    required String recipientEkHex,
    required IntentBody body,
  }) async {
    if (!IntentBody.validMessage(body.message)) return null;
    if (!NearbyCrypto.isLowerHex(
          body.address,
          length: NearbyLimits.addressHexLength ~/ 2,
        ) ||
        !NearbyCrypto.isLowerHex(
          body.nonceHex,
          length: NearbyLimits.nonceBytes,
        )) {
      return null;
    }
    final recipientEk = NearbyCrypto.unhex(
      recipientEkHex,
      length: NearbyCrypto.keyBytes,
    );
    if (recipientEk == null) return null;
    final plaintext = NearbyCanonicalJson.encode(body.toJson());
    // epk is only known after sealing, so seal with a fresh ephemeral key
    // whose public half we compute first.
    final eph = await NearbyCrypto.newEphemeral();
    final epkHex = NearbyCrypto.hex(await NearbyCrypto.publicKeyBytes(eph));
    final aad = NearbyCanonicalJson.encode(
      aadOf(keys.skHex, recipientEkHex, epkHex),
    );
    final sealed = await NearbyCrypto.seal(
      recipientEk: recipientEk,
      plaintext: plaintext,
      aad: aad,
      ephemeral: eph,
    );
    final unsigned = <String, Object>{
      'box': NearbyCrypto.hex(sealed.box),
      'epk': epkHex,
      'from': keys.skHex,
      'n24': NearbyCrypto.hex(sealed.nonce24),
      't': 'intent',
      'to': recipientEkHex,
      'v': 1,
    };
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

  /// Parses and verifies the outer record (canonical, fields, signature under
  /// `from`). Decrypting the box is a second step ([open]) because it needs
  /// the recipient's keys and the binding checks of the service.
  static Future<IntentRecord?> decode(
    Uint8List payload, {
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
    const keys = {'box', 'epk', 'from', 'n24', 'sig', 't', 'to', 'v'};
    if (object.keys.toSet().length != keys.length ||
        !object.keys.every(keys.contains)) {
      fail('fields');
      return null;
    }
    if (object['t'] != 'intent' || object['v'] != 1) {
      fail('type');
      return null;
    }
    final box = object['box'], epk = object['epk'], from = object['from'];
    final n24 = object['n24'], sigHex = object['sig'], to = object['to'];
    if (box is! String ||
        epk is! String ||
        from is! String ||
        n24 is! String ||
        sigHex is! String ||
        to is! String) {
      fail('types');
      return null;
    }
    if (!NearbyCrypto.isLowerHex(epk, length: 32) ||
        !NearbyCrypto.isLowerHex(from, length: 32) ||
        !NearbyCrypto.isLowerHex(to, length: 32) ||
        !NearbyCrypto.isLowerHex(n24, length: NearbyCrypto.nonceBytes) ||
        !NearbyCrypto.isLowerHex(box) ||
        box.length < NearbyCrypto.macBytes * 2) {
      fail('hex');
      return null;
    }
    final sig = NearbyCrypto.unhex(sigHex, length: NearbyCrypto.signatureBytes);
    if (sig == null) {
      fail('sig');
      return null;
    }
    final unsigned = Map<String, Object>.from(object)..remove('sig');
    if (!await NearbyCrypto.verify(
      NearbyCanonicalJson.encode(unsigned),
      sig,
      NearbyCrypto.unhex(from, length: 32)!,
    )) {
      fail('signature');
      return null;
    }
    return IntentRecord(
      fromSkHex: from,
      toEkHex: to,
      epkHex: epk,
      nonce24Hex: n24,
      boxHex: box,
    );
  }

  /// Opens the box with the recipient's agreement key and validates the body
  /// against [nowSeconds]. Null when it does not authenticate or is expired.
  Future<IntentBody?> open(
    NearbySessionKeys recipient,
    int nowSeconds, {
    List<String>? reason,
  }) async {
    void fail(String r) => reason?.add(r);
    if (toEkHex != recipient.ekHex) {
      fail('not for me');
      return null;
    }
    final aad = NearbyCanonicalJson.encode(aadOf(fromSkHex, toEkHex, epkHex));
    final clear = await NearbyCrypto.open(
      recipientAgreement: recipient.agreement,
      epk: NearbyCrypto.unhex(epkHex, length: 32)!,
      nonce24: NearbyCrypto.unhex(nonce24Hex, length: NearbyCrypto.nonceBytes)!,
      box: NearbyCrypto.unhex(boxHex)!,
      aad: aad,
    );
    if (clear == null) {
      fail('box');
      return null;
    }
    final object = NearbyCanonicalJson.decodeObject(clear);
    if (object == null) {
      fail('body not canonical');
      return null;
    }
    const keys = {'addr', 'exp', 'msg', 'n'};
    if (object.keys.toSet().length != keys.length ||
        !object.keys.every(keys.contains)) {
      fail('body fields');
      return null;
    }
    final addr = object['addr'], exp = object['exp'], msg = object['msg'];
    final n = object['n'];
    if (addr is! String || exp is! int || msg is! String || n is! String) {
      fail('body types');
      return null;
    }
    if (!NearbyCrypto.isLowerHex(
          addr,
          length: NearbyLimits.addressHexLength ~/ 2,
        ) ||
        !NearbyCrypto.isLowerHex(n, length: NearbyLimits.nonceBytes) ||
        !IntentBody.validMessage(msg)) {
      fail('body values');
      return null;
    }
    if (exp <= nowSeconds ||
        exp > nowSeconds + NearbyLimits.intentAcceptFutureSeconds) {
      fail('body expiry');
      return null;
    }
    return IntentBody(address: addr, nonceHex: n, message: msg, exp: exp);
  }
}
