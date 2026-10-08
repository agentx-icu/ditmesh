import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/material_practice.dart';
import '../../../training/material_store.dart';
import '../../../training/training_controller.dart';
import '../learn_playback.dart';
import '../receive/receive_drill_screen.dart';
import 'material_editor_screen.dart';
import 'material_export_sheet.dart';
import 'material_file_gateway.dart';
import 'material_labels.dart';

/// My materials (functional spec §9): the learner's own texts, word lists
/// and callsigns — create, edit, import TXT/JSON, export JSON or WAV,
/// favourite, search, practise.
class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({
    super.key,
    required this.controller,
    required this.playback,
  });

  final TrainingController controller;
  final LearnPlaybackFactory playback;

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final TextEditingController _search = TextEditingController();
  List<TrainingMaterial>? _all;
  bool _favoritesOnly = false;

  TrainingController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    final all = await _c.loadMaterials();
    if (mounted) setState(() => _all = all);
  }

  void _snack(String text) => ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(SnackBar(content: Text(text)));

  List<TrainingMaterial> get _visible {
    final q = _search.text.trim().toLowerCase();
    return (_all ?? const <TrainingMaterial>[])
        .where((m) => !_favoritesOnly || m.favorite)
        .where(
          (m) =>
              q.isEmpty ||
              m.title.toLowerCase().contains(q) ||
              m.tags.any((t) => t.toLowerCase().contains(q)) ||
              m.originalText.toLowerCase().contains(q),
        )
        .toList()
      ..sort((a, b) {
        if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
  }

  Future<void> _edit({
    TrainingMaterial? existing,
    String? text,
    String? title,
  }) async {
    final saved = await Navigator.of(context).push<TrainingMaterial>(
      MaterialPageRoute(
        builder: (_) => MaterialEditorScreen(
          controller: _c,
          existing: existing,
          initialText: text,
          initialTitle: title,
        ),
      ),
    );
    if (saved != null) await _reload();
  }

  Future<void> _import() async {
    final gateway = MaterialFileGateway.of(context);
    final s = context.s;
    PickedFile? file;
    try {
      file = await gateway.pick(maxBytes: MaterialLimits.maxBytes);
    } on PickedFileTooLarge {
      _snack(s.materialsProblemTooLarge);
      return;
    } on Object {
      _snack(s.materialsImportFailed);
      return;
    }
    if (file == null || !mounted) return;
    final String text;
    try {
      text = utf8.decode(file.bytes);
    } on FormatException {
      _snack(s.materialsImportNotUtf8);
      return;
    }
    if (file.name.toLowerCase().endsWith('.json')) {
      await _importLibrary(text);
    } else {
      final dot = file.name.lastIndexOf('.');
      await _edit(
        text: text,
        title: dot > 0 ? file.name.substring(0, dot) : file.name,
      );
    }
  }

  /// A JSON library is imported whole or not at all.
  Future<void> _importLibrary(String raw) async {
    final s = context.s;
    final List<TrainingMaterial> incoming;
    try {
      incoming = MaterialLibraryCodec.decode(raw);
    } on FormatException {
      _snack(s.materialsImportInvalid);
      return;
    }
    final all = await _c.loadMaterials();
    final ids = all.map((m) => m.id).toSet();
    final seen = <String>{};
    // Collisions with the library or within the file itself.
    final collides = incoming.any((m) => ids.contains(m.id) || !seen.add(m.id));
    if (!mounted) return;
    // Every import is previewed and confirmed before anything is written.
    final policy = await showDialog<DuplicatePolicy>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(s.materialsImportConfirm(incoming.length)),
        children: <Widget>[
          for (final m in incoming.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '• ${m.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (collides)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Text(s.materialsDuplicateTitle),
            ),
          for (final p
              in collides
                  ? DuplicatePolicy.values
                  : const <DuplicatePolicy>[DuplicatePolicy.keepCopy])
            SimpleDialogOption(
              key: ValueKey('import-${p.name}'),
              onPressed: () => Navigator.of(context).pop(p),
              child: Text(switch (p) {
                _ when !collides => s.materialsImport,
                DuplicatePolicy.overwrite => s.materialsDuplicateOverwrite,
                DuplicatePolicy.keepCopy => s.materialsDuplicateKeepCopy,
                DuplicatePolicy.skip => s.materialsDuplicateSkip,
              }),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.actionCancel),
          ),
        ],
      ),
    );
    if (policy == null) return;
    try {
      await _c.updateMaterials(
        (current) => MaterialLibraryCodec.merge(
          current,
          incoming,
          policy: policy,
          newId: _c.newMaterialId,
        ),
      );
      _snack(s.materialsImported(incoming.length));
    } on Object {
      _snack(s.materialsImportFailed);
    }
    await _reload();
  }

  /// Plain-text export keeps the original text (line breaks included), so
  /// a list exported here imports back as the same list.
  Future<void> _exportText(TrainingMaterial m) async {
    final s = context.s;
    try {
      final ok = await MaterialFileGateway.of(context).save(
        Uint8List.fromList(utf8.encode(m.originalText)),
        fileName: '${safeFileName(m.title)}.txt',
        mimeType: 'text/plain',
      );
      if (ok) _snack(s.materialsExported(1));
    } on Object {
      _snack(s.materialsExportFailed);
    }
  }

  Future<void> _exportLibrary() async {
    final s = context.s;
    final list = _visible;
    if (list.isEmpty) return;
    try {
      final ok = await MaterialFileGateway.of(context).save(
        Uint8List.fromList(utf8.encode(MaterialLibraryCodec.encode(list))),
        fileName: 'ditmesh-materials.json',
        mimeType: 'application/json',
      );
      if (ok) _snack(s.materialsExported(list.length));
    } on Object {
      _snack(s.materialsExportFailed);
    }
  }

  Future<void> _practise(TrainingMaterial m) async {
    final s = context.s;
    final unavailable = _c.unavailableLearnedOnly(m);
    final learnedOnly = await showDialog<bool>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(s.materialsPracticeMode),
        children: <Widget>[
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              unavailable == 0
                  ? s.materialsPracticeLearned
                  : s.materialsPracticeLearnedPartial(unavailable),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.materialsPracticeAll),
          ),
        ],
      ),
    );
    if (learnedOnly == null || !mounted) return;
    final session = _c.startMaterialSession(m, learnedOnly: learnedOnly);
    if (session == null) {
      _snack(s.materialsPracticeNothing);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<Object?>(
        builder: (_) => ReceiveDrillScreen(
          controller: _c,
          playback: widget.playback,
          session: session,
          title: m.title,
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(TrainingMaterial m) async {
    await _c.upsertMaterial(m.copyWith(favorite: !m.favorite));
    await _reload();
  }

  Future<void> _delete(TrainingMaterial m) async {
    final s = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.materialsDeleteTitle),
        content: Text(s.materialsDeleteBody(m.title)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.materialsDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _c.deleteMaterial(m.id);
    await _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final all = _all;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.materialsTitle),
        actions: <Widget>[
          IconButton(
            tooltip: s.materialsImport,
            icon: const Icon(Icons.file_open_outlined),
            onPressed: () => unawaited(_import()),
          ),
          IconButton(
            tooltip: s.materialsExportJson,
            icon: const Icon(Icons.ios_share),
            onPressed: (all?.isEmpty ?? true)
                ? null
                : () => unawaited(_exportLibrary()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('material-new'),
        onPressed: () => unawaited(_edit()),
        icon: const Icon(Icons.add),
        label: Text(s.materialsNew),
      ),
      body: all == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: s.materialsSearch,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FilterChip(
                      label: Text(s.materialsFavoritesOnly),
                      selected: _favoritesOnly,
                      onSelected: (v) => setState(() => _favoritesOnly = v),
                    ),
                  ),
                ),
                Expanded(
                  child: all.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              s.materialsEmpty,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 88),
                          children: [
                            for (final m in _visible) _tile(context, m),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _tile(BuildContext context, TrainingMaterial m) {
    final s = context.s;
    return ListTile(
      minTileHeight: 64,
      leading: IconButton(
        tooltip: m.favorite ? s.materialsUnfavorite : s.materialsFavorite,
        icon: Icon(m.favorite ? Icons.star : Icons.star_border),
        onPressed: () => unawaited(_toggleFavorite(m)),
      ),
      title: Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          MaterialLabels.kind(s, m.kind),
          s.materialsItems(m.normalizedItems.length),
          if (m.source != null) s.materialsFromChat,
          ...m.tags,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => unawaited(_practise(m)),
      trailing: PopupMenuButton<String>(
        tooltip: s.materialsActions,
        onSelected: (v) => unawaited(switch (v) {
          'practise' => _practise(m),
          'wav' => showMaterialExportSheet(
            context,
            controller: _c,
            material: m,
          ),
          'txt' => _exportText(m),
          'edit' => _edit(existing: m),
          _ => _delete(m),
        }),
        itemBuilder: (_) => [
          PopupMenuItem(value: 'practise', child: Text(s.materialsPractise)),
          PopupMenuItem(value: 'wav', child: Text(s.materialsExportWav)),
          PopupMenuItem(value: 'txt', child: Text(s.materialsExportTxt)),
          PopupMenuItem(value: 'edit', child: Text(s.materialsEdit)),
          PopupMenuItem(value: 'delete', child: Text(s.materialsDelete)),
        ],
      ),
    );
  }
}
