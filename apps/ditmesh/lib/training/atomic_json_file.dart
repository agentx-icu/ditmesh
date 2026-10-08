import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// A JSON document on disk that is written atomically and read defensively.
///
/// * [write] serialises to `<path>.tmp`, moves the previous document to
///   `<path>.bak` and renames the temp file into place, so a crash mid-write
///   never leaves a half-written primary file.
/// * [read] parses the primary file and falls back to `.bak` when it is
///   missing or unreadable. Corrupt primaries are set aside as `<path>.corrupt`.
///   [readDecoded] also validates the typed document before accepting it.
///   No usable document yields null so the caller can start fresh.
///
/// Every store in `lib/training/` is a thin typed wrapper over this class so
/// the crash-safety story is written (and tested) once.
final class AtomicJsonFile {
  AtomicJsonFile(this.file);

  final File file;

  // File objects and typed stores can be recreated while earlier operations
  // are still running. Serialize by path, rather than by store instance.
  static final Map<String, Future<void>> _operations = {};

  File get tempFile => File('${file.path}.tmp');
  File get backupFile => File('${file.path}.bak');
  File get corruptFile => File('${file.path}.corrupt');

  /// The decoded document, or null when nothing readable exists.
  Future<Map<String, Object?>?> read() => readDecoded((json) => json);

  /// Applies the typed codec before accepting a document, so an invalid
  /// document structure receives the same backup recovery as invalid JSON.
  Future<T?> readDecoded<T>(T Function(Map<String, Object?> json) decode) =>
      _serialize(() => _readDecoded(decode));

  Future<T?> _readDecoded<T>(
    T Function(Map<String, Object?> json) decode,
  ) async {
    final primary = await _tryRead(file, decode);
    if (primary != null) {
      return primary;
    }
    if (!await file.exists()) {
      // Nothing was ever written, or the last write died between the
      // "move to .bak" and "rename tmp" steps. The backup is then the latest
      // good document, so fall through and try it.
      return _tryRead(backupFile, decode);
    }
    // The primary exists but is unreadable: keep it for inspection and use
    // the backup.
    await _setAside();
    return _tryRead(backupFile, decode);
  }

  /// Persists [json]: temp file -> rotate valid previous into `.bak` -> rename.
  /// [validate] checks the previous document's schema before rotating it.
  Future<void> write(
    Map<String, Object?> json, {
    void Function(Map<String, Object?> json)? validate,
  }) {
    // Take the snapshot at invocation, before callers can update their map.
    final encoded = const JsonEncoder.withIndent('  ').convert(json);
    return _serialize(() => _write(encoded, validate));
  }

  Future<void> _write(
    String encoded,
    void Function(Map<String, Object?> json)? validate,
  ) async {
    await file.parent.create(recursive: true);
    final tmp = tempFile;
    await tmp.writeAsString(encoded, flush: true);
    if (await file.exists()) {
      final previous = await _tryRead(file, (json) {
        validate?.call(json);
        return json;
      });
      if (previous == null) {
        // Never rotate a corrupt primary over the last usable backup.
        await _setAside();
      } else {
        await file.rename(backupFile.path);
      }
    }
    await tmp.rename(file.path);
  }

  /// Removes the document and its companions.
  Future<void> delete() => _serialize(_delete);

  Future<void> _delete() async {
    for (final f in <File>[file, tempFile, backupFile, corruptFile]) {
      if (await f.exists()) {
        await f.delete();
      }
    }
  }

  Future<T?> _tryRead<T>(
    File f,
    T Function(Map<String, Object?> json) decode,
  ) async {
    if (!await f.exists()) {
      return null;
    }
    try {
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is! Map<String, Object?>) return null;
      try {
        return decode(decoded);
      } on Object {
        return null;
      }
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final path = p.normalize(file.absolute.path);
    final previous = _operations[path] ?? Future<void>.value();
    final result = previous.then((_) => operation());
    late final Future<void> settled;
    void release() {
      if (identical(_operations[path], settled)) _operations.remove(path);
    }

    // Keep the queue usable after a failed operation; the original result
    // still delivers the error to its caller.
    settled = result.then<void>(
      (_) => release(),
      onError: (Object error) {
        release();
      },
    );
    _operations[path] = settled;
    return result;
  }

  Future<void> _setAside() async {
    try {
      if (await corruptFile.exists()) {
        await corruptFile.delete();
      }
      await file.rename(corruptFile.path);
    } on FileSystemException {
      // Best effort: a read-only volume must not stop the fallback read.
    }
  }
}
