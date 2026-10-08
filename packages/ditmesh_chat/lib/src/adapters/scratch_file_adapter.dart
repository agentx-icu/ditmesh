import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:tim2tox_dart/interfaces/scratch_file_service.dart';

/// Tim2Tox [ScratchFileService] rooted at one identity's `scratch/` directory.
///
/// Every write lands in its own fresh subdirectory, so concurrent calls with
/// the same suggested basename never collide. Basenames are sanitized but the
/// extension and any `__dur{ms}` suffix are preserved, as the interface
/// requires. Tim2Tox deletes what it created via [deleteScratchFile]; the
/// identity teardown removes the whole root as a safety net.
class IdentityScratchFileService implements ScratchFileService {
  IdentityScratchFileService(this.rootDirectory);

  final String rootDirectory;
  int _sequence = 0;

  static final RegExp _unsafe = RegExp(r'[<>:"/\\|?*\u0000-\u001f]');

  String _sanitizeName(String suggested) {
    final base = p.basename(suggested).trim();
    final cleaned = base.replaceAll(_unsafe, '_');
    return cleaned.isEmpty ? 'scratch' : cleaned;
  }

  Future<String> _allocate(String category, String suggestedFileName) async {
    final safeCategory = _sanitizeName(category);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final dir = Directory(
      p.join(rootDirectory, safeCategory, '${stamp}_${_sequence++}'),
    );
    await dir.create(recursive: true);
    return p.join(dir.path, _sanitizeName(suggestedFileName));
  }

  @override
  Future<String> writeBytesToScratch(
    Uint8List bytes, {
    required String category,
    required String suggestedFileName,
  }) async {
    final path = await _allocate(category, suggestedFileName);
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  @override
  Future<String> copyFileToScratch(
    String sourcePath, {
    required String category,
    required String suggestedFileName,
  }) async {
    final path = await _allocate(category, suggestedFileName);
    await File(sourcePath).copy(path);
    return path;
  }

  @override
  Future<void> deleteScratchFile(String path) async {
    // Only ever delete inside our root: Tim2Tox hands back the paths we
    // returned, but a defensive check costs nothing.
    if (!p.isWithin(rootDirectory, path)) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
    final parent = file.parent;
    if (await parent.exists() && parent.listSync().isEmpty) {
      await parent.delete();
    }
  }

  /// Removes every scratch file. Called on disconnect / identity deletion.
  Future<void> clear() async {
    final dir = Directory(rootDirectory);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
