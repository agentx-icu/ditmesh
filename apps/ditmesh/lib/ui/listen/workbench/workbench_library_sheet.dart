import 'dart:async';

import 'package:flutter/material.dart';
import 'package:morse_dsp/morse_dsp.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/audio_material_store.dart';
import '../../../training/training_controller.dart';
import '../../common/field_label.dart';
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
              decoration: InputDecoration(
                label: FieldLabel(s.workbenchSaveTitle),
              ),
            ),
            TextField(
              controller: _note,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                label: FieldLabel(s.workbenchSaveNote),
              ),
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
  required VoidCallback onChanged,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _LibrarySheet(
    controller: controller,
    training: training,
    picker: picker,
    onFailure: onFailure,
    onChanged: onChanged,
  ),
);

class _LibrarySheet extends StatefulWidget {
  const _LibrarySheet({
    required this.controller,
    required this.training,
    required this.picker,
    required this.onFailure,
    required this.onChanged,
  });

  final WorkbenchController controller;
  final TrainingController training;
  final RecordingPicker? picker;
  final VoidCallback onFailure;
  final VoidCallback onChanged;

  @override
  State<_LibrarySheet> createState() => _LibrarySheetState();
}

class _LibrarySheetState extends State<_LibrarySheet> {
  List<(AudioMaterial, bool)>? _items;
  bool _loadFailed = false;
  bool _opening = false;
  bool _deleting = false;
  String? _error;
  String? _outcome;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    try {
      final all = await widget.training.loadAudioMaterials();
      final items = <(AudioMaterial, bool)>[
        for (final m in all)
          (m, await widget.controller.library.exists(m.file)),
      ];
      if (mounted) {
        setState(() {
          _items = items;
          _loadFailed = false;
        });
      }
    } on Object {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _open(AudioMaterial m) async {
    if (_opening || _deleting) return;
    _opening = true;
    final route = ModalRoute.of<void>(context);
    final bool ok;
    try {
      ok = await widget.controller.openSaved(
        m.file,
        m.title,
        selection: (m.start, m.end),
      );
    } finally {
      _opening = false;
    }
    if (!mounted || route?.isActive != true) return;
    final navigator = route!.navigator!;
    if (route.isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(route);
    }
    if (!ok) widget.onFailure();
  }

  Future<void> _relink(AudioMaterial m) async {
    final s = context.s;
    final onChanged = widget.onChanged;
    setState(() => _error = null);
    try {
      final picked =
          await (widget.picker ??
                  PlatformRecordingPicker(dialogTitle: s.workbenchRelink))
              .pick();
      if (picked == null || !mounted) return;
      final clips = await widget.training.loadAudioMaterials();
      Duration minimum = m.end;
      for (final clip in clips) {
        if (clip.file == m.file && clip.end > minimum) minimum = clip.end;
      }
      final reader = await widget.controller.library.importTo(
        picked,
        relativePath: m.file,
        minimumDuration: minimum,
      );
      await closeReader(reader);
    } on RecordingTooShortException catch (error) {
      if (mounted) {
        setState(() {
          _error = s.workbenchRelinkTooShort(
            formatClock(error.actualLength),
            formatClock(error.requiredLength),
          );
        });
      }
      return;
    } on WavFormatException catch (error) {
      if (mounted) setState(() => _error = workbenchWavError(s, error.error));
      return;
    } on Object {
      if (mounted) setState(() => _error = s.workbenchErrorIo);
      return;
    }
    onChanged();
    await _reload();
  }

  Future<void> _delete(AudioMaterial m) async {
    if (_deleting || _opening) return;
    final s = context.s;
    final onChanged = widget.onChanged;
    setState(() {
      _deleting = true;
      _error = null;
      _outcome = null;
    });
    var removed = false;
    try {
      final materials = await widget.training.loadAudioMaterials();
      final deleteFile =
          m.file != widget.controller.file &&
          m.file != RecordingLibrary.workingFile &&
          !materials.any((item) => item.id != m.id && item.file == m.file) &&
          await widget.controller.library.exists(m.file);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(s.workbenchDeleteClipTitle(m.title)),
          content: Text(
            deleteFile
                ? s.workbenchDeleteClipAndFile
                : s.workbenchDeleteClipOnly,
          ),
          actions: [
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(s.actionCancel),
            ),
            FilledButton(
              key: const ValueKey('workbench-confirm-delete'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(s.workbenchDelete),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final stillUsed = await widget.training.deleteAudioMaterial(m.id);
      removed = true;
      // Remove audio only within the scope approved in the dialog.
      final deleteNow =
          deleteFile && !stillUsed && m.file != widget.controller.file;
      if (deleteNow) {
        await widget.controller.library.delete(m.file);
      }
      if (mounted) {
        setState(
          () => _outcome = deleteNow
              ? s.workbenchRemovedClipAndFile
              : s.workbenchRemovedClip,
        );
      }
    } on Object {
      if (mounted) {
        setState(
          () => _error = removed
              ? s.workbenchRemovedClipFileError
              : s.workbenchErrorIo,
        );
      }
    } finally {
      if (removed) onChanged();
      if (mounted) {
        setState(() => _deleting = false);
        await _reload();
      }
    }
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
            if ((_loadFailed ? s.workbenchErrorIo : _error) case final error?)
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_outcome case final outcome?)
              Semantics(liveRegion: true, child: Text(outcome)),
            if (_loadFailed)
              TextButton(onPressed: _reload, child: Text(s.actionRetry))
            else if (items == null)
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
                          [
                            if (present)
                              '${formatClock(m.start)} – ${formatClock(m.end)}'
                            else
                              s.workbenchMissing,
                            if (m.note.isNotEmpty) m.note,
                          ].join('\n'),
                        ),
                        onTap: present ? () => unawaited(_open(m)) : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (!present)
                              IconButton(
                                tooltip: s.workbenchRelink,
                                onPressed: _deleting
                                    ? null
                                    : () => unawaited(_relink(m)),
                                icon: const Icon(Icons.link),
                              ),
                            IconButton(
                              tooltip: s.workbenchDelete,
                              onPressed: _deleting
                                  ? null
                                  : () => unawaited(_delete(m)),
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

String workbenchWavError(S s, WavError? error) => switch (error) {
  WavError.notRiff || WavError.notWave => s.workbenchErrorNotWav,
  WavError.unsupportedFormat ||
  WavError.unsupportedBitDepth => s.workbenchErrorFormat,
  WavError.unsupportedChannels => s.workbenchErrorChannels,
  WavError.unsupportedRate => s.workbenchErrorRate,
  WavError.tooLarge => s.workbenchErrorTooLarge,
  WavError.tooLong => s.workbenchErrorTooLong,
  WavError.missingFmt ||
  WavError.missingData ||
  WavError.truncated ||
  null => s.workbenchErrorDamaged,
};
