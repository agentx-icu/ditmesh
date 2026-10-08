// ditmesh's own overlay on the vendored `tencent_cloud_chat_sdk` plugin,
// applied by tool/bootstrap_deps.dart after tim2tox's patch series. See
// third_party/overlays/tencent_cloud_chat_sdk/README.md for the why.
//
// The overlay directory mirrors the plugin: every file in it is copied over
// the same relative path in the vendored plugin, after the paths listed in
// its REMOVE.txt were deleted. `sha256` covers the overlay's file names and
// contents so the vendor state can record what was applied.
//
// No package imports: bootstrap runs BEFORE `dart pub get` (it writes the
// overrides pub needs), so only `dart:` libraries and the system hash tool
// are available. Hashing goes through [sha256FileSync] like the patch series.

import 'dart:convert';
import 'dart:io';

class VendorOverlay {
  VendorOverlay(this.dir);

  /// Overlay root (e.g. `third_party/overlays/tencent_cloud_chat_sdk`).
  final Directory dir;

  static const String removeListName = 'REMOVE.txt';
  static const Set<String> _metaFiles = {'README.md', removeListName};

  bool get exists => dir.existsSync();

  /// Relative paths (POSIX separators) of every overlay file to copy.
  List<String> get files {
    if (!exists) return const [];
    final root = dir.path;
    final out = <String>[];
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final rel = _relative(entity.path, root);
      if (_metaFiles.contains(rel)) continue;
      out.add(rel);
    }
    out.sort();
    return out;
  }

  /// Paths to delete in the vendored plugin before copying, from REMOVE.txt.
  List<String> get removals {
    final f = File('${dir.path}/$removeListName');
    if (!f.existsSync()) return const [];
    return [
      for (final line in f.readAsLinesSync())
        if (line.trim().isNotEmpty && !line.trimLeft().startsWith('#'))
          line.trim(),
    ];
  }

  /// Hash of the removal list plus every file's path and bytes (system
  /// SHA-256 over a concatenation written to a temp file).
  String get sha256 {
    final tmp = Directory.systemTemp.createTempSync('ditmesh_overlay_');
    try {
      final concat = File('${tmp.path}/overlay.bin');
      final sink = concat.openSync(mode: FileMode.write);
      sink.writeFromSync(utf8.encode('REMOVE\n${removals.join('\n')}\n'));
      for (final rel in files) {
        sink.writeFromSync(utf8.encode('FILE $rel\n'));
        sink.writeFromSync(File('${dir.path}/$rel').readAsBytesSync());
        sink.writeFromSync(const [0]);
      }
      sink.closeSync();
      return sha256FileSync(concat.path);
    } finally {
      tmp.deleteSync(recursive: true);
    }
  }

  /// Applies the overlay to [target] when [force] is set, the recorded
  /// `overlay_sha256` in [state] differs from the current one, or the tree
  /// does not match the overlay any more; records the new hash in [state].
  /// Returns whether it was applied. A missing overlay is a hard error: it
  /// is what keeps Tencent's native SDK out of the bundles.
  bool applyIfNeeded(Directory target, Map<String, dynamic> state,
      {required bool force}) {
    if (!exists) {
      stderr.writeln('bootstrap_deps: overlay ${dir.path} is missing');
      exit(1);
    }
    final current = sha256;
    if (!force &&
        state['overlay_sha256'] == current &&
        verifyApplied(target) == null) {
      return false;
    }
    stdout.writeln(
      'Applying ditmesh overlay (${files.length} file(s), '
      '${removals.length} removal(s))...',
    );
    apply(target);
    state['overlay_sha256'] = current;
    final problem = verifyApplied(target);
    if (problem != null) {
      stderr.writeln('bootstrap_deps: overlay did not apply cleanly: $problem');
      exit(1);
    }
    return true;
  }

  /// Checks the vendored tree against the overlay: every removed path is
  /// gone (a removed directory that the overlay repopulates may hold only
  /// overlay files) and every overlay file is present byte for byte. Returns
  /// null when it matches, else what is wrong (`--offline-check-only`).
  String? verifyApplied(Directory target) {
    if (!exists) return 'overlay directory ${dir.path} is missing';
    final overlayFiles = files;
    for (final rel in removals) {
      final path = '${target.path}/$rel';
      final type = FileSystemEntity.typeSync(path, followLinks: false);
      if (type == FileSystemEntityType.notFound) continue;
      final repopulated = overlayFiles.where((f) => f.startsWith('$rel/'));
      if (type != FileSystemEntityType.directory || repopulated.isEmpty) {
        return '$rel still present in the vendored plugin';
      }
      // Nothing but overlay files (and the directories leading to them)
      // may live in a repopulated directory: no stray file, link or dir.
      for (final entity
          in Directory(path).listSync(recursive: true, followLinks: false)) {
        final inner = _relative(entity.path, target.path);
        final ok = switch (entity) {
          File() => overlayFiles.contains(inner),
          Directory() => overlayFiles.any((f) => f.startsWith('$inner/')),
          _ => false,
        };
        if (!ok) return '$inner still present in the vendored plugin';
      }
    }
    for (final rel in overlayFiles) {
      final dest = File('${target.path}/$rel');
      if (!dest.existsSync()) return '$rel missing from the vendored plugin';
      final a = dest.readAsBytesSync();
      final b = File('${dir.path}/$rel').readAsBytesSync();
      if (a.length != b.length) return '$rel differs from the overlay';
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return '$rel differs from the overlay';
      }
    }
    return null;
  }

  /// Deletes [removals] under [target] and copies [files] into it.
  void apply(Directory target) {
    for (final rel in removals) {
      final path = '${target.path}/$rel';
      final type = FileSystemEntity.typeSync(path, followLinks: false);
      switch (type) {
        case FileSystemEntityType.directory:
          Directory(path).deleteSync(recursive: true);
        case FileSystemEntityType.file:
        case FileSystemEntityType.link:
          File(path).deleteSync();
        default:
          break; // already gone
      }
    }
    for (final rel in files) {
      final dest = File('${target.path}/$rel');
      dest.parent.createSync(recursive: true);
      File('${dir.path}/$rel').copySync(dest.path);
    }
  }

  /// [path] relative to [root] with POSIX separators. On Windows the roots
  /// are passed with forward slashes while `listSync` joins with `\\`, so
  /// both separators are normalised before the leading one is dropped.
  static String _relative(String path, String root) {
    final p = path.replaceAll('\\', '/');
    final r = root.replaceAll('\\', '/');
    var rel = p.startsWith(r) ? p.substring(r.length) : p;
    while (rel.startsWith('/')) {
      rel = rel.substring(1);
    }
    return rel;
  }
}

/// SHA-256 of a file via the platform tool (certutil / sha256sum / shasum);
/// shared with tool/bootstrap_deps.dart, which cannot use pub packages.
String sha256FileSync(String path) {
  if (Platform.isWindows) {
    final r = Process.runSync('certutil', ['-hashfile', path, 'SHA256']);
    if (r.exitCode != 0) throw Exception('certutil failed: ${r.stderr}');
    final hex = RegExp(r'^[A-Fa-f0-9 ]+$');
    final line = (r.stdout as String)
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty && hex.hasMatch(l), orElse: () => '');
    if (line.isEmpty) throw Exception('certutil printed no SHA-256 hash');
    return line.replaceAll(' ', '').toLowerCase();
  }
  try {
    final r = Process.runSync('sha256sum', [path]);
    if (r.exitCode == 0) return (r.stdout as String).split(' ').first.trim();
  } on ProcessException {
    // macOS has no sha256sum; fall through to shasum.
  }
  final r = Process.runSync('shasum', ['-a', '256', path]);
  if (r.exitCode != 0) throw Exception('sha256 tool failed: ${r.stderr}');
  return (r.stdout as String).split(' ').first.trim();
}
