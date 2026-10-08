import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as pkgffi;
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:tim2tox_dart/ffi/tim2tox_ffi.dart';

/// Tox's `TOX_PASS_ENCRYPTION_EXTRA_LENGTH` (`toxencryptsave.h`): the fixed
/// overhead a passphrase-encrypted savedata carries.
const int toxPassEncryptionExtraLength = 80;

/// Tox savedata encryption (`tox_pass_encrypt` / `tox_pass_decrypt`) and the
/// public-key extractor, behind an interface so the identity state machine
/// can be tested without the native library.
abstract interface class ProfileCrypto {
  /// True iff [data] starts with the Tox encrypted-save magic.
  bool isEncrypted(Uint8List data);

  /// Passphrase-encrypts plaintext savedata. Throws [ChatException]
  /// `crypto_failed` on a native error.
  Uint8List encrypt(Uint8List plaintext, String password);

  /// Decrypts. Throws [ChatException] `wrong_password` when the passphrase
  /// does not open the blob (Tox does not distinguish "wrong password" from
  /// "corrupt", and neither can we).
  Uint8List decrypt(Uint8List ciphertext, String password);

  /// 64-hex public key of a PLAINTEXT savedata blob. Throws [ChatException]
  /// `invalid_profile` when the bytes are not a Tox savedata.
  String extractPublicKey(Uint8List plaintext);
}

/// [ProfileCrypto] over `libtim2tox_ffi`. Ported from toxee's
/// `lib/util/account_export/encryption.dart` + `tox_file_io.dart`.
///
/// Buffer ownership: every returned `Uint8List` is a Dart copy made before
/// the native buffer is freed (an `asTypedList` view over freed memory was a
/// real toxee bug). The passphrase buffer is zeroed before release.
class Tim2ToxProfileCrypto implements ProfileCrypto {
  Tim2ToxProfileCrypto({Tim2ToxFfi? ffi}) : _ffiOverride = ffi;

  final Tim2ToxFfi? _ffiOverride;
  Tim2ToxFfi get _ffi => _ffiOverride ?? Tim2ToxFfi.open();

  @override
  bool isEncrypted(Uint8List data) {
    if (data.length < toxPassEncryptionExtraLength) return false;
    final ptr = pkgffi.malloc<ffi.Uint8>(toxPassEncryptionExtraLength);
    try {
      ptr
          .asTypedList(toxPassEncryptionExtraLength)
          .setAll(0, data.sublist(0, toxPassEncryptionExtraLength));
      return _ffi.isDataEncryptedNative(ptr, toxPassEncryptionExtraLength) == 1;
    } finally {
      pkgffi.malloc.free(ptr);
    }
  }

  @override
  Uint8List encrypt(Uint8List plaintext, String password) {
    final outLen = plaintext.length + toxPassEncryptionExtraLength;
    return _withBuffers(plaintext, password, outLen, (inPtr, pwPtr, pwLen,
        outPtr) {
      final n = _ffi.passEncryptNative(
        inPtr,
        plaintext.length,
        pwPtr,
        pwLen,
        outPtr,
        outLen,
      );
      if (n < 0) {
        throw const ChatException('crypto_failed', 'Profile encryption failed');
      }
      return n;
    });
  }

  @override
  Uint8List decrypt(Uint8List ciphertext, String password) {
    if (ciphertext.length <= toxPassEncryptionExtraLength) {
      throw const ChatException('wrong_password', 'Profile cannot be opened');
    }
    final outLen = ciphertext.length - toxPassEncryptionExtraLength;
    return _withBuffers(ciphertext, password, outLen, (inPtr, pwPtr, pwLen,
        outPtr) {
      final n = _ffi.passDecryptNative(
        inPtr,
        ciphertext.length,
        pwPtr,
        pwLen,
        outPtr,
        outLen,
      );
      if (n < 0) {
        throw const ChatException(
          'wrong_password',
          'Incorrect password or corrupted profile',
        );
      }
      return n;
    });
  }

  @override
  String extractPublicKey(Uint8List plaintext) {
    final profilePtr = pkgffi.malloc<ffi.Uint8>(plaintext.length);
    final idBuf = pkgffi.malloc<ffi.Int8>(128);
    try {
      profilePtr.asTypedList(plaintext.length).setAll(0, plaintext);
      final n = _ffi.extractToxIdFromProfileNative(
        profilePtr,
        plaintext.length,
        ffi.Pointer<ffi.Uint8>.fromAddress(0),
        0,
        idBuf,
        128,
      );
      if (n <= 0) {
        throw const ChatException(
          'invalid_profile',
          'Not a Tox profile (public key unreadable)',
        );
      }
      return idBuf.cast<pkgffi.Utf8>().toDartString(length: n).toUpperCase();
    } finally {
      pkgffi.malloc.free(profilePtr);
      pkgffi.malloc.free(idBuf);
    }
  }

  /// Allocates input / passphrase / output buffers, runs [body] (which returns
  /// the number of output bytes written), and copies the output out before
  /// freeing everything. The passphrase buffer is wiped first.
  Uint8List _withBuffers(
    Uint8List input,
    String password,
    int outLen,
    int Function(
      ffi.Pointer<ffi.Uint8> input,
      ffi.Pointer<ffi.Uint8> pw,
      int pwLen,
      ffi.Pointer<ffi.Uint8> out,
    ) body,
  ) {
    final pw = utf8.encode(password);
    final inPtr = pkgffi.malloc<ffi.Uint8>(input.length);
    final pwPtr = pkgffi.malloc<ffi.Uint8>(pw.isEmpty ? 1 : pw.length);
    final outPtr = pkgffi.malloc<ffi.Uint8>(outLen);
    try {
      inPtr.asTypedList(input.length).setAll(0, input);
      if (pw.isNotEmpty) pwPtr.asTypedList(pw.length).setAll(0, pw);
      final n = body(inPtr, pwPtr, pw.length, outPtr);
      return Uint8List.fromList(outPtr.asTypedList(n));
    } finally {
      if (pw.isNotEmpty) pwPtr.asTypedList(pw.length).fillRange(0, pw.length, 0);
      pkgffi.malloc.free(inPtr);
      pkgffi.malloc.free(pwPtr);
      pkgffi.malloc.free(outPtr);
    }
  }
}
