@TestOn('mac-os || linux')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/util/atomic_file.dart';
import 'package:path/path.dart' as p;

int _mode(String path) => FileStat.statSync(path).mode & 0x1FF;

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('ditmesh_perms_');
  });

  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  test('identity directories are owner-only', () async {
    final paths = IdentityPaths(p.join(temp.path, 'ditmesh', 'identity'));
    await paths.ensureDirectories();
    expect(_mode(paths.root), 0x1C0); // 0700
    expect(_mode(p.dirname(paths.root)), 0x1C0);
  });

  test('atomically written secrets are 0600', () async {
    final target = File(p.join(temp.path, 'tox_profile.tox'));
    await writeBytesAtomic(target, Uint8List.fromList([1, 2, 3]));
    expect(_mode(target.path), 0x180); // 0600
  });
}
