import 'dart:io';
import 'dart:typed_data';

import 'posix_permissions.dart';

int _nextStageId = 0;

/// Replaces a file only after a flushed, independent staging write completes.
/// A unique sibling keeps overlapping writers from sharing or deleting a stage.
/// The stage is created owner-only (0600) BEFORE any byte is written, and
/// the rename carries that mode to the target.
Future<void> writeBytesAtomic(File target, Uint8List bytes) async {
  await target.parent.create(recursive: true);
  final stage = File(
    '${target.path}.$pid.${DateTime.now().microsecondsSinceEpoch}.'
    '${_nextStageId++}.new',
  );
  try {
    await stage.create(exclusive: true);
    PosixPermissions.set(stage.path, PosixPermissions.privateFile);
    await stage.writeAsBytes(bytes, flush: true);
    await stage.rename(target.path);
  } catch (_) {
    if (await stage.exists()) await stage.delete();
    rethrow;
  }
}
