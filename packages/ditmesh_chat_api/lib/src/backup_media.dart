import 'dart:convert';

/// The one rule for which workbench recordings an opt-in backup carries
/// (functional spec §11.3): saved recordings referenced by an audio
/// material, under a plain managed file name — never the working
/// recording, staging or temporary files. The app counts with it before
/// asking, and the backend exports with it, so both always see the same
/// set.
abstract final class BackupMedia {
  /// Largest total of recordings a backup may carry (built in memory).
  static const int maxBytes = 100 * 1024 * 1024;

  /// The audio materials document, relative to
  /// `IdentityService.dataDirectory()`.
  static const String materialsDoc = 'training/docs/audio_materials.json';

  static final RegExp _managed = RegExp(
    r'^media/recordings/([A-Za-z0-9_\-]+(?:\.[A-Za-z0-9]+)?)$',
  );

  /// File names (inside `media/recordings/`) referenced by the audio
  /// materials document [json]; empty when it is missing or unreadable.
  static Set<String> referenced(String? json) {
    if (json == null) return const <String>{};
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      return const <String>{};
    }
    final list = decoded is Map ? decoded['materials'] : null;
    if (list is! List) return const <String>{};
    final out = <String>{};
    for (final m in list) {
      final file = m is Map ? m['file'] : null;
      final match = file is String ? _managed.firstMatch(file) : null;
      final name = match?.group(1);
      if (name != null && name != 'current.wav') out.add(name);
    }
    return out;
  }
}
