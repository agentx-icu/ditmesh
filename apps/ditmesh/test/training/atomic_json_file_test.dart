import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/training/atomic_json_file.dart';

void main() {
  late Directory directory;
  late File file;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ditmesh_atomic_');
    file = File('${directory.path}/document.json');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test(
    'overlapping writes keep invocation order across file instances',
    () async {
      final writes = <Future<void>>[
        for (var value = 0; value < 20; value++)
          AtomicJsonFile(file).write(<String, Object?>{'value': value}),
      ];

      await Future.wait(writes);

      expect(await AtomicJsonFile(file).read(), <String, Object?>{'value': 19});
      expect(
        await AtomicJsonFile(File('${file.path}.bak')).read(),
        <String, Object?>{'value': 18},
      );
    },
  );

  test('delete queued after a write cannot resurrect its document', () async {
    await AtomicJsonFile(file).write(<String, Object?>{'value': 1});
    final save = AtomicJsonFile(file).write(<String, Object?>{'value': 2});
    final clear = AtomicJsonFile(file).delete();

    await Future.wait(<Future<void>>[save, clear]);

    expect(await AtomicJsonFile(file).read(), isNull);
    expect(await File('${file.path}.tmp').exists(), isFalse);
    expect(await File('${file.path}.bak').exists(), isFalse);
  });

  test('a read after an unawaited save sees the committed document', () async {
    final store = AtomicJsonFile(file);
    final write = store.write(<String, Object?>{'value': 4});
    final read = AtomicJsonFile(file).read();

    final loaded = await read;
    await write;
    expect(loaded, <String, Object?>{'value': 4});
  });

  test('a failed write does not prevent later writes', () async {
    final blocker = File('${directory.path}/blocked');
    await blocker.writeAsString('not a directory');
    final store = AtomicJsonFile(File('${blocker.path}/document.json'));
    await expectLater(
      store.write(<String, Object?>{'value': 1}),
      throwsA(isA<FileSystemException>()),
    );
    await blocker.delete();

    await store.write(<String, Object?>{'value': 2});

    expect(await store.read(), <String, Object?>{'value': 2});
  });
}
