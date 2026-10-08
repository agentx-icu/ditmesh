import 'dart:convert';

import 'trainer_progress.dart';

/// Persistence boundary for [TrainerProgress].
///
/// The app provides a file / preferences backed implementation; this package
/// only ships [InMemoryTrainerStore] for tests and previews.
abstract interface class TrainerStore {
  /// Returns the saved progress, or null when nothing has been saved yet.
  Future<TrainerProgress?> load();

  Future<void> save(TrainerProgress progress);

  /// Forgets any saved progress.
  Future<void> clear();
}

/// Keeps progress as a JSON string in memory, so a round trip through the
/// store exercises the same (de)serialisation a real store would.
final class InMemoryTrainerStore implements TrainerStore {
  InMemoryTrainerStore([TrainerProgress? initial])
    : _json = initial == null ? null : jsonEncode(initial.toJson());

  String? _json;
  int _saveCount = 0;

  /// Number of [save] calls so far.
  int get saveCount => _saveCount;

  /// Raw stored JSON, for inspection.
  String? get storedJson => _json;

  @override
  Future<TrainerProgress?> load() async {
    final json = _json;
    if (json == null) {
      return null;
    }
    return TrainerProgress.fromJson(jsonDecode(json) as Map<String, Object?>);
  }

  @override
  Future<void> save(TrainerProgress progress) async {
    _json = jsonEncode(progress.toJson());
    _saveCount++;
  }

  @override
  Future<void> clear() async {
    _json = null;
  }
}
