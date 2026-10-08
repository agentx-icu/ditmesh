import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/identity/password_verifier.dart';

void main() {
  test('pbkdf2Sha256 matches the RFC 7914 / RFC 6070-derived test vector', () {
    // PBKDF2-HMAC-SHA256("password", "salt", c=1, dkLen=32) — from RFC 7914 §11.
    final out = pbkdf2Sha256(utf8.encode('password'), utf8.encode('salt'), 1, 32);
    expect(
      out.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
    );
    // c=2 from the same section.
    final two = pbkdf2Sha256(utf8.encode('password'), utf8.encode('salt'), 2, 32);
    expect(
      two.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
    );
  });

  test('set / verify / remove, with per-identity keys', () async {
    final store = MemorySecureStore();
    final v = PasswordVerifier(store, iterations: 200);
    expect(await v.hasPassword('A' * 76), isFalse);
    await v.setPassword('A' * 76, 'secret');
    expect(await v.hasPassword('A' * 76), isTrue);
    expect(await v.hasPassword('B' * 76), isFalse);
    expect(await v.verify('A' * 76, 'secret'), isTrue);
    expect(await v.verify('A' * 76, 'Secret'), isFalse);
    expect(await v.verify('B' * 76, 'secret'), isFalse);
    expect(store.values.values.single, startsWith(r'pbkdf2-sha256$200$'));
    await v.removePassword('A' * 76);
    expect(await v.hasPassword('A' * 76), isFalse);
    expect(await v.verify('A' * 76, 'secret'), isFalse);
  });

  test('an empty password clears the verifier', () async {
    final v = PasswordVerifier(MemorySecureStore(), iterations: 10);
    await v.setPassword('A' * 76, 'x');
    await v.setPassword('A' * 76, '');
    expect(await v.hasPassword('A' * 76), isFalse);
  });
}
