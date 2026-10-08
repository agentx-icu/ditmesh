import 'dart:async';

import 'package:flutter/material.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/audio_material_store.dart';
import '../../../training/training_controller.dart';
import 'recording_files.dart';
import 'workbench_controller.dart';
import 'workbench_waveform.dart';

/// Asks for a title and note; returns null when cancelled.
Future<(String, String)?> showSaveSelectionDialog(
  BuildContext context,
  String suggestedTitle,
) => showDialog<(String, String)>(
  context: context,
  builder: (_) => _SaveDialog(suggestedTitle),
);

/// Owns its text controllers so they outlive the closing animation.
class _SaveDialog extends StatefulWidget {
  const _SaveDialog(this.suggestedTitle);

  final String suggestedTitle;

  @override
  State<_SaveDialog> createState() => _SaveDialogState();
}

class _SaveDialogState extends State<_SaveDialog> {
  late final _title = TextEditingController(text: widget.suggestedTitle);
  final _note = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(s.workbenchSave),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              key: const ValueKey('workbench-save-title'),
              controller: _title,
              decoration: InputDecoration(labelText: s.workbenchSaveTitle),
            ),
            TextField(
              controller: _note,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(labelText: s.workbenchSaveNote),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.actionCancel),
        ),
        FilledButton(
          key: const ValueKey('workbench-save-confirm'),
          onPressed: () => Navigator.of(context).pop((
            _title.text.trim().isEmpty
                ? widget.suggestedTitle
                : _title.text.trim(),
            _note.text.trim(),
          )),
          child: Text(s.workbenchSave),
        ),
      ],
    );
  }
}

/// Saved selections: open one, relink a missing recording, or delete the
/// entry. A missing media file never blocks the list.
Future<void> showWorkbenchLibrary(
  BuildContext context, {
  required WorkbenchController controller,
  required TrainingController training,
  required RecordingPicker? picker,
  required VoidCallback onFailure,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _LibrarySheet(
    controller: controller,
    training: training,
    picker: picker,
    onFailure: onFailure,
  ),
);

class _LibrarySheet extends StatefulWidget {
  const _LibrarySheet({
    required this.controller,
    required this.training,
    required this.picker,
    required this.onFailure,
  });

  final WorkbenchController controller;
  final TrainingController training;
  final RecordingPicker? picker;
  final VoidCallback onFailure;

  @override
  State<_LibrarySheet> createState() => _LibrarySheetState();
}

class _LibrarySheetState extends State<_LibrarySheet> {
  List<(AudioMaterial, bool)>? _items;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    final all = await widget.training.loadAudioMaterials();
    final items = <(AudioMaterial, bool)>[
      for (final m in all) (m, await widget.controller.library.exists(m.file)),
    ];
    if (mounted) setState(() => _items = items);
  }

  Future<void> _open(AudioMaterial m) async {
    final ok = await widget.controller.openSaved(
      m.file,
      m.title,
      selection: (m.start, m.end),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    if (!ok) widget.onFailure();
  }

  Future<void> _relink(AudioMaterial m) async {
    final picked =
        await (widget.picker ??
                PlatformRecordingPicker(dialogTitle: context.s.workbenchRelink))
            .pick();
    if (picked == null) return;
    try {
      final reader = await widget.controller.library.importTo(
        picked,
        relativePath: m.file,
      );
      await closeReader(reader);
    } on Object {
      widget.onFailure();
      return;
    }
    await _reload();
  }

  Future<void> _delete(AudioMaterial m) async {
    final stillUsed = await widget.training.deleteAudioMaterial(m.id);
    // The recording that is open stays on disk: saving another selection
    // of it must not point at a deleted file. It is pruned the next time
    // the workbench opens if nothing refers to it any more.
    final open = m.file == widget.controller.file;
    if (!stillUsed && !open && m.file != RecordingLibrary.workingFile) {
      await widget.controller.library.delete(m.file);
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final items = _items;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              s.workbenchLibrary,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (items == null)
              const Center(child: CircularProgressIndicator())
            else if (items.isEmpty)
              Text(s.workbenchLibraryEmpty)
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    for (final (m, present) in items)
                      ListTile(
                        key: ValueKey('workbench-item-${m.id}'),
                        minTileHeight: 56,
                        title: Text(m.title),
                        subtitle: Text(
                          present
                              ? '${formatClock(m.start)} – ${formatClock(m.end)}'
                                    '${m.note.isEmpty ? '' : '\n${m.note}'}'
                              : s.workbenchMissing,
                        ),
                        onTap: present ? () => unawaited(_open(m)) : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (!present)
                              IconButton(
                                tooltip: s.workbenchRelink,
                                onPressed: () => unawaited(_relink(m)),
                                icon: const Icon(Icons.link),
                              ),
                            IconButton(
                              tooltip: s.workbenchDelete,
                              onPressed: () => unawaited(_delete(m)),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
