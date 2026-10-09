import 'dart:io';
import 'vendor_overlay.dart';

/// Rebuilds a copied Dart package; the pinned submodule is always read-only.
abstract final class Tim2ToxDartOverlay {
  static const destination = 'third_party/tim2tox_ditmesh';
  static const patchesPath = 'tool/ci/tim2tox-dart-overlays';
  static const stamp = '.ditmesh-dart-overlay-sha256';

  static List<File> patches(String root) =>
      Directory('$root/$patchesPath')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.patch'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  static String fingerprint(String root) {
    final temp = Directory.systemTemp.createTempSync('ditmesh_dart_digest_');
    try {
      final concat = File('${temp.path}/digest');
      final sink = concat.openSync(mode: FileMode.write);
      final source = Directory('$root/third_party/tim2tox/dart');
      final files =
          source
              .listSync(recursive: true, followLinks: false)
              .whereType<File>()
              .where((f) => !_ignored(f.path))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      for (final file in [...files, ...patches(root)]) {
        sink.writeStringSync(file.path.substring(root.length));
        sink.writeFromSync(file.readAsBytesSync());
      }
      sink.closeSync();
      return sha256FileSync(concat.path);
    } finally {
      temp.deleteSync(recursive: true);
    }
  }

  static String? verify(String root) {
    final file = File('$root/$destination/$stamp');
    if (!file.existsSync() ||
        file.readAsStringSync().trim() != fingerprint(root)) {
      return 'DitMesh Dart overlay is missing or stale; re-run bootstrap';
    }
    return null;
  }

  static void prepare(String root) {
    if (verify(root) == null) return;
    final digest = fingerprint(root);
    final target = Directory('$root/$destination');
    if (target.existsSync() && !File('${target.path}/$stamp').existsSync()) {
      throw StateError('Refusing to replace unmanaged ${target.path}');
    }
    final temporary = Directory(
      '$root/third_party',
    ).createTempSync('.dart-overlay-');
    try {
      final staged = Directory('${temporary.path}/package')..createSync();
      _copy(Directory('$root/third_party/tim2tox/dart'), staged);
      for (final patch in patches(root)) {
        final result = Process.runSync('git', [
          'apply',
          '--unsafe-paths',
          '--directory=${staged.path}',
          patch.path,
        ], workingDirectory: root);
        if (result.exitCode != 0) {
          throw StateError('Dart overlay failed: ${result.stderr}');
        }
      }
      File('${staged.path}/$stamp').writeAsStringSync('$digest\n');
      if (target.existsSync()) target.deleteSync(recursive: true);
      staged.renameSync(target.path);
    } finally {
      temporary.deleteSync(recursive: true);
    }
  }

  static bool _ignored(String path) => path
      .split(RegExp(r'[/\\]'))
      .any((part) => {'.git', '.dart_tool', 'build'}.contains(part));

  static void _copy(Directory source, Directory destination) {
    for (final entry in source.listSync(followLinks: false)) {
      if (_ignored(entry.path)) continue;
      final name = entry.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (entry is File) entry.copySync('${destination.path}/$name');
      if (entry is Directory) {
        final dir = Directory('${destination.path}/$name')..createSync();
        _copy(entry, dir);
      }
    }
  }
}
