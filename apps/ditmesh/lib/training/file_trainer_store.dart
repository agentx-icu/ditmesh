import 'dart:io';

import 'package:morse_trainer/morse_trainer.dart';
import 'package:path/path.dart' as p;

import 'atomic_json_file.dart';

/// [TrainerStore] persisted as `<dataDirectory>/training/progress.json`.
///
/// Progress lives inside the identity's data directory (product decision:
/// training requires an identity), so switching or deleting an identity
/// switches or deletes its training progress with it. Writes are atomic and
/// a corrupt file falls back to the `.bak` of the previous save; see
/// [AtomicJsonFile].
final class FileTrainerStore implements TrainerStore {
  FileTrainerStore(this.file) : _json = AtomicJsonFile(file);

  /// The conventional location under an identity's data directory.
  factory FileTrainerStore.inDataDirectory(String dataDirectory) =>
      FileTrainerStore(File(p.join(dataDirectory, subdirectory, fileName)));

  static const String subdirectory = 'training';
  static const String fileName = 'progress.json';

  final File file;
  final AtomicJsonFile _json;

  @override
  Future<TrainerProgress?> load() => _json.readDecoded(_decode);

  static TrainerProgress _decode(Map<String, Object?> json) {
    final progress = TrainerProgress.fromJson(json);
    // Model constructors use assertions. Files must be validated in release
    // builds too, before invalid counters or SRS indexes reach the trainer.
    final invalid =
        progress.currentLesson < 1 ||
        progress.streakDays < 0 ||
        progress.dailyGoalChars < 0 ||
        progress.maxHistory <= 0 ||
        // Lifetime counters can never be below what the kept history shows.
        progress.lifetimeSessions < progress.history.length ||
        progress.lifetimeChars <
            progress.history.fold<int>(0, (sum, s) => sum + s.totalChars) ||
        progress.charStats.values.any(
          (s) => s.attempts < 0 || s.correct < 0 || s.correct > s.attempts,
        ) ||
        progress.history.any(
          (s) =>
              s.totalChars < 0 ||
              s.correctChars < 0 ||
              s.correctChars > s.totalChars ||
              (s.lesson != null && s.lesson! < 1) ||
              (s.elapsed?.isNegative ?? false),
        ) ||
        progress.srs.intervals.any((interval) => interval.isNegative) ||
        progress.srs.cards.values.any(
          (card) => card.box < 0 || card.box > progress.srs.maxBox,
        ) ||
        progress.confusion.targets.any(
          (target) => progress.confusion
              .rowFor(target)
              .values
              .any((count) => count < 0),
        );
    if (invalid) throw const FormatException('Invalid training progress');
    return progress;
  }

  @override
  Future<void> save(TrainerProgress progress) =>
      _json.write(progress.toJson(), validate: _decode);

  @override
  Future<void> clear() => _json.delete();
}
