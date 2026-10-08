import 'dart:convert';
import 'dart:io';

import 'package:ditmesh_chat/ditmesh_chat.dart';

/// Disk-backed preferences for the headless peer harness. A reopened backend
/// reads a new cache from disk rather than retaining the previous session.
class RealPeerStore implements KeyValueStore {
  RealPeerStore(this.file)
    : _data = file.existsSync()
          ? Map<String, Object>.from(jsonDecode(file.readAsStringSync()) as Map)
          : <String, Object>{};

  final File file;
  final Map<String, Object> _data;
  Future<void> _writes = Future<void>.value();

  Future<void> _save() {
    final snapshot = jsonEncode(_data);
    return _writes = _writes.then((_) async {
      await file.parent.create(recursive: true);
      final staging = File('${file.path}.tmp');
      await staging.writeAsString(snapshot, flush: true);
      await staging.rename(file.path);
    });
  }

  Future<void> flush() => _writes;

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  int? getInt(String key) => _data[key] as int?;

  @override
  List<String>? getStringList(String key) =>
      (_data[key] as List?)?.cast<String>().toList();

  @override
  Set<String> keys() => _data.keys.toSet();

  @override
  Future<void> setString(String key, String value) {
    _data[key] = value;
    return _save();
  }

  @override
  Future<void> setBool(String key, bool value) {
    _data[key] = value;
    return _save();
  }

  @override
  Future<void> setInt(String key, int value) {
    _data[key] = value;
    return _save();
  }

  @override
  Future<void> setStringList(String key, List<String> value) {
    _data[key] = List<String>.of(value);
    return _save();
  }

  @override
  Future<void> remove(String key) {
    _data.remove(key);
    return _save();
  }
}
