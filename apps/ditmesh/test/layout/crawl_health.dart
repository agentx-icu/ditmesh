import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Non-layout failures are fatal too: a missing destination cannot prove layout.
final class CrawlHealth {
  CrawlHealth({required this.scene});
  final String Function() scene;
  final List<String> other = [];

  void record(Object error, StackTrace stack) =>
      other.add('[${scene()}] $error\n$stack');

  /// Collect framework and stray async errors while preserving body failures.
  Future<void> capture(
    Future<void> Function() body, {
    void Function(FlutterErrorDetails)? onFlutterError,
  }) async {
    final previous = FlutterError.onError;
    FlutterError.onError =
        onFlutterError ??
        (details) =>
            record(details.exception, details.stack ?? StackTrace.current);
    final done = Completer<void>();
    try {
      runZonedGuarded(
        () =>
            unawaited(body().then(done.complete, onError: done.completeError)),
        record,
      );
      await done.future;
    } finally {
      FlutterError.onError = previous;
    }
  }

  void checkTree(WidgetTester tester) {
    for (final widget in tester.widgetList<ErrorWidget>(
      find.byType(ErrorWidget),
    )) {
      record('visible ErrorWidget: ${widget.message}', StackTrace.current);
    }
  }

  void requireHealthy() {
    if (other.isNotEmpty) {
      fail(
        '${other.toSet().length} non-layout failure(s):\n${other.toSet().join('\n')}',
      );
    }
  }
}

/// Drain real file work between frames, then finish finite route animations.
/// Animated indicators may remain, but errors and actual targets are checked.
Future<void> settleLayout(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  });
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
  } on FlutterError catch (error) {
    if (!error.message.startsWith('pumpAndSettle timed out')) rethrow;
  }
}
