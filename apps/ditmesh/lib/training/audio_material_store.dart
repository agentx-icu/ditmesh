import 'training_controller.dart';

/// A saved selection of a recording plus the learner's note (spec §11.2.5).
/// Only this metadata lives in the training directory (and so in identity
/// backups); the media file is referenced by a path relative to the profile
/// and may be missing, which never breaks loading.
final class AudioMaterial {
  const AudioMaterial({
    required this.id,
    required this.title,
    required this.file,
    required this.originalName,
    required this.start,
    required this.end,
    required this.sampleRate,
    required this.channels,
    required this.createdAt,
    this.note = '',
  });

  final String id;
  final String title;

  /// Media path relative to the profile directory (`media/recordings/…`).
  final String file;
  final String originalName;

  /// Selection on the recording's sample clock.
  final Duration start;
  final Duration end;
  final int sampleRate;
  final int channels;
  final DateTime createdAt;
  final String note;

  AudioMaterial copyWith({String? title, String? note}) => AudioMaterial(
    id: id,
    title: title ?? this.title,
    file: file,
    originalName: originalName,
    start: start,
    end: end,
    sampleRate: sampleRate,
    channels: channels,
    createdAt: createdAt,
    note: note ?? this.note,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'title': title,
    'file': file,
    'originalName': originalName,
    'startUs': start.inMicroseconds,
    'endUs': end.inMicroseconds,
    'sampleRate': sampleRate,
    'channels': channels,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'note': note,
  };

  /// The only media paths accepted: a plain file name under
  /// `media/recordings/` (no drive letters, backslashes or `..`), so a
  /// restored or edited document can never point outside the profile.
  static final RegExp safeFile = RegExp(
    r'^media/recordings/[A-Za-z0-9_\-]+(\.[A-Za-z0-9]+)?$',
  );

  factory AudioMaterial.fromJson(Map<String, Object?> json) {
    final file = json['file'];
    if (file is! String || !safeFile.hasMatch(file)) {
      throw const FormatException('unsafe media path');
    }
    return AudioMaterial(
      id: json['id']! as String,
      title: json['title'] as String? ?? '',
      file: file,
      originalName: json['originalName'] as String? ?? '',
      start: Duration(microseconds: (json['startUs']! as num).toInt()),
      end: Duration(microseconds: (json['endUs']! as num).toInt()),
      sampleRate: (json['sampleRate']! as num).toInt(),
      channels: (json['channels']! as num).toInt(),
      createdAt: DateTime.parse(json['createdAt']! as String),
      note: json['note'] as String? ?? '',
    );
  }
}

/// Audio material metadata as one training document.
extension AudioMaterialStore on TrainingController {
  static const String doc = 'audio_materials';

  /// Every readable entry; a damaged entry is skipped, never fatal.
  Future<List<AudioMaterial>> loadAudioMaterials() async {
    final json = await readDoc(doc);
    final list = json?['materials'];
    if (list is! List) return <AudioMaterial>[];
    final out = <AudioMaterial>[];
    for (final m in list) {
      try {
        out.add(AudioMaterial.fromJson(m as Map<String, Object?>));
      } on Object {
        continue;
      }
    }
    return out;
  }

  Future<void> _saveAll(List<AudioMaterial> all) =>
      writeDoc(doc, <String, Object?>{
        'v': 1,
        'materials': [for (final m in all) m.toJson()],
      });

  /// Read-modify-write under the controller's document transaction, so
  /// concurrent saves and deletions never lose or resurrect entries.
  Future<void> upsertAudioMaterial(AudioMaterial material) =>
      docTransaction(() async {
        final all = await loadAudioMaterials();
        final at = all.indexWhere((m) => m.id == material.id);
        if (at < 0) {
          all.add(material);
        } else {
          all[at] = material;
        }
        await _saveAll(all);
      });

  /// Removes the entry and returns whether its media file is still
  /// referenced by another entry (checked inside the same transaction).
  Future<bool> deleteAudioMaterial(String id) => docTransaction(() async {
    final all = await loadAudioMaterials();
    final gone = all.where((m) => m.id == id).toList();
    final rest = all.where((m) => m.id != id).toList();
    await _saveAll(rest);
    return gone.any((g) => rest.any((m) => m.file == g.file));
  });

  /// A new id, also used as the media file name.
  String newAudioMaterialId() =>
      'rec_${now().microsecondsSinceEpoch.toRadixString(36)}_'
      '${random.nextInt(1 << 30).toRadixString(36)}';
}
