import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:morse_dsp/morse_dsp.dart';
import 'package:path/path.dart' as p;

/// A file the learner picked. Pickers give a file path when there is one;
/// content providers without a path (Android documents, iCloud) give a
/// byte stream ([read]), which is copied without loading it whole.
final class PickedRecording {
  const PickedRecording({
    required this.name,
    this.path,
    this.bytes,
    this.read,
    this.size,
  });

  final String name;
  final String? path;

  /// In-memory content (tests, tiny files).
  final Uint8List? bytes;
  final Stream<List<int>> Function()? read;

  /// Size in bytes when the picker reports it (checked before copying).
  final int? size;
}

/// Lets the learner choose a recording. Abstracted so tests never open a
/// native dialog. No microphone permission is involved.
abstract interface class RecordingPicker {
  Future<PickedRecording?> pick();
}

/// `file_picker`: any file type (the format is read from the WAV headers,
/// not the extension).
final class PlatformRecordingPicker implements RecordingPicker {
  const PlatformRecordingPicker({this.dialogTitle});

  final String? dialogTitle;

  @override
  Future<PickedRecording?> pick() async {
    final file = await FilePicker.pickFile(dialogTitle: dialogTitle);
    if (file == null) return null;
    final path = file.path;
    return PickedRecording(
      name: file.name,
      path: path,
      read: path == null ? file.readAsByteStream : null,
      size: await file.length(),
    );
  }
}

/// [ByteSource] over a [RandomAccessFile]: reads only the requested range,
/// never the whole recording. Reads are serialised (a RandomAccessFile has
/// one position).
final class FileByteSource implements ByteSource {
  FileByteSource._(this._file, this.length);

  static Future<FileByteSource> open(File file) async {
    final raf = await file.open();
    return FileByteSource._(raf, await raf.length());
  }

  final RandomAccessFile _file;
  Future<void> _tail = Future<void>.value();
  bool _closed = false;

  @override
  final int length;

  @override
  Future<Uint8List> read(int offset, int count) {
    final done = _tail.then((_) async {
      if (_closed) throw StateError('recording closed');
      final n = count.clamp(0, length - offset.clamp(0, length));
      await _file.setPosition(offset);
      return _file.read(n);
    });
    _tail = done.then<void>((_) {}, onError: (Object _) {});
    return done;
  }

  Future<void> close() async {
    await _tail;
    if (_closed) return;
    _closed = true;
    await _file.close();
  }
}

/// Recordings copied into managed storage in the learning profile's own
/// root, beside (not inside) the tree identity backups copy:
/// `<profile root>/media/recordings/`. Training documents travel in
/// identity backups; recordings deliberately do not (spec §11.3), only the
/// metadata that refers to them.
final class RecordingLibrary {
  RecordingLibrary(this.root);

  /// The profile root media paths resolve from: an identity's root (the
  /// parent of `IdentityService.dataDirectory()`, which is the backed-up
  /// tree), or the guest directory (`GuestStore.directory()`). Each profile
  /// has its own.
  final String root;

  static const String workingFile = 'media/recordings/current.wav';
  static final RegExp _safe = RegExp(
    r'^media/recordings/[A-Za-z0-9_\-]+(\.[A-Za-z0-9]+)?$',
  );

  /// The managed file for [relativePath]; throws [ArgumentError] for any
  /// path that is not a plain name under `media/recordings/` or that would
  /// resolve outside the profile.
  File fileFor(String relativePath) {
    if (!_safe.hasMatch(relativePath)) {
      throw ArgumentError.value(relativePath, 'relativePath', 'unsafe');
    }
    final resolved = p.normalize(
      p.joinAll(<String>[root, ...relativePath.split('/')]),
    );
    if (!p.isWithin(p.normalize(root), resolved)) {
      throw ArgumentError.value(relativePath, 'relativePath', 'outside');
    }
    return File(resolved);
  }

  /// Deletes recordings no entry refers to (left behind when an entry was
  /// deleted while its recording was open). Call only when no import or
  /// save is in flight.
  Future<void> pruneUnreferenced(Set<String> referenced) async {
    final dir = Directory(p.join(root, 'media', 'recordings'));
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final rel = 'media/recordings/${p.basename(entity.path)}';
      if (rel == workingFile || referenced.contains(rel)) continue;
      if (!_safe.hasMatch(rel)) continue;
      await entity.delete();
    }
  }

  /// Copies [picked] into [relativePath] (the working slot by default)
  /// after validating it, and opens it. Throws [WavFormatException] for
  /// anything unsupported; the previous file is replaced only on success,
  /// right after [beforeReplace] (close readers of the old file there).
  Future<WavPcmReader> importTo(
    PickedRecording picked, {
    String relativePath = workingFile,
    Future<void> Function()? beforeReplace,
  }) async {
    final declared = picked.size ?? picked.bytes?.length;
    if (declared != null && declared > WavPcmReader.maxBytes) {
      throw const WavFormatException(WavError.tooLarge);
    }
    final target = fileFor(relativePath);
    await target.parent.create(recursive: true);
    final staged = File('${target.path}.importing');
    try {
      final path = picked.path;
      if (path != null) {
        final source = File(path);
        if (await source.length() > WavPcmReader.maxBytes) {
          throw const WavFormatException(WavError.tooLarge);
        }
        await source.copy(staged.path);
      } else if (picked.read != null) {
        await _copyCapped(picked.read!(), staged);
      } else {
        await staged.writeAsBytes(picked.bytes ?? Uint8List(0), flush: true);
      }
      final probe = await FileByteSource.open(staged);
      try {
        await WavPcmReader.parse(probe);
      } finally {
        await probe.close();
      }
    } on Object {
      if (await staged.exists()) await staged.delete();
      rethrow;
    }
    await beforeReplace?.call();
    await staged.rename(target.path);
    return open(relativePath);
  }

  /// Streams into [target], refusing to write past the size limit.
  static Future<void> _copyCapped(Stream<List<int>> data, File target) async {
    final sink = target.openWrite();
    var written = 0;
    try {
      await for (final chunk in data) {
        written += chunk.length;
        if (written > WavPcmReader.maxBytes) {
          throw const WavFormatException(WavError.tooLarge);
        }
        sink.add(chunk);
      }
    } finally {
      await sink.close();
    }
  }

  /// Opens a managed recording; throws [FileSystemException] when missing.
  Future<WavPcmReader> open(String relativePath) async {
    final source = await FileByteSource.open(fileFor(relativePath));
    try {
      return await WavPcmReader.open(source);
    } on Object {
      await source.close();
      rethrow;
    }
  }

  /// Keeps the working recording under [relativePath] (for a saved audio
  /// material); copies so the working slot stays usable.
  Future<void> keepWorkingAs(String relativePath) async {
    final target = fileFor(relativePath);
    await target.parent.create(recursive: true);
    await fileFor(workingFile).copy(target.path);
  }

  Future<bool> exists(String relativePath) => fileFor(relativePath).exists();

  /// Saved recordings a backup would carry: the files named in
  /// [referenced] (see `BackupMedia.referenced`) that exist. Count and
  /// total bytes. Synchronous: a handful of files, read before a backup.
  (int, int) savedSizeSync(Set<String> referenced) {
    var count = 0;
    var bytes = 0;
    for (final name in referenced) {
      final f = File(p.join(root, 'media', 'recordings', name));
      if (!f.existsSync()) continue;
      count++;
      bytes += f.lengthSync();
    }
    return (count, bytes);
  }

  Future<void> delete(String relativePath) async {
    final f = fileFor(relativePath);
    if (await f.exists()) await f.delete();
  }
}

/// Closes the file behind [reader] when it came from [RecordingLibrary].
Future<void> closeReader(WavPcmReader? reader) async {
  final source = reader?.source;
  if (source is FileByteSource) await source.close();
}
