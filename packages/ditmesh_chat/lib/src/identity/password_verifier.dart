import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'secure_store.dart';

/// Durable "does this identity have a password, and is this it?" check.
///
/// Mirrors toxee's `PasswordVerifier`: a PBKDF2-HMAC-SHA256 hash + random
/// salt lives in the platform secure store, keyed by the identity's Tox ID.
/// The verifier is the AUTHORITY on protection state — `tox_profile.tox` is
/// plaintext for the whole of a connected session (Tox rewrites it as it
/// runs), so "is the file encrypted right now" cannot be the gate. The
/// Tox-level `tox_pass_decrypt` is the second factor: a wrong password also
/// fails there, but only when the file happens to be encrypted.
class PasswordVerifier {
  PasswordVerifier(this._store, {this.iterations = defaultIterations});

  final SecureStore _store;

  /// PBKDF2 rounds for new verifiers: ~0.35 s on a desktop and ~1-1.5 s on
  /// a mid-range phone, off the UI isolate. The stored value names its own
  /// rounds, so older (60k) verifiers keep verifying and are rewritten at
  /// these rounds on the next successful unlock ([needsRehash]).
  static const int defaultIterations = 200000;

  /// PBKDF2 rounds new verifiers are written with.
  final int iterations;

  static const int _saltLength = 16;
  static const int _hashLength = 32;

  static String _key(String toxId) =>
      'ditmesh.password.${toxId.trim().toUpperCase()}';

  Future<bool> hasPassword(String toxId) async {
    final v = await _store.read(_key(toxId));
    return v != null && v.isNotEmpty;
  }

  Future<void> setPassword(String toxId, String password) async {
    if (password.isEmpty) return removePassword(toxId);
    final salt = _randomBytes(_saltLength);
    final hash = await _derive(password, salt, iterations);
    await _store.write(
      _key(toxId),
      'pbkdf2-sha256\$$iterations\$${_hex(salt)}\$${_hex(hash)}',
    );
  }

  Future<void> removePassword(String toxId) => _store.delete(_key(toxId));

  /// Rolls the verifier back if the corresponding profile/record write fails.
  Future<T> replacePassword<T>(
    String toxId,
    String? password,
    Future<T> Function() commit,
  ) async {
    final key = _key(toxId);
    final previous = await _store.read(key);
    try {
      if (password == null || password.isEmpty) {
        await removePassword(toxId);
      } else {
        await setPassword(toxId, password);
      }
      return await commit();
    } catch (_) {
      if (previous == null) {
        await _store.delete(key);
      } else {
        await _store.write(key, previous);
      }
      rethrow;
    }
  }

  /// False when no password is set, the password does not match, or the
  /// stored value is malformed (the caller may then rewrite it once the
  /// password is proven another way). A secure-store read failure throws.
  Future<bool> verify(String toxId, String password) async {
    final parsed = _parse(await _store.read(_key(toxId)));
    if (parsed == null) return false;
    final (rounds, salt, expected) = parsed;
    final actual = await _derive(password, salt, rounds);
    return _constantTimeEquals(expected, actual);
  }

  /// True when a verifier is stored but is malformed or uses fewer rounds
  /// than [iterations]: a successful unlock should rewrite it.
  Future<bool> needsRehash(String toxId) async {
    final stored = await _store.read(_key(toxId));
    if (stored == null || stored.isEmpty) return false;
    final parsed = _parse(stored);
    return parsed == null || parsed.$1 < iterations;
  }

  static final RegExp _hexPattern = RegExp(r'^(?:[0-9a-fA-F]{2})+$');

  /// `(rounds, salt, hash)` of a well-formed stored value, else null: an
  /// odd-length or non-hex field must not decode to a shorter value.
  static (int, Uint8List, Uint8List)? _parse(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != 'pbkdf2-sha256') return null;
    final rounds = int.tryParse(parts[1]);
    if (rounds == null || rounds <= 0) return null;
    if (parts[2].length != _saltLength * 2 ||
        parts[3].length != _hashLength * 2 ||
        !_hexPattern.hasMatch(parts[2]) ||
        !_hexPattern.hasMatch(parts[3])) {
      return null;
    }
    return (rounds, _unhex(parts[2]), _unhex(parts[3]));
  }

  static Future<Uint8List> _derive(
    String password,
    Uint8List salt,
    int rounds,
  ) {
    final pw = utf8.encode(password);
    // Off the UI isolate: 200k HMAC rounds are a visible stall on a phone.
    return Isolate.run(() => pbkdf2Sha256(pw, salt, rounds, _hashLength));
  }

  static Uint8List _randomBytes(int n) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(n, (_) => rng.nextInt(256)));
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List _unhex(String s) {
    final out = Uint8List(s.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// PBKDF2 with HMAC-SHA256 (RFC 8018 §5.2). `package:crypto` ships HMAC but
/// no PBKDF2, so the block loop lives here. Pure Dart; runs in an isolate.
Uint8List pbkdf2Sha256(
  List<int> password,
  List<int> salt,
  int rounds,
  int keyLength,
) {
  final hmac = Hmac(sha256, password);
  final blocks = (keyLength / 32).ceil();
  final out = Uint8List(blocks * 32);
  for (var block = 1; block <= blocks; block++) {
    final blockBytes = Uint8List(4)
      ..buffer.asByteData().setUint32(0, block, Endian.big);
    var u = Uint8List.fromList(hmac.convert([...salt, ...blockBytes]).bytes);
    final t = Uint8List.fromList(u);
    for (var i = 1; i < rounds; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    out.setRange((block - 1) * 32, block * 32, t);
  }
  return Uint8List.sublistView(out, 0, keyLength);
}
