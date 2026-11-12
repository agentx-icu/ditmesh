import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// File reads and decoder workers run outside fake async. Wait for their
/// observable result instead of spending a fixed number of test frames.
Future<void> waitForWorkbench(
  WidgetTester tester,
  Finder finder, {
  bool absent = false,
  bool enabled = false,
}) => waitForWorkbenchCondition(
  tester,
  () {
    final matches = finder.evaluate();
    if (absent) return matches.isEmpty;
    if (matches.isEmpty) return false;
    if (!enabled) return true;
    final button = matches.single.widget;
    return button is ButtonStyleButton && button.onPressed != null;
  },
  description:
      '${absent
          ? 'remove'
          : enabled
          ? 'enable'
          : 'show'} $finder',
);

Future<void> waitForWorkbenchCondition(
  WidgetTester tester,
  bool Function() ready, {
  required String description,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final elapsed = Stopwatch()..start();
  do {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    if (ready()) {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 50),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 1),
      );
      return;
    }
  } while (elapsed.elapsed < timeout);
  fail('Workbench did not $description within $timeout.');
}
