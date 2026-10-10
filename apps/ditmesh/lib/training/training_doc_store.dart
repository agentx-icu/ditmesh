import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'atomic_json_file.dart';

/// Named JSON documents beside the training progress: group practice
/// sessions and audio materials. Each lives under the learning profile's
/// `training/` directory so identity backups already include it.
abstract interface class TrainingDocStore {
  Future<Map<String, Object?>?> read(String name);

  Future<void> write(String name, Map<String, Object?> json);
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
}
