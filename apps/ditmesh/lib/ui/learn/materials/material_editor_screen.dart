import 'dart:async';

import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/material_store.dart';
import '../../../training/training_controller.dart';
import 'material_labels.dart';

/// Create or edit a material (functional spec §9.1–9.2). The preview shows
/// counts, segments, unsupported characters, prosigns and duplicates before
/// anything is saved; limits are rejected explicitly. The original text is
/// kept as typed; only the trainable items are normalised.
class MaterialEditorScreen extends StatefulWidget {
  const MaterialEditorScreen({
    super.key,
    required this.controller,
    this.existing,
    this.initialText,
    this.initialTitle,
  });

  final TrainingController controller;
  final TrainingMaterial? existing;

  /// Prefill from an imported TXT file.
  final String? initialText;
  final String? initialTitle;

  @override
  State<MaterialEditorScreen> createState() => _MaterialEditorScreenState();
}

class _MaterialEditorScreenState extends State<MaterialEditorScreen> {
  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.title ?? widget.initialTitle ?? '',
  );
  late final TextEditingController _tags = TextEditingController(
    text: widget.existing?.tags.join(', ') ?? '',
  );
  late final TextEditingController _text = TextEditingController(
    text: widget.existing?.originalText ?? widget.initialText ?? '',
  );
  late MaterialKind _kind = widget.existing?.kind ?? MaterialKind.text;
  late MaterialAnalysis _analysis = MaterialImport.analyze(_text.text, _kind);
  bool _saving = false;
  Timer? _debounce;

  void _reanalyze() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _analysis = MaterialImport.analyze(_text.text, _kind));
      }
    });
  }

  Future<void> _save() async {
    final analysis = MaterialImport.analyze(_text.text, _kind);
    if (!analysis.ok || _title.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    final c = widget.controller;
    final tags = _tags.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final existing = widget.existing;
    final material = existing == null
        ? MaterialImport.create(
            id: c.newMaterialId(),
            title: _title.text.trim(),
            kind: _kind,
            text: _text.text,
            analysis: analysis,
            now: c.now(),
            tags: tags,
          )
        : existing.copyWith(
            title: _title.text.trim(),
            kind: _kind,
            originalText: _text.text,
            normalizedItems: analysis.items,
            tags: tags,
            updatedAt: c.now(),
          );
    try {
      await c.upsertMaterial(material);
      if (mounted) Navigator.of(context).pop(material);
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(context.s.materialsSaveFailed)));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _title.dispose();
    _tags.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final a = _analysis;
    final canSave = a.ok && _title.text.trim().isNotEmpty && !_saving;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? s.materialsNew : s.materialsEdit),
        actions: <Widget>[
          TextButton(
            key: const ValueKey('material-save'),
            onPressed: canSave ? () => unawaited(_save()) : null,
            child: Text(s.materialsSave),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextField(
                    controller: _title,
                    decoration: InputDecoration(
                      labelText: s.materialsTitleField,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<MaterialKind>(
                    segments: <ButtonSegment<MaterialKind>>[
                      for (final k in MaterialKind.values)
                        ButtonSegment(
                          value: k,
                          label: Text(MaterialLabels.kind(s, k)),
                        ),
                    ],
                    selected: <MaterialKind>{_kind},
                    showSelectedIcon: false,
                    onSelectionChanged: (v) {
                      setState(() => _kind = v.first);
                      _reanalyze();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tags,
                    decoration: InputDecoration(
                      labelText: s.materialsTagsField,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('material-text'),
                    controller: _text,
                    minLines: 5,
                    maxLines: 14,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: _kind == MaterialKind.text
                          ? s.materialsTextField
                          : s.materialsListField,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => _reanalyze(),
                  ),
                  const SizedBox(height: 12),
                  MaterialPreview(analysis: a, kind: _kind),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Counts, problems and the first trainable items of an analysis.
class MaterialPreview extends StatelessWidget {
  const MaterialPreview({
    super.key,
    required this.analysis,
    required this.kind,
  });

  final MaterialAnalysis analysis;
  final MaterialKind kind;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final a = analysis;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(s.materialsPreview, style: theme.textTheme.titleSmall),
            Text(
              s.materialsPreviewCounts(
                a.items.length,
                a.symbolCount,
                a.prosigns,
              ),
            ),
            if (a.unsupported.isNotEmpty)
              Text(
                s.materialsPreviewUnsupported(a.unsupported.join(' ')),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            if (a.duplicates.isNotEmpty)
              Text(s.materialsPreviewDuplicates(a.duplicates.length)),
            for (final p in a.problems)
              Text(
                MaterialLabels.problem(s, p),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            const SizedBox(height: 8),
            for (final item in a.items.take(5))
              Text(
                item,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
