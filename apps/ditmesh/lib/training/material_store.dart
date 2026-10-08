import 'package:morse_trainer/morse_trainer.dart';

import 'training_controller.dart';

/// The learner's material library (functional spec §9), one document under
/// the profile's training directory, so identity backups include it.
extension MaterialStore on TrainingController {
  static const String doc = 'materials';

  Future<List<TrainingMaterial>> loadMaterials() async {
    final json = await readDoc(doc);
    final list = json?['materials'];
    if (list is! List) return <TrainingMaterial>[];
    final out = <TrainingMaterial>[];
    for (final m in list) {
      // A single bad entry must not hide the rest of the library.
      try {
        out.add(TrainingMaterial.fromJson(m as Map<String, Object?>));
      } on Object {
        continue;
      }
    }
    return out;
  }

  Future<void> saveMaterials(List<TrainingMaterial> materials) =>
      writeDoc(doc, <String, Object?>{
        'v': 1,
        'materials': [for (final m in materials) m.toJson()],
      });

  Future<void> upsertMaterial(TrainingMaterial material) =>
      docTransaction(() async {
        final all = await loadMaterials();
        final at = all.indexWhere((m) => m.id == material.id);
        if (at < 0) {
          all.add(material);
        } else {
          all[at] = material;
        }
        await saveMaterials(all);
      });

  Future<void> deleteMaterial(String id) => docTransaction(() async {
    final all = await loadMaterials();
    await saveMaterials(all.where((m) => m.id != id).toList());
  });

  /// Applies [update] to the whole library atomically (imports, merges).
  Future<void> updateMaterials(
    List<TrainingMaterial> Function(List<TrainingMaterial> all) update,
  ) => docTransaction(() async {
    await saveMaterials(update(await loadMaterials()));
  });

  /// Materials saved from messages of [conversationId] (shown when that
  /// conversation's history is cleared: the copies stay independent).
  Future<int> materialsFromConversation(String conversationId) async {
    final prefix = 'chat:$profileKey/$conversationId/';
    return (await loadMaterials())
        .where((m) => m.source?.localRef?.startsWith(prefix) ?? false)
        .length;
  }

  /// Saves a confirmed chat message snapshot as a text material. The id is
  /// derived from the message reference, so a retried save never adds a
  /// second copy. Returns the stored material.
  Future<TrainingMaterial> saveChatMaterial({
    required String conversationId,
    required String messageId,
    required String text,
    required String title,
    required String description,
  }) => docTransaction(() async {
    final ref = 'chat:$profileKey/$conversationId/$messageId';
    final id = 'chat_${_fnv(ref)}';
    final all = await loadMaterials();
    for (final m in all) {
      if (m.id == id) return m;
    }
    final analysis = MaterialImport.analyze(text, MaterialKind.text);
    final material = MaterialImport.create(
      id: id,
      title: title,
      kind: MaterialKind.text,
      text: text,
      analysis: analysis,
      now: now(),
      source: MaterialSource(description: description, localRef: ref),
    );
    await saveMaterials([...all, material]);
    return material;
  });

  /// A new random material id.
  String newMaterialId() =>
      'm_${now().microsecondsSinceEpoch.toRadixString(36)}_'
      '${random.nextInt(1 << 30).toRadixString(36)}';

  static String _fnv(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }
}
