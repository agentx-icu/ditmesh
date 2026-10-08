import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/training_controller.dart';
import '../../../training/training_settings.dart';
import 'material_file_gateway.dart';

/// Audio export of a material (functional spec §9.2): PCM WAV, 16-bit mono
/// 48 kHz at the chosen character / effective speed and tone. Longer
/// material is split into explicit parts of at most ten minutes. The answer
/// text is only added when the learner asks for it before sharing.
Future<void> showMaterialExportSheet(
  BuildContext context, {
  required TrainingController controller,
  required TrainingMaterial material,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _ExportSheet(controller: controller, material: material),
);

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({required this.controller, required this.material});

  final TrainingController controller;
  final TrainingMaterial material;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  late double _char = widget.controller.trainerSettings.characterWpm;
  late double _eff = widget.controller.trainerSettings.isFarnsworth
      ? widget.controller.trainerSettings.farnsworthWpm!
      : _char;
  late double _tone = widget.controller.trainerSettings.toneHz;
  bool _withAnswer = false;
  bool _busy = false;
  String? _status;

  MorseTiming get _timing =>
      MorseTiming(wpm: _char, farnsworthWpm: _eff < _char ? _eff : null);

  String get _text => widget.material.normalizedItems.join(' ');

  List<String> get _parts {
    try {
      return MorseWavExport.segments(_text, _timing);
    } on WavExportException {
      return const <String>[];
    }
  }

  Future<void> _export() async {
    final s = context.s;
    final gateway = MaterialFileGateway.of(context);
    final parts = _parts;
    if (parts.isEmpty) {
      setState(() => _status = s.materialsExportFailed);
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
    });
    final base = safeFileName(widget.material.title);
    var saved = 0;
    try {
      for (var i = 0; i < parts.length; i++) {
        final suffix = parts.length == 1 ? '' : '-${i + 1}';
        final bytes = MorseWavExport.renderText(
          parts[i],
          _timing,
          toneHz: _tone,
        );
        // Never report a zero-byte file as a successful export.
        if (bytes.length <= 44) throw StateError('empty audio');
        if (!await gateway.save(
          bytes,
          fileName: '$base$suffix.wav',
          mimeType: 'audio/wav',
        )) {
          break;
        }
        saved++;
        if (_withAnswer &&
            !await gateway.save(
              Uint8List.fromList(utf8.encode(parts[i])),
              fileName: '$base$suffix.txt',
              mimeType: 'text/plain',
            )) {
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = saved == 0 ? null : s.materialsWavExported(saved);
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = s.materialsExportFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final parts = _parts.length;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              s.materialsExportWav,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(s.materialsWavCharSpeed(_char.round())),
            Slider(
              value: _char,
              min: TrainingSettings.minCharacterWpm,
              max: TrainingSettings.maxCharacterWpm,
              divisions: 30,
              label: '${_char.round()}',
              onChanged: (v) => setState(() {
                _char = v.roundToDouble();
                if (_eff > _char) _eff = _char;
              }),
            ),
            Text(s.materialsWavEffSpeed(_eff.round())),
            Slider(
              value: _eff,
              min: TrainingSettings.minFarnsworthWpm,
              max: _char,
              divisions: (_char - TrainingSettings.minFarnsworthWpm)
                  .round()
                  .clamp(1, 40),
              label: '${_eff.round()}',
              onChanged: (v) => setState(() => _eff = v.roundToDouble()),
            ),
            Text(s.materialsWavTone(_tone.round())),
            Slider(
              value: _tone,
              min: TrainingSettings.minToneHz,
              max: TrainingSettings.maxToneHz,
              divisions: 12,
              label: '${_tone.round()}',
              onChanged: (v) => setState(() => _tone = v.roundToDouble()),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _withAnswer,
              onChanged: (v) => setState(() => _withAnswer = v),
              title: Text(s.materialsWavWithAnswer),
            ),
            Text(
              parts <= 1 ? s.materialsWavFormat : s.materialsWavParts(parts),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_status != null) ...[
              const SizedBox(height: 8),
              Text(_status!, key: const ValueKey('wav-status')),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('wav-export'),
              onPressed: _busy || parts == 0 ? null : _export,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(s.materialsExportWav),
            ),
          ],
        ),
      ),
    );
  }
}
