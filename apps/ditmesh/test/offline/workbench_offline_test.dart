import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_features.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/ui/listen/workbench/workbench_screen.dart';
import 'package:provider/provider.dart';

import '../learn/helpers/l10n.dart';
import '../learn/helpers/test_controller.dart';
import '../listen/workbench_support.dart';

/// Offline build: the workbench's training profile failing to open is a
/// retryable storage error, not a silent "scored, not recorded" mode.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('wbo_'));
  tearDown(() => root.deleteSync(recursive: true));

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 2)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('a training failure shows the storage error; retry recovers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final t = await TestTraining.create();
    var fail = true;
    var attempts = 0;
    Future<TrainingController> training() async {
      attempts++;
      if (fail) throw StateError('disk unavailable');
      return t.controller;
    }

    await tester.pumpWidget(
      Provider<AppFeatures>.value(
        value: const AppFeatures(chat: false),
        child: l10nApp(
          home: WorkbenchScreen(
            player: FakeClipPlayer(),
            profileRoot: () async => root.path,
            training: training,
          ),
        ),
      ),
    );
    await settle(tester);
    expect(find.text(en.learnStorageUnavailable), findsOneWidget);

    fail = false;
    await tester.tap(find.byKey(const ValueKey('workbench-retry')));
    await settle(tester);
    expect(attempts, 2);
    expect(find.text(en.learnStorageUnavailable), findsNothing);
    expect(find.text(en.workbenchBackupNote), findsOneWidget);
  });
}
