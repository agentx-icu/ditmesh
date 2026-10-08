import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'atomic_json_file.dart';
import 'training_settings.dart';

/// Persistence boundary for [TrainingSettings]; mirrors `TrainerStore`.
abstract interface class TrainingSettingsStore {
  /// Saved settings, or null when nothing has been saved yet.
  Future<TrainingSettings?> load();

  Future<void> save(TrainingSettings settings);

  Future<void> clear();
}

/// Settings as `<dataDirectory>/training/settings.json`, written atomically
/// with a `.bak` fallback (see [AtomicJsonFile]).
final class FileTrainingSettingsStore implements TrainingSettingsStore {
  FileTrainingSettingsStore(this.file) : _json = AtomicJsonFile(file);

  factory FileTrainingSettingsStore.inDataDirectory(String dataDirectory) =>
      FileTrainingSettingsStore(
        File(p.join(dataDirectory, subdirectory, fileName)),
      );

  static const String subdirectory = 'training';
  static const String fileName = 'settings.json';

  final File file;
  final AtomicJsonFile _json;

  @override
  Future<TrainingSettings?> load() => _json.readDecoded(_decode);

  static TrainingSettings _decode(Map<String, Object?> json) {
    final settings = TrainingSettings.fromJson(json);
    final trainer = settings.trainer;
    final parameters = <double?>[
      trainer.characterWpm,
      trainer.farnsworthWpm,
      trainer.toneHz,
    ];
    if (parameters.any((v) => v != null && (!v.isFinite || v <= 0)) ||
        trainer.sessionLengthChars <= 0 ||
        (trainer.sessionLengthSeconds != null &&
            trainer.sessionLengthSeconds! <= 0) ||
        trainer.groupSize <= 0) {
      throw const FormatException('Invalid training settings');
    }
    // Keep every value inside what the settings screen can set: a positive
    // but absurd speed (say 1e300 WPM) would round the dit to zero and break
    // playback and keying. Older builds also offered sessions down to 20
    // symbols, too short for a lesson session to ever unlock the next
    // lesson; those are lifted to the floor.
    final wpm = trainer.characterWpm.clamp(
      TrainingSettings.minCharacterWpm,
      TrainingSettings.maxCharacterWpm,
    );
    final farnsworth = trainer.farnsworthWpm?.clamp(
      TrainingSettings.minFarnsworthWpm,
      wpm,
    );
    final bounded = trainer.copyWith(
      characterWpm: wpm,
      farnsworthWpm: farnsworth,
      toneHz: trainer.toneHz.clamp(
        TrainingSettings.minToneHz,
        TrainingSettings.maxToneHz,
      ),
      sessionLengthChars: trainer.sessionLengthChars.clamp(
        TrainingSettings.minSessionChars,
        TrainingSettings.maxSessionChars,
      ),
    );
    return bounded == trainer ? settings : settings.copyWith(trainer: bounded);
  }

  @override
  Future<void> save(TrainingSettings settings) =>
      _json.write(settings.toJson(), validate: _decode);

  @override
  Future<void> clear() => _json.delete();
}

/// Round-trips through JSON in memory so tests exercise the real codec.
final class InMemoryTrainingSettingsStore implements TrainingSettingsStore {
  InMemoryTrainingSettingsStore([TrainingSettings? initial])
    : _json = initial == null ? null : jsonEncode(initial.toJson());

  String? _json;
  int _saveCount = 0;

  int get saveCount => _saveCount;

  @override
  Future<TrainingSettings?> load() async {
    final json = _json;
    if (json == null) {
      return null;
    }
    return TrainingSettings.fromJson(jsonDecode(json) as Map<String, Object?>);
  }

  @override
  Future<void> save(TrainingSettings settings) async {
    _json = jsonEncode(settings.toJson());
    _saveCount++;
  }

  @override
  Future<void> clear() async {
    _json = null;
  }
}
