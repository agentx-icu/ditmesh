import 'dart:async';

import 'package:flutter/material.dart';

import '../../i18n/l10n_extension.dart';
import 'tool_page.dart';

/// UTC and local time, ticking once a second. Logs and QSLs use UTC.
///
/// [now] is injectable so tests can pin the clock.
class UtcClockTool extends StatefulWidget {
  const UtcClockTool({super.key, this.now = DateTime.now});

  final DateTime Function() now;

  @override
  State<UtcClockTool> createState() => _UtcClockToolState();
}

class _UtcClockToolState extends State<UtcClockTool> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final local = widget.now().toLocal();
    final utc = local.toUtc();
    return ToolPage(
      title: s.toolsClockTitle,
      children: <Widget>[
        ToolSection(
          children: <Widget>[
            ResultRow(
              label: s.toolsClockUtc,
              value: '${formatTime(utc)}Z',
              emphasize: true,
            ),
            ResultRow(label: '', value: formatDate(utc)),
            const Divider(height: 24),
            ResultRow(label: s.toolsClockLocal, value: formatTime(local)),
            ResultRow(
              label: formatOffset(local.timeZoneOffset),
              value: formatDate(local),
            ),
          ],
        ),
        Text(s.toolsClockNote, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

String _two(int v) => v.toString().padLeft(2, '0');

/// `14:05:09`.
String formatTime(DateTime t) =>
    '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

/// ISO date, `2026-10-02`.
String formatDate(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${_two(t.month)}-${_two(t.day)}';

/// `UTC+8`, `UTC-3:30`, `UTC+0`.
String formatOffset(Duration offset) {
  final sign = offset.isNegative ? '-' : '+';
  final minutes = offset.inMinutes.abs();
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? 'UTC$sign$h' : 'UTC$sign$h:${_two(m)}';
}
