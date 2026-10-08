import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Share-sheet anchor guard. iPadOS presents the share sheet as a popover
/// that needs a source rect; `share_plus` centres it when none is given, so
/// the popover floats detached from the control the user tapped. Every share
/// call under `lib/` must therefore pass `sharePositionOrigin` (the real ones
/// do: backup export, LAN node info, learning-material export). The value may
/// be a `Rect?` resolved at runtime from the tapped widget, but never the
/// literal `null`, and the pre-`ShareParams` API (`Share.share*`), whose
/// origin is an easily forgotten optional, is not used at all.
///
/// Runs with the package root (apps/ditmesh) as the working directory.
void main() {
  final List<File> sources =
      Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !_isGenerated(f.path))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('no legacy Share.share* call', () {
    final legacy = RegExp(
      r'\bShare\.(share|shareXFiles|shareUri|shareFiles|shareWithResult)\(',
    );
    for (final file in sources) {
      expect(
        legacy.hasMatch(file.readAsStringSync()),
        isFalse,
        reason:
            '${file.path}: use SharePlus.instance.share(ShareParams(..., '
            'sharePositionOrigin: ...))',
      );
    }
  });

  test('every SharePlus.instance.share call passes sharePositionOrigin', () {
    final call = RegExp(r'SharePlus\s*\.\s*instance\s*\.\s*share\s*\(');
    int calls = 0;
    for (final file in sources) {
      final source = file.readAsStringSync();
      for (final m in call.allMatches(source)) {
        calls++;
        final args = _balancedArguments(source, m.end - 1);
        final where = '${file.path}:${_lineOf(source, m.start)}';
        expect(
          args,
          contains('sharePositionOrigin:'),
          reason: '$where: share call without sharePositionOrigin',
        );
        expect(
          RegExp(r'sharePositionOrigin:\s*null\b').hasMatch(args),
          isFalse,
          reason: '$where: sharePositionOrigin is the literal null',
        );
      }
    }
    // The guard must be looking at real code: the app has share actions.
    expect(calls, greaterThanOrEqualTo(1));
  });
}

bool _isGenerated(String path) =>
    path.contains('/generated/') ||
    path.contains(r'\generated\') ||
    path.endsWith('.g.dart');

/// Text between the parenthesis at [open] and its matching close, skipping
/// string literals so a `)` inside one does not end the scan early.
String _balancedArguments(String source, int open) {
  assert(source[open] == '(');
  int depth = 0;
  String? quote;
  for (int i = open; i < source.length; i++) {
    final c = source[i];
    if (quote != null) {
      if (c == r'\') {
        i++;
        continue;
      }
      if (c == quote) quote = null;
      continue;
    }
    if (c == "'" || c == '"') {
      quote = c;
      continue;
    }
    if (c == '(') depth++;
    if (c == ')' && --depth == 0) return source.substring(open + 1, i);
  }
  throw StateError('unbalanced parentheses at offset $open');
}

int _lineOf(String source, int offset) =>
    '\n'.allMatches(source.substring(0, offset)).length + 1;
