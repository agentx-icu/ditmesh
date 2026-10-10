import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'file_trainer_store.dart';
import 'training_controller.dart';
import 'training_doc_store.dart';
import 'training_settings_store.dart';

/// Whose learning data a training controller works on (functional spec
/// §8.2): the local guest, or an identity by public key. Chat always needs
/// a real identity.
sealed class LearningProfile {
  const LearningProfile();

  String get key;
}

final class GuestProfile extends LearningProfile {
  const GuestProfile();

  static const String profileKey = 'guest';

  @override
  String get key => profileKey;
}

final class IdentityProfile extends LearningProfile {
  const IdentityProfile(this.publicKey);

  final String publicKey;

  @override
  String get key => publicKey;
}

/// Guest learning data, kept apart from every identity under
/// `<support>/ditmesh/guest/` (training files in its `training/`
/// sub-directory, like an identity's data directory). It never touches,
/// reads or decrypts an identity profile.
class GuestStore {
  GuestStore({Future<String> Function()? root}) : _root = root ?? _defaultRoot;

  static Future<String> _defaultRoot() async {
    final support = await getApplicationSupportDirectory();
    return p.join(support.path, 'ditmesh', 'guest');
  }

  final Future<String> Function() _root;

  /// The guest's data directory (the equivalent of an identity's).
  Future<String> directory() async {
    final dir = await _root();
    await Directory(dir).create(recursive: true);
    return dir;
  }

  Future<File> _marker() async => File(p.join(await directory(), 'active'));

  /// Whether the learner chose guest mode last time (kept across restarts).
  Future<bool> isActive() async => (await _marker()).exists();

  Future<void> setActive(bool active) async {
    final marker = await _marker();
    if (active) {
      await marker.writeAsString('1', flush: true);
    } else if (await marker.exists()) {
      await marker.delete();
    }
  }

  /// Whether the guest has any learning data worth migrating: progress,
  /// settings, plans, materials or details.
  Future<bool> hasProgress() async {
    final training = Directory(
      p.join(await directory(), FileTrainerStore.subdirectory),
    );
    if (!await training.exists()) return false;
    return training.list(recursive: true).any((e) => e is File);
  }

  /// Identifies this batch of guest data; a new batch (after clearing or
  /// migrating) gets a new one, so an earlier migration's completion
  /// record never hides new data.
  Future<String> generation() async {
    final file = File(p.join(await directory(), 'generation'));
    if (await file.exists()) {
      final value = (await file.readAsString()).trim();
      if (value.isNotEmpty) return value;
    }
    final value = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    await file.writeAsString(value, flush: true);
    return value;
  }

  /// The guest's training controller (file stores under [directory]).
  Future<TrainingController> openController() async {
    final dir = await directory();
    final controller = TrainingController(
      progressStore: FileTrainerStore.inDataDirectory(dir),
      settingsStore: FileTrainingSettingsStore.inDataDirectory(dir),
      profileKey: GuestProfile.profileKey,
      docs: FileTrainingDocStore.inDataDirectory(dir),
    );
    await controller.load();
    return controller;
  }

  /// Deletes the guest's learning data (the learner asked to clear it).
  Future<void> clear() async {
    final dir = await directory();
    final training = Directory(p.join(dir, FileTrainerStore.subdirectory));
    if (await training.exists()) await training.delete(recursive: true);
    final media = Directory(p.join(dir, 'media'));
    if (await media.exists()) await media.delete(recursive: true);
    final generation = File(p.join(dir, 'generation'));
    if (await generation.exists()) await generation.delete();
    // A journal describes data that no longer exists.
    final journal = File(p.join(dir, 'migration-journal.json'));
    if (await journal.exists()) await journal.delete();
    await _deleteMatching(dir, 'pending-');
  }

  static Future<void> _deleteMatching(String dir, String prefix) async {
    await for (final e in Directory(dir).list()) {
      if (e is File && p.basename(e.path).startsWith(prefix)) await e.delete();
    }
  }

  /// A migration that recorded completion but crashed before its cleanup:
  /// finish the cleanup before the guest profile is used again, so new
  /// guest practice starts a new batch and is never removed by a later
  /// recovery of the old one.
  Future<void> finishCompletedMigrations() async {
    final dir = await directory();
    final genFile = File(p.join(dir, 'generation'));
    if (!await genFile.exists()) return;
    final gen = (await genFile.readAsString()).trim();
    var done = false;
    await for (final e in Directory(dir).list()) {
      final name = p.basename(e.path);
      if (e is File &&
          name.startsWith('migrated-') &&
          name.endsWith('-$gen.json')) {
        done = true;
      }
    }
    if (done) await clear();
  }
}

/// What a migration did.
enum MigrationOutcome {
  /// Data moved; or nothing to move.
  done,

  /// This identity already received the guest data (idempotent retry).
  alreadyDone,
}

/// Moves (or, for a restored identity, explicitly replaces) training data
/// from the guest to an identity as one recoverable transaction:
/// stage a copy → validate it → move any existing target aside → commit by
/// rename → record completion → remove the guest copy. A failure before
/// the commit leaves the guest data untouched and usable; retrying never
/// duplicates anything because the files are copied, not credited again.
final class GuestMigration {
  GuestMigration({
    required this.guestDirectory,
    required this.identityDirectory,
    required this.generation,
  });

  final String guestDirectory;
  final String identityDirectory;

  /// The guest data batch being moved ([GuestStore.generation]).
  final String generation;

  String get _source => p.join(guestDirectory, FileTrainerStore.subdirectory);
  String get _target =>
      p.join(identityDirectory, FileTrainerStore.subdirectory);
  String get _staging => '$_target.guest-staging';

  /// Saved recordings (workbench audio materials) move with the data that
  /// refers to them; the working recording does not.
  String get _mediaSource => p.join(guestDirectory, 'media', 'recordings');

  /// The identity root, beside its backed-up data directory (recordings
  /// are not in identity backups).
  String get _mediaTarget =>
      p.join(p.dirname(identityDirectory), 'media', 'recordings');
  String get _mediaStaging => '$_mediaTarget.guest-staging';
  static const String _workingRecording = 'current.wav';
  File get _journal => File(p.join(guestDirectory, 'migration-journal.json'));
  File _doneMarker(String key) => File(
    p.join(guestDirectory, 'migrated-${key.toLowerCase()}-$generation.json'),
  );

  /// Whether an interrupted migration must be finished (startup check).
  static Future<bool> hasJournal(String guestDirectory) =>
      File(p.join(guestDirectory, 'migration-journal.json')).exists();

  Future<MigrationOutcome> run({
    required String identityKey,
    required DateTime now,
  }) async {
    final marker = _doneMarker(identityKey);
    final source = Directory(_source);
    final staging = Directory(_staging);
    if (await marker.exists()) {
      // Moved before; finish any cleanup a crash interrupted.
      await _complete(marker, source, now);
      return MigrationOutcome.alreadyDone;
    }

    // Resume a migration interrupted after its commit: the staged copy was
    // renamed onto the target, only the bookkeeping is missing. Never redo
    // the copy (that would replace newer identity activity).
    if (await _journal.exists()) {
      final journal = jsonDecode(await _journal.readAsString());
      if (journal is Map &&
          journal['state'] == 'committing' &&
          journal['key'] == identityKey &&
          journal['generation'] == generation &&
          !await staging.exists() &&
          await Directory(_target).exists()) {
        await _commitMedia();
        await _complete(marker, source, now);
        return MigrationOutcome.done;
      }
      await _journal.delete();
    }
    if (!await source.exists()) return MigrationOutcome.done;

    // 1. Stage a copy (a leftover staging dir from a crash is redone).
    if (await staging.exists()) await staging.delete(recursive: true);
    await _copy(source, staging);

    await _stageMedia();

    // 2. Validate: the staged progress must load.
    final progress = File(p.join(_staging, FileTrainerStore.fileName));
    if (await progress.exists()) {
      final loaded = await FileTrainerStore(progress).load();
      if (loaded == null) {
        throw const FormatException('staged guest progress is unreadable');
      }
    }

    // 3. Journal the commit, move an existing target aside (never deleted
    // here), 4. commit by rename.
    await _journal.writeAsString(
      jsonEncode(<String, Object?>{
        'state': 'committing',
        'key': identityKey,
        'generation': generation,
      }),
      flush: true,
    );
    final target = Directory(_target);
    if (await target.exists()) {
      await target.rename(
        '$_target.before-guest-${now.millisecondsSinceEpoch}',
      );
    }
    await staging.rename(_target);
    await _commitMedia();
    await _complete(marker, source, now);
    return MigrationOutcome.done;
  }

  /// Copies the guest's saved recordings into a staging folder under names
  /// that are free next to the identity's own recordings. A colliding name
  /// gets a new one, and the staged audio-material references are rewritten
  /// to match before anything is committed — an identity recording is never
  /// replaced, and no guest recording is dropped.
  Future<void> _stageMedia() async {
    final mediaStaging = Directory(_mediaStaging);
    if (await mediaStaging.exists()) await mediaStaging.delete(recursive: true);
    final media = Directory(_mediaSource);
    if (!await media.exists()) return;
    await mediaStaging.create(recursive: true);
    final taken = <String>{};
    final target = Directory(_mediaTarget);
    if (await target.exists()) {
      await for (final e in target.list()) {
        taken.add(p.basename(e.path));
      }
    }
    final renames = <String, String>{};
    await for (final entity in media.list()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name == _workingRecording) continue;
      var dest = name;
      if (taken.contains(dest)) {
        final ext = p.extension(name);
        final stem = p.basenameWithoutExtension(name);
        var n = 0;
        do {
          dest = '${stem}_g$generation${n == 0 ? '' : '_$n'}$ext';
          n++;
        } while (taken.contains(dest));
        renames[name] = dest;
      }
      taken.add(dest);
      await entity.copy(p.join(mediaStaging.path, dest));
    }
    if (renames.isNotEmpty) await _remapReferences(_staging, renames);
  }

  /// Rewrites `media/recordings/<old>` references in the audio materials
  /// document (and its backup copy) of the training directory [training].
  static Future<void> _remapReferences(
    String training,
    Map<String, String> renames,
  ) async {
    for (final name in const [
      'audio_materials.json',
      'audio_materials.json.bak',
    ]) {
      final file = File(p.join(training, 'docs', name));
      if (!await file.exists()) continue;
      final Object? json;
      try {
        json = jsonDecode(await file.readAsString());
      } on FormatException {
        continue;
      }
      final list = json is Map ? json['materials'] : null;
      if (list is! List) continue;
      for (final m in list) {
        if (m is! Map) continue;
        final ref = m['file'];
        if (ref is! String) continue;
        final old = p.posix.basename(ref);
        final now = renames[old];
        if (now != null) m['file'] = 'media/recordings/$now';
      }
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(json),
        flush: true,
      );
    }
  }

  /// Moves staged recordings next to the identity's own. Names were made
  /// unique while staging; should one have appeared since, the recording
  /// takes another free name and the committed references follow it — an
  /// identity recording is never replaced.
  Future<void> _commitMedia() async {
    final staged = Directory(_mediaStaging);
    if (!await staged.exists()) return;
    final target = Directory(_mediaTarget);
    await target.create(recursive: true);
    final renames = <String, String>{};
    await for (final entity in staged.list()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      var dest = File(p.join(target.path, name));
      var n = 1;
      while (await dest.exists()) {
        final next =
            '${p.basenameWithoutExtension(name)}_g${generation}_m$n'
            '${p.extension(name)}';
        dest = File(p.join(target.path, next));
        renames[name] = next;
        n++;
      }
      await entity.rename(dest.path);
    }
    if (renames.isNotEmpty) await _remapReferences(_target, renames);
    await staged.delete(recursive: true);
  }

  /// 5. Record completion before removing the guest copy, so a retry after
  /// a failed removal is a no-op rather than a second copy.
  Future<void> _complete(File marker, Directory source, DateTime now) async {
    if (!await marker.exists()) {
      await marker.writeAsString(
        jsonEncode(<String, Object?>{'at': now.toIso8601String()}),
        flush: true,
      );
    }
    if (await source.exists()) await source.delete(recursive: true);
    final guestMedia = Directory(p.join(guestDirectory, 'media'));
    if (await guestMedia.exists()) await guestMedia.delete(recursive: true);
    final gen = File(p.join(guestDirectory, 'generation'));
    if (await gen.exists()) await gen.delete();
    if (await _journal.exists()) await _journal.delete();
  }

  static Future<void> _copy(Directory from, Directory to) async {
    await to.create(recursive: true);
    await for (final entity in from.list(recursive: false)) {
      final name = p.basename(entity.path);
      if (entity is Directory) {
        await _copy(entity, Directory(p.join(to.path, name)));
      } else if (entity is File) {
        await entity.copy(p.join(to.path, name));
      }
    }
  }
}
