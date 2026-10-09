// Bootstrap the Tox chat dependencies for the ditmesh workspace. Ported from
// toxee's tool/bootstrap_deps.dart (2026-09-30) minus the chat-uikit-flutter /
// flutter_skill / record_android branches: ditmesh draws its own chat UI and
// only needs tim2tox_dart + the patched Tencent Cloud Chat SDK it compiles
// against. Run from the repo root: `dart run tool/bootstrap_deps.dart`
// (`--offline-check-only`: verify, no network/writes; `--force`: re-vendor).
//
// Steps: (1) git submodule sync/update for third_party/tim2tox; (2) download
// tencent_cloud_chat_sdk per third_party/tim2tox/tool/tencent_cloud_chat_sdk
// .lock.json into third_party/tencent_cloud_chat_sdk; (3) apply tim2tox's
// patch series with its own apply_sdk_patches.dart; (4) write the ROOT
// pubspec_overrides.yaml (a pub workspace reads overrides at the root only).
// State: third_party/.vendor_state.json (gitignored), so --offline-check-only
// can prove the tree matches the lock without network.
import 'dart:convert';
import 'dart:io';

import 'vendor_overlay.dart';
import 'tim2tox_dart_overlay.dart';

const _submodulePath = 'third_party/tim2tox';
const _submoduleUrl = 'https://github.com/agentx-icu/tim2tox';
const _sdkDirRel = 'third_party/tencent_cloud_chat_sdk';
const _lockRel = '$_submodulePath/tool/tencent_cloud_chat_sdk.lock.json';
const _stateRel = 'third_party/.vendor_state.json';
const _commonStubRel = 'third_party/stubs/tencent_cloud_chat_common';
// ditmesh's platform overlay (no Tencent native SDK), see its README.
const _overlayRel = 'third_party/overlays/tencent_cloud_chat_sdk';

Future<void> main(List<String> args) async {
  final repoRoot = _repoRoot();
  if (args.contains('--offline-check-only')) {
    exit(_offlineCheck(repoRoot));
  }
  final force = args.contains('--force');

  await _ensureSubmodule(repoRoot);

  final lock = _readLock(File('$repoRoot/$_lockRel'));
  final tim2toxDir = Directory('$repoRoot/$_submodulePath');
  final sdkDir = Directory('$repoRoot/$_sdkDirRel');
  final stateFile = File('$repoRoot/$_stateRel');
  final state = _readState(stateFile);

  // Patches mutate the SDK in place (there is no clean "un-apply"), so a
  // changed series forces a re-vendor.
  final patches = _PatchSeries.load(tim2toxDir, lock.version);
  final storedPatchesSha = state['patches_sha256']?.toString() ?? '';
  final integrityError = patches.expectedIntegrityError(storedPatchesSha);
  if (integrityError != null) {
    stderr.writeln('bootstrap_deps: $integrityError');
    exit(1);
  }
  final patchesChanged = patches.exists &&
      storedPatchesSha.isNotEmpty &&
      storedPatchesSha != patches.sha256;

  final needVendor = force ||
      !sdkDir.existsSync() ||
      state['version'] != lock.version ||
      state['sha256'] != lock.sha256 ||
      patchesChanged;

  final newState = <String, dynamic>{};
  if (needVendor) {
    // Drop prior state first so a crash mid-vendor cannot pass offline-check.
    if (stateFile.existsSync()) stateFile.deleteSync();
    await _vendorSdk(lock, sdkDir);
    newState['version'] = lock.version;
    newState['sha256'] = lock.sha256;
  } else {
    newState.addAll(state);
  }

  final mustPatch = patches.exists &&
      (needVendor ||
          newState['patches_applied'] != true ||
          newState['patches_sha256'] != patches.sha256);
  if (mustPatch) {
    stdout.writeln(
      'Applying tencent_cloud_chat_sdk patches from tim2tox '
      '(${patches.names.length} patch(es))...',
    );
    final script = File('${tim2toxDir.path}/tool/apply_sdk_patches.dart');
    if (!script.existsSync()) {
      stderr.writeln('bootstrap_deps: ${script.path} not found');
      exit(1);
    }
    final code = await _run(
      tim2toxDir.path,
      'dart',
      [script.path, '--sdk-dir=${sdkDir.path}'],
    );
    if (code != 0) {
      _writeStateAtomic(stateFile, <String, dynamic>{
        'version': newState['version'],
        'sha256': newState['sha256'],
        'partial': true,
        'reason': 'apply_sdk_patches failed (exit $code)',
      });
      stderr.writeln('bootstrap_deps: apply_sdk_patches failed (exit $code)');
      exit(code);
    }
    newState['patches_applied'] = true;
    newState['patches_sha256'] = patches.sha256;
  }

  // (3b) ditmesh's overlay: no-op platform stubs, no Tencent native SDK.
  final mustOverlay = VendorOverlay(Directory('$repoRoot/$_overlayRel'))
      .applyIfNeeded(sdkDir, newState, force: needVendor || mustPatch);
  if (needVendor || mustPatch || mustOverlay) {
    newState.remove('partial');
    newState.remove('reason');
    _writeStateAtomic(stateFile, newState);
  }

  Tim2ToxDartOverlay.prepare(repoRoot);
  _writeOverrides(repoRoot);
  stdout.writeln('Bootstrap complete.');
}

Future<void> _ensureSubmodule(String repoRoot) async {
  var code = await _run(repoRoot, 'git', ['submodule', 'sync', '--recursive']);
  if (code != 0) {
    stderr.writeln('bootstrap_deps: git submodule sync failed');
    exit(code);
  }
  // Only the tim2tox gitlink itself: its nested c-toxcore submodules are
  // needed for a native build, not for the Dart package.
  code = await _run(
    repoRoot,
    'git',
    ['submodule', 'update', '--init', '--', _submodulePath],
  );
  if (code != 0) {
    stdout.writeln(
      'Submodule not registered yet; cloning from $_submoduleUrl if missing.',
    );
  }
  final dir = Directory('$repoRoot/$_submodulePath');
  if (!dir.existsSync() || dir.listSync().isEmpty) {
    dir.parent.createSync(recursive: true);
    stdout.writeln('Cloning $_submodulePath...');
    code = await _run(repoRoot, 'git', ['clone', _submoduleUrl, _submodulePath]);
    if (code != 0) {
      stderr.writeln('bootstrap_deps: git clone $_submodulePath failed');
      exit(code);
    }
  }
}

class _Lock {
  const _Lock(this.version, this.archiveUrl, this.sha256);
  final String version;
  final String archiveUrl;
  final String sha256;
}

_Lock _readLock(File lockFile) {
  if (!lockFile.existsSync()) {
    stderr.writeln('bootstrap_deps: missing $_lockRel');
    stderr.writeln('  Ensure $_submodulePath is checked out.');
    exit(1);
  }
  final lock = jsonDecode(lockFile.readAsStringSync()) as Map<String, dynamic>;
  final version = lock['version'] as String? ?? '';
  final archiveUrl = lock['archive_url'] as String? ?? '';
  final sha256 = lock['sha256'] as String? ?? '';
  if (version.isEmpty || archiveUrl.isEmpty) {
    stderr.writeln('bootstrap_deps: lock file must have version and archive_url');
    exit(1);
  }
  if (sha256.isEmpty) {
    stderr.writeln(
      'bootstrap_deps: lock file `${lockFile.path}` has no `sha256`; '
      'compute it with `shasum -a 256 <archive>` and commit it upstream.',
    );
    exit(1);
  }
  return _Lock(version, archiveUrl, sha256);
}

Map<String, dynamic> _readState(File f) {
  if (!f.existsSync()) return <String, dynamic>{};
  try {
    return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  } catch (_) {
    return <String, dynamic>{};
  }
}

void _writeStateAtomic(File stateFile, Map<String, dynamic> contents) {
  stateFile.parent.createSync(recursive: true);
  final tmp = File('${stateFile.path}.tmp');
  tmp.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(contents));
  tmp.renameSync(stateFile.path);
}

Future<void> _vendorSdk(_Lock lock, Directory sdkDir) async {
  if (sdkDir.existsSync()) sdkDir.deleteSync(recursive: true);
  sdkDir.createSync(recursive: true);
  final tempDir = Directory.systemTemp.createTempSync('ditmesh_sdk_');
  try {
    final archivePath = '${tempDir.path}/sdk.tar.gz';
    stdout.writeln('Downloading tencent_cloud_chat_sdk ${lock.version}...');
    await _download(lock.archiveUrl, archivePath);
    final actual = await _sha256File(archivePath);
    if (actual != lock.sha256) {
      throw Exception(
        'bootstrap_deps: SHA-256 mismatch (got $actual, expected '
        '${lock.sha256})',
      );
    }
    final extractDir = Directory('${tempDir.path}/x')..createSync();
    await _extractTarGz(archivePath, extractDir.path);
    // A pub tarball is flat; a GitHub tarball has one top-level directory.
    final entries = extractDir.listSync();
    final Directory source = entries.length == 1 && entries.first is Directory
        ? entries.first as Directory
        : extractDir;
    _copyDir(source, sdkDir);
    if (Platform.isWindows) _normalizeLineEndings(sdkDir);
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

Future<void> _download(String url, String destPath) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse(url));
    final resp = await req.close();
    if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
    final sink = File(destPath).openWrite();
    await resp.pipe(sink);
  } finally {
    client.close();
  }
}

Future<void> _extractTarGz(String archivePath, String destDir) async {
  final r = await Process.run('tar', ['-xzf', archivePath, '-C', destDir]);
  if (r.exitCode != 0) throw Exception('tar extract failed: ${r.stderr}');
}

void _copyDir(Directory src, Directory dest) {
  for (final e in src.listSync()) {
    final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final destPath = '${dest.path}/$name';
    if (e is File) {
      File(destPath).parent.createSync(recursive: true);
      e.copySync(destPath);
    } else if (e is Directory) {
      Directory(destPath).createSync(recursive: true);
      _copyDir(e, Directory(destPath));
    }
  }
}

const _textExtensions = {
  '.dart', '.yaml', '.yml', '.json', '.xml', '.gradle', '.kts', '.java', //
  '.kt', '.m', '.mm', '.swift', '.h', '.hpp', '.c', '.cc', '.cpp', '.txt',
  '.md',
};

/// git-apply on Windows chokes on CRLF (same normalisation toxee performs).
void _normalizeLineEndings(Directory sdkDir) {
  for (final entity in sdkDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    final lower = entity.path.toLowerCase();
    if (!_textExtensions.any(lower.endsWith)) continue;
    final contents = entity.readAsStringSync();
    final normalized = contents.replaceAll('\r\n', '\n');
    if (contents != normalized) entity.writeAsStringSync(normalized);
  }
}

class _PatchSeries {
  _PatchSeries._(this.dir, this.seriesFile, this.names);

  factory _PatchSeries.load(Directory tim2toxDir, String version) {
    final dir = Directory(
      '${tim2toxDir.path}/patches/tencent_cloud_chat_sdk/$version',
    );
    final series = File('${dir.path}/series');
    final names = series.existsSync()
        ? series
            .readAsLinesSync()
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty && !l.startsWith('#'))
            .toList()
        : const <String>[];
    return _PatchSeries._(dir, series, names);
  }

  final Directory dir;
  final File seriesFile;
  final List<String> names;

  bool get exists => seriesFile.existsSync();

  String? get firstMissing {
    for (final n in names) {
      if (!File('${dir.path}/$n').existsSync()) return n;
    }
    return null;
  }

  /// SHA-256 over `series` + every patch body, in series order.
  late final String sha256 = _computeSha256();

  String _computeSha256() {
    final tmp = Directory.systemTemp.createTempSync('ditmesh_patches_');
    try {
      final concat = File('${tmp.path}/concat.bin');
      final sink = concat.openSync(mode: FileMode.write);
      try {
        sink.writeFromSync(seriesFile.readAsBytesSync());
        for (final n in names) {
          sink.writeFromSync(File('${dir.path}/$n').readAsBytesSync());
        }
      } finally {
        sink.closeSync();
      }
      return _sha256FileSync(concat.path);
    } finally {
      tmp.deleteSync(recursive: true);
    }
  }

  /// Null when the on-disk series is consistent with [storedSha256].
  String? expectedIntegrityError(String storedSha256) {
    if (exists && names.isEmpty) {
      return 'patch series is empty or comment-only; refusing to treat it as '
          'valid';
    }
    if (!exists && storedSha256.isNotEmpty) {
      return 'patch series is missing while vendor_state.patches_sha256 '
          'records expected patches';
    }
    final missing = exists ? firstMissing : null;
    if (missing != null) return 'patch series declares missing patch: $missing';
    return null;
  }
}

void _writeOverrides(String repoRoot) {
  final out = StringBuffer()
    ..writeln('# Generated by tool/bootstrap_deps.dart - do not edit, do not '
        'commit.')
    ..writeln('# Points the workspace at the vendored, patched Tencent Cloud '
        'Chat SDK and')
    ..writeln('# the tim2tox Dart package. Re-run the tool after a submodule '
        'bump.')
    ..writeln('dependency_overrides:')
    ..writeln('  tim2tox_dart:')
    ..writeln('    path: ${Tim2ToxDartOverlay.destination}')
    ..writeln('  tencent_cloud_chat_sdk:')
    ..writeln('    path: $_sdkDirRel')
    // tim2tox_dart's pubspec requires tencent_cloud_chat_common (a UIKit
    // widget package) but only Tim2ToxSdkPlatform imports it, and ditmesh
    // never compiles that file. The stub satisfies pub without dragging the
    // UIKit plugin tree (TUICore, hive, audioplayers, ...) into the app.
    ..writeln('  tencent_cloud_chat_common:')
    ..writeln('    path: $_commonStubRel');
  final file = File('$repoRoot/pubspec_overrides.yaml');
  final body = out.toString();
  // Only rewrite when the content differs: Flutter's build gates `pub get`
  // on this file's mtime.
  if (!file.existsSync() || file.readAsStringSync() != body) {
    file.writeAsStringSync(body);
  }
}

int _offlineCheck(String repoRoot) {
  int fail(String msg) {
    stderr.writeln('bootstrap_deps: offline-check: $msg');
    return 1;
  }

  final lockFile = File('$repoRoot/$_lockRel');
  final dartProblem = Tim2ToxDartOverlay.verify(repoRoot);
  if (dartProblem != null) return fail(dartProblem);
  if (!lockFile.existsSync()) return fail('lock file missing');
  final tim2tox = Directory('$repoRoot/$_submodulePath');
  if (!tim2tox.existsSync()) return fail('submodule directory missing');
  if (!Directory('$repoRoot/$_sdkDirRel').existsSync()) {
    return fail('$_sdkDirRel missing');
  }
  if (!File('$repoRoot/$_commonStubRel/pubspec.yaml').existsSync()) {
    return fail('$_commonStubRel missing');
  }
  final stateFile = File('$repoRoot/$_stateRel');
  if (!stateFile.existsSync()) return fail('$_stateRel missing');
  Map<String, dynamic> lock;
  Map<String, dynamic> state;
  try {
    lock = jsonDecode(lockFile.readAsStringSync()) as Map<String, dynamic>;
    state = jsonDecode(stateFile.readAsStringSync()) as Map<String, dynamic>;
  } catch (e) {
    return fail('failed to parse lock/state json: $e');
  }
  final lockVersion = lock['version']?.toString() ?? '';
  final lockSha = lock['sha256']?.toString() ?? '';
  if (lockVersion.isEmpty || lockSha.isEmpty) {
    return fail('lock file missing version or sha256');
  }
  if (state['version']?.toString() != lockVersion) {
    return fail(
      'vendor_state version mismatch (state=${state['version']}, '
      'lock=$lockVersion)',
    );
  }
  if (state['sha256']?.toString() != lockSha) {
    return fail('vendor_state sha256 does not match lock');
  }
  if (state['partial'] == true) {
    return fail(
      'vendor_state is marked partial (${state['reason'] ?? 'unknown'}); '
      're-run `dart run tool/bootstrap_deps.dart --force`.',
    );
  }
  final patches = _PatchSeries.load(tim2tox, lockVersion);
  final stored = state['patches_sha256']?.toString() ?? '';
  final err = patches.expectedIntegrityError(stored);
  if (err != null) return fail(err);
  if (patches.exists) {
    if (stored.isEmpty) {
      return fail(
        'vendor_state.patches_sha256 missing but a patch series exists; '
        're-run `dart run tool/bootstrap_deps.dart`.',
      );
    }
    if (patches.sha256 != stored) {
      return fail(
        'patches_sha256 in vendor_state does not match the current patches '
        '(re-run `dart run tool/bootstrap_deps.dart`)',
      );
    }
  }
  final overlay = VendorOverlay(Directory('$repoRoot/$_overlayRel'));
  final overlayProblem = overlay.verifyApplied(Directory('$repoRoot/$_sdkDirRel'));
  if (overlayProblem != null ||
      state['overlay_sha256']?.toString() != overlay.sha256) {
    return fail(
      '${overlayProblem ?? 'overlay_sha256 in vendor_state does not match $_overlayRel'} '
      '(re-run `dart run tool/bootstrap_deps.dart`)',
    );
  }
  if (!File('$repoRoot/pubspec_overrides.yaml').existsSync()) {
    return fail('pubspec_overrides.yaml missing (re-run the tool)');
  }
  stdout.writeln('bootstrap_deps: offline-check OK');
  return 0;
}

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync() &&
        File('${dir.path}/tool/bootstrap_deps.dart').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      stderr.writeln('bootstrap_deps: run from the ditmesh repo root');
      exit(1);
    }
    dir = parent;
  }
}

Future<int> _run(String cwd, String executable, List<String> args) async {
  final r = await Process.run(executable, args, workingDirectory: cwd);
  if (r.stdout.toString().trim().isNotEmpty) stdout.write(r.stdout);
  if (r.stderr.toString().trim().isNotEmpty) stderr.write(r.stderr);
  return r.exitCode;
}

Future<String> _sha256File(String path) async => _sha256FileSync(path);

String _sha256FileSync(String path) => sha256FileSync(path);
