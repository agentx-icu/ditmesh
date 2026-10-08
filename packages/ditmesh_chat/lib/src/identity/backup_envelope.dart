import 'dart:typed_data';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'profile_crypto.dart';

/// The authenticated encrypted envelope of a complete backup (F10).
///
/// ```text
/// magic      4 bytes  "MCQE"
/// version    u8       1
/// suite      u8       1 = toxencryptsave: libsodium scrypt (salsa208/sha256)
///                         key derivation with a random 32-byte salt, then
///                         XSalsa20-Poly1305 (the `tox_pass_encrypt` format)
/// reserved   2 bytes  0
/// sealed     the suite's output over (header ‖ inner archive)
/// ```
///
/// The 8-byte header is public: it is what decryption needs (format and
/// suite). It is also sealed inside, and [open] rejects a header that does
/// not match its sealed copy, so it is authenticated too. Everything else —
/// identity metadata, chat text, learning content, the private manifest —
/// is only in the sealed part. The KDF parameters are the library's fixed,
/// supported ones (stored implicitly by the suite id, together with the salt
/// inside the sealed blob); a future suite gets a new id.
///
/// The suite reuses the Tox savedata encryption this package already binds
/// on every platform ([ProfileCrypto]) instead of inventing a primitive.
abstract final class BackupEnvelope {
  static const int version = 1;
  static const int suiteToxEncryptSave = 1;
  static const int headerLength = 8;

  /// Largest sealed backup accepted; matches what the app can hold in memory.
  static const int maxBytes = maxBackupFileBytes;

  static Uint8List header() => Uint8List.fromList([
    ...encryptedBackupMagic,
    version,
    suiteToxEncryptSave,
    0,
    0,
  ]);

  static Uint8List seal(
    Uint8List inner,
    String passphrase,
    ProfileCrypto crypto,
  ) {
    if (passphrase.isEmpty) {
      throw const ChatException('wrong_passphrase', 'Passphrase required');
    }
    final head = header();
    if (inner.length + head.length + toxPassEncryptionExtraLength * 2 >
        maxBytes) {
      throw const ChatException('backup_too_large', 'Backup is too large');
    }
    final plain = Uint8List(head.length + inner.length)
      ..setAll(0, head)
      ..setAll(head.length, inner);
    final sealed = crypto.encrypt(plain, passphrase);
    return Uint8List(head.length + sealed.length)
      ..setAll(0, head)
      ..setAll(head.length, sealed);
  }

  /// The inner archive. Throws `unsupported_backup_version` for an unknown
  /// version or suite, `invalid_backup` for a malformed or oversized file,
  /// and `wrong_passphrase` when the passphrase does not open it or the data
  /// was altered or truncated (the cipher cannot tell those apart).
  static Uint8List open(
    Uint8List bytes,
    String passphrase,
    ProfileCrypto crypto,
  ) {
    if (!isEncryptedBackup(bytes) ||
        bytes.length < headerLength + toxPassEncryptionExtraLength) {
      throw const ChatException('invalid_backup', 'Not an encrypted backup');
    }
    if (bytes.length > maxBytes) {
      throw const ChatException('backup_too_large', 'Backup is too large');
    }
    if (bytes[4] != version ||
        bytes[5] != suiteToxEncryptSave ||
        bytes[6] != 0 ||
        bytes[7] != 0) {
      throw const ChatException(
        'unsupported_backup_version',
        'This backup was written by a newer DitMesh',
      );
    }
    if (passphrase.isEmpty) {
      throw const ChatException('wrong_passphrase', 'Passphrase required');
    }
    final Uint8List plain;
    try {
      plain = crypto.decrypt(
        Uint8List.sublistView(bytes, headerLength),
        passphrase,
      );
    } on ChatException {
      throw const ChatException(
        'wrong_passphrase',
        'Wrong passphrase, or the backup was altered',
      );
    }
    if (plain.length < headerLength) {
      throw const ChatException('invalid_backup', 'Backup is empty');
    }
    for (var i = 0; i < headerLength; i++) {
      if (plain[i] != bytes[i]) {
        throw const ChatException(
          'wrong_passphrase',
          'Backup header does not match its sealed copy',
        );
      }
    }
    return Uint8List.sublistView(plain, headerLength);
  }
}
