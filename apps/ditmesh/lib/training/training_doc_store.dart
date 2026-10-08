import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'atomic_json_file.dart';

/// Named JSON documents beside the training progress: simulator drafts,
/// materials, rhythm details. Each lives under the learning profile's
/// `training/` directory so identity backups already include it.
abstract interface class TrainingDocStore {
  Future<Map<String, Object?>?> read(String name);

  Future<void> write(String name, Map<String, Object?> json);

  Future<void> delete(String name);

  /// Every stored document name (for cache trimming).
  Future<List<String>> names();
}

/// `<dataDirectory>/training/docs/<name>.json`, written atomically with a
/// `.bak` fallback ([AtomicJsonFile]).
final class FileTrainingDocStore implements TrainingDocStore {
  FileTrainingDocStore(this.directory);

  factory FileTrainingDocStore.inDataDirectory(String dataDirectory) =>
      FileTrainingDocStore(
        Directory(p.join(dataDirectory, 'training', subdirectory)),
      );

  static const String subdirectory = 'docs';
  static final RegExp _safe = RegExp(r'^[a-z0-9_\-.]{1,120}$');

  final Directory directory;

  AtomicJsonFile _file(String name) {
    if (!_safe.hasMatch(name) || name.contains('..')) {
      throw ArgumentError.value(name, 'name', 'not a safe document name');
    }
    return AtomicJsonFile(File(p.join(directory.path, '$name.json')));
  }

  @override
  Future<Map<String, Object?>?> read(String name) => _file(name).read();

  @override
  Future<void> write(String name, Map<String, Object?> json) async {
    await directory.create(recursive: true);
    await _file(name).write(json);
  }

  @override
  Future<void> delete(String name) => _file(name).delete();

  @override
  Future<List<String>> names() async {
    if (!await directory.exists()) return const <String>[];
    final out = <String>[];
    await for (final entity in directory.list()) {
      final base = p.basename(entity.path);
      if (entity is File && base.endsWith('.json')) {
        out.add(base.substring(0, base.length - 5));
      }
    }
    out.sort();
    return out;
  }
}

/// Keeps documents as JSON strings so tests exercise (de)serialisation.
final class InMemoryTrainingDocStore implements TrainingDocStore {
  final Map<String, String> docs = <String, String>{};

  @override
  Future<Map<String, Object?>?> read(String name) async {
    final raw = docs[name];
    return raw == null ? null : jsonDecode(raw) as Map<String, Object?>;
  }

  @override
  Future<void> write(String name, Map<String, Object?> json) async {
    docs[name] = jsonEncode(json);
  }

  @override
  Future<void> delete(String name) async {
    docs.remove(name);
  }

  @override
  Future<List<String>> names() async => docs.keys.toList()..sort();
}
