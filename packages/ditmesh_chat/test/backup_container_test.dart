import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

Uint8List _b(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  test('round-trips entries, order and the encrypted flag', () {
    final original = BackupContainer(
      entries: {
        BackupContainer.identityEntry: _b('{"toxId":"AB"}'),
        BackupContainer.profileEntry: Uint8List.fromList([0, 1, 2, 255]),
        'training/progress.json': _b('{"wpm":18}'),
        'training/nested/deep.bin': Uint8List(0),
      },
      profileEncrypted: true,
    );
    final decoded = BackupContainer.decode(original.encode());
    expect(decoded.profileEncrypted, isTrue);
    expect(decoded.entries.keys.toList(), original.entries.keys.toList());
    expect(decoded.profile, [0, 1, 2, 255]);
    expect(utf8.decode(decoded.identity!), '{"toxId":"AB"}');
    expect(decoded.trainingFiles.map((e) => e.key), [
      'training/progress.json',
      'training/nested/deep.bin',
    ]);
  });

  test('rejects foreign bytes and truncated archives', () {
    expect(
      () => BackupContainer.decode(_b('PK\x03\x04 definitely a zip')),
      throwsA(
        isA<ChatException>().having((e) => e.code, 'code', 'invalid_backup'),
      ),
    );
    final good = BackupContainer(
      entries: {BackupContainer.profileEntry: Uint8List(40)},
      profileEncrypted: false,
    ).encode();
    expect(
      () => BackupContainer.decode(
        Uint8List.sublistView(good, 0, good.length - 5),
      ),
      throwsA(isA<ChatException>()),
    );
  });

  test('a crafted entry size or path is invalid_backup, not a crash', () {
    Matcher invalidBackup() => throwsA(
      isA<ChatException>().having((e) => e.code, 'code', 'invalid_backup'),
    );
    // Header: magic, version 1, flags 0, one entry.
    Uint8List archive({required List<int> path, required int size}) {
      final good = BackupContainer(
        entries: {'x': Uint8List(0)},
        profileEncrypted: false,
      ).encode();
      final out = BytesBuilder()
        ..add(good.sublist(0, 10))
        ..add([0, path.length])
        ..add(path);
      final sizeBytes = ByteData(8)..setUint64(0, size, Endian.big);
      out
        ..add(sizeBytes.buffer.asUint8List())
        ..add(List<int>.filled(16, 0));
      return out.toBytes();
    }

    // 2^63 - 1: `offset + size` would overflow past the bounds check.
    expect(
      () => BackupContainer.decode(
        archive(path: utf8.encode('profile'), size: 0x7fffffffffffffff),
      ),
      invalidBackup(),
    );
    // Malformed UTF-8 in the entry path.
    expect(
      () => BackupContainer.decode(archive(path: [0xff, 0xfe], size: 0)),
      invalidBackup(),
    );
  });

  test('rejects entry paths that could escape the identity root', () {
    for (final bad in [
      '../x',
      '/abs',
      'a/../b',
      r'a\b',
      '',
      'a//b',
      'C:/escape',
      'training/C:escape',
    ]) {
      expect(BackupContainer.isSafeArchivePath(bad), isFalse, reason: bad);
    }
    expect(BackupContainer.isSafeArchivePath('training/a/b.json'), isTrue);
  });

  test('refuses a newer container version', () {
    final bytes = BackupContainer(
      entries: {BackupContainer.profileEntry: Uint8List(1)},
      profileEncrypted: false,
    ).encode();
    bytes[4] = 9;
    expect(
      () => BackupContainer.decode(bytes),
      throwsA(
        isA<ChatException>().having(
          (e) => e.code,
          'code',
          'unsupported_backup_version',
        ),
      ),
    );
  });
}
