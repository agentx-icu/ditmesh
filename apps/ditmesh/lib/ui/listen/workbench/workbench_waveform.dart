import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:morse_dsp/morse_dsp.dart';

import '../../../i18n/l10n_extension.dart';
import '../../common/field_label.dart';
import 'workbench_controller.dart';

String formatClock(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  final ms = (d.inMilliseconds % 1000) ~/ 10;
  return '$m:${s.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
}

/// Simplified min/max waveform with draggable selection handles, plus
/// accessible start/end time fields (precise dragging is not required on
/// a phone).
class WorkbenchWaveform extends StatefulWidget {
  const WorkbenchWaveform({super.key, required this.controller});

  final WorkbenchController controller;

  @override
  State<WorkbenchWaveform> createState() => _WorkbenchWaveformState();
}

class _WorkbenchWaveformState extends State<WorkbenchWaveform> {
  final _startField = TextEditingController();
  final _endField = TextEditingController();
  bool _startEdited = false;
  bool _endEdited = false;
  int? _dragAnchor;

  WorkbenchController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_sync);
    _sync();
  }

  @override
  void didUpdateWidget(WorkbenchWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, _c)) {
      oldWidget.controller.removeListener(_sync);
      _c.addListener(_sync);
      _startEdited = false;
      _endEdited = false;
      _dragAnchor = null;
      _sync();
    }
  }

  String _displayTime(int frame) =>
      (_c.positionOf(frame).inMilliseconds / 1000).toStringAsFixed(2);

  void _sync() {
    final a = _displayTime(_c.start);
    final b = _displayTime(_c.end);
    if (!_startEdited && _startField.text != a) _startField.text = a;
    if (!_endEdited && _endField.text != b) _endField.text = b;
  }

  int? _frameAtSeconds(String text) {
    final info = _c.info;
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (info == null || value == null) return null;
    final seconds = value.clamp(0, info.frameCount / info.sampleRate);
    return (seconds * info.sampleRate).round();
  }

  void _commitTime(String text, {required bool start}) {
    if (start) {
      if (!_startEdited) return;
      _startEdited = false;
    } else {
      if (!_endEdited) return;
      _endEdited = false;
    }
    final frame = _frameAtSeconds(text);
    if (frame != null) {
      _c.setSelection(start ? frame : _c.start, start ? _c.end : frame);
    }
    _sync();
  }

  int _frameAtX(double x, double width) {
    final total = _c.info!.frameCount;
    return (x / width * total).round().clamp(0, total);
  }

  @override
  void dispose() {
    _c.removeListener(_sync);
    _startField.dispose();
    _endField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final info = _c.info;
    if (info == null) return const SizedBox.shrink();
    final total = math.max(1, info.frameCount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onHorizontalDragStart: (d) {
                final f = _frameAtX(d.localPosition.dx, width);
                final start = _c.start;
                final end = _c.end;
                _dragAnchor = (f - start).abs() <= (f - end).abs()
                    ? end
                    : start;
              },
              onHorizontalDragUpdate: (d) {
                final anchor = _dragAnchor;
                if (anchor == null) return;
                final f = _frameAtX(d.localPosition.dx, width);
                _c.setSelection(anchor, f);
              },
              onHorizontalDragEnd: (_) => _dragAnchor = null,
              onHorizontalDragCancel: () => _dragAnchor = null,
              child: ExcludeSemantics(
                child: CustomPaint(
                  key: const ValueKey('workbench-waveform'),
                  size: Size(width, 96),
                  painter: _WavePainter(
                    envelope: _c.waveform,
                    start: _c.start / total,
                    end: _c.end / total,
                    wave: theme.colorScheme.primary,
                    selection: theme.colorScheme.primaryContainer,
                    handle: theme.colorScheme.tertiary,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _timeField(
              s.workbenchStart,
              const ValueKey('workbench-start'),
              start: true,
            ),
            _timeField(
              s.workbenchEnd,
              const ValueKey('workbench-end'),
              start: false,
            ),
            TextButton(
              onPressed: () => _c.setSelection(0, info.frameCount),
              child: Text(s.workbenchSelectAll),
            ),
          ],
        ),
      ],
    );
  }

  Widget _timeField(String label, Key key, {required bool start}) {
    final controller = start ? _startField : _endField;
    return SizedBox(
      width: 132,
      child: TextField(
        key: key,
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: InputDecoration(
          label: FieldLabel(label),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (text) {
          final edited = text != _displayTime(start ? _c.start : _c.end);
          if (start) {
            _startEdited = edited;
          } else {
            _endEdited = edited;
          }
        },
        onSubmitted: (text) => _commitTime(text, start: start),
        onTapOutside: (_) => _commitTime(controller.text, start: start),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.envelope,
    required this.start,
    required this.end,
    required this.wave,
    required this.selection,
    required this.handle,
  });

  final WaveformEnvelope? envelope;
  final double start;
  final double end;
  final Color wave;
  final Color selection;
  final Color handle;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Rect.fromLTRB(start * w, 0, end * w, h),
      Paint()..color = selection,
    );
    final env = envelope;
    if (env != null && env.length > 0) {
      final paint = Paint()
        ..color = wave
        ..strokeWidth = math.max(1, w / env.length);
      for (var i = 0; i < env.length; i++) {
        final x = (i + 0.5) / env.length * w;
        final top = h / 2 - env.maxs[i] * h / 2;
        final bottom = h / 2 - env.mins[i] * h / 2;
        canvas.drawLine(
          Offset(x, top),
          Offset(x, math.max(bottom, top + 1)),
          paint,
        );
      }
    }
    final hp = Paint()
      ..color = handle
      ..strokeWidth = 3;
    for (final x in <double>[start * w, end * w]) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), hp);
      canvas.drawCircle(Offset(x, h - 6), 6, hp);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.envelope != envelope || old.start != start || old.end != end;
}
