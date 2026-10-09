import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';

import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/util/atomic_file.dart';
import 'package:ditmesh_chat/src/util/posix_fsync.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ffi/ffi.dart' as pkgffi;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tim2tox_dart/ffi/tim2tox_ffi.dart';

/// L10 (native buffers wiped) and L11 (directory flush after a rename).

/// Records, at every free, whether the whole allocation was zero.
class _RecordingAllocator implements ffi.Allocator {
  final Map<int, int> _sizes = {};
  final List<bool> zeroAtFree = [];

  @override
  ffi.Pointer<T> allocate<T extends ffi.NativeType>(
    int byteCount, {
    int? alignment,
  }) {
    final ptr = pkgffi.malloc.allocate<T>(byteCount, alignment: alignment);
    _sizes[ptr.address] = byteCount;
    return ptr;
  }

  @override
  void free(ffi.Pointer<ffi.NativeType> pointer) {
    final size = _sizes.remove(pointer.address)!;
    final bytes = pointer.cast<ffi.Uint8>().asTypedList(size);
    zeroAtFree.add(bytes.every((b) => b == 0));
    pkgffi.malloc.free(pointer);
  }
}

/// Echo "crypto": encrypt prefixes 80 bytes of 0xEE, decrypt strips them;
/// [fail] makes both report a native error after writing the output.
class _EchoFfi extends Tim2ToxFfi {
  _EchoFfi() : super.forTesting();
  bool fail = false;

  @override
  int Function(ffi.Pointer<ffi.Uint8>, int) get isDataEncryptedNative =>
      (ptr, len) => ptr.asTypedList(len).first == 0xEE ? 1 : 0;

  @override
  int Function(
    ffi.Pointer<ffi.Uint8>,
    int,
    ffi.Pointer<ffi.Uint8>,
    int,
    ffi.Pointer<ffi.Uint8>,
    int,
  )
  get passEncryptNative => (inp, inLen, pw, pwLen, out, outLen) {
    final o = out.asTypedList(outLen);
    o.fillRange(0, 80, 0xEE);
    o.setAll(80, inp.asTypedList(inLen));
    return fail ? -1 : outLen;
  };

  @override
  int Function(
    ffi.Pointer<ffi.Uint8>,
    int,
    ffi.Pointer<ffi.Uint8>,
    int,
    ffi.Pointer<ffi.Uint8>,
    int,
  )
  get passDecryptNative => (inp, inLen, pw, pwLen, out, outLen) {
    out.asTypedList(outLen).setAll(0, inp.asTypedList(inLen).sublist(80));
    return fail ? -1 : outLen;
  };

  @override
  int Function(
    ffi.Pointer<ffi.Uint8>,
    int,
    ffi.Pointer<ffi.Uint8>,
    int,
    ffi.Pointer<ffi.Int8>,
    int,
  )
  get extractToxIdFromProfileNative => (prof, len, pw, pwLen, buf, cap) {
    final id = '11' * 32;
    buf.cast<ffi.Uint8>().asTypedList(id.length).setAll(0, id.codeUnits);
    return fail ? 0 : id.length;
  };
}

void main() {
  group('L10 profile crypto wipes native buffers', () {
    late _RecordingAllocator allocator;
    late _EchoFfi native;
    late Tim2ToxProfileCrypto crypto;
    final secret = Uint8List.fromList(List.generate(200, (i) => i % 250 + 1));

    setUp(() {
      allocator = _RecordingAllocator();
      native = _EchoFfi();
      crypto = Tim2ToxProfileCrypto(ffi: native, allocator: allocator);
    });

    test('encrypt / decrypt / isEncrypted / extractPublicKey', () {
      final sealed = crypto.encrypt(secret, 'pw');
      expect(sealed.length, secret.length + 80);
      final opened = crypto.decrypt(sealed, 'pw');
      expect(opened, secret, reason: 'returned copies stay intact');
      expect(crypto.isEncrypted(sealed), isTrue);
      expect(crypto.isEncrypted(secret), isFalse);
      expect(crypto.extractPublicKey(secret), '11' * 32);
      expect(allocator.zeroAtFree, isNotEmpty);
      expect(allocator.zeroAtFree, everyElement(isTrue));
    });

    test('failing native calls wipe too', () {
      native.fail = true;
      expect(() => crypto.encrypt(secret, 'pw'), throwsA(isA<ChatException>()));
      expect(
        () => crypto.decrypt(Uint8List(300)..fillRange(0, 300, 7), 'pw'),
        throwsA(isA<ChatException>()),
      );
      expect(
        () => crypto.extractPublicKey(secret),
        throwsA(isA<ChatException>()),
      );
      expect(allocator.zeroAtFree, hasLength(8));
      expect(allocator.zeroAtFree, everyElement(isTrue));
    });
  });

  group('L11 directory flush', () {
    late Directory dir;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('ditmesh_fsync_');
    });
    tearDown(() async {
      directorySync = PosixDirectorySync.sync;
      await dir.delete(recursive: true);
    });

    test('flushes a directory on POSIX, no-op on Windows', () {
      expect(PosixDirectorySync.supported, !Platform.isWindows);
      expect(PosixDirectorySync.sync(dir.path), !Platform.isWindows);
      expect(PosixDirectorySync.sync(p.join(dir.path, 'missing')), isFalse);
    });

    test('writeBytesAtomic flushes the parent after the rename', () async {
      final target = File(p.join(dir.path, 'a', 'state.bin'));
      final flushed = <String>[];
      directorySync = (path) {
        // The rename has already committed when the flush runs.
        expect(target.readAsBytesSync(), [1, 2, 3]);
        flushed.add(path);
        return true;
      };
      await writeBytesAtomic(target, Uint8List.fromList([1, 2, 3]));
      expect(flushed, [target.parent.path]);
    });

    test('a failing flush leaves the committed write in place', () async {
      final target = File(p.join(dir.path, 'state.bin'));
      directorySync = (_) => throw const FileSystemException('EIO');
      await writeBytesAtomic(target, Uint8List.fromList([9]));
      expect(target.readAsBytesSync(), [9]);
      directorySync = (_) => false;
      await writeBytesAtomic(target, Uint8List.fromList([8]));
      expect(target.readAsBytesSync(), [8]);
      expect(
        dir.listSync().whereType<File>().map((f) => p.basename(f.path)),
        ['state.bin'],
        reason: 'no staging file left behind',
      );
    });
  });
}
