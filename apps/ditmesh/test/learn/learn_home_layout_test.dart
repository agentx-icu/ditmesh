import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/ui/appearance/ui_style.dart';
import 'package:ditmesh/ui/learn/learn_home.dart';
import 'package:ditmesh/ui/learn/learn_home_widgets.dart';
import 'package:ditmesh/ui/theme.dart';

import 'helpers/fake_playback.dart';
import 'helpers/l10n.dart';
import 'helpers/test_controller.dart';

Future<TestTraining> _pumpClassic(
  WidgetTester tester, {
  required Size size,
  required double scale,
  required int lesson,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final training = await TestTraining.create(
    progress: TrainerProgress(currentLesson: lesson),
  );
  addTearDown(training.controller.dispose);
  await tester.pumpWidget(
    l10nApp(
      theme: DitmeshTheme.light(style: UiStyle.classic),
      home: LearnHome(
        controller: training.controller,
        playback: FakeLearnPlaybackFactory(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return training;
}

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(900, 800),
  ]) {
    for (final scale in [1.0, 1.8]) {
      testWidgets(
        'Classic lesson action precedes compact chips at $size/$scale',
        (tester) async {
          await _pumpClassic(tester, size: size, scale: scale, lesson: 4);
          final chips = find.byType(LearnedCharChip);
          final first = tester.getRect(chips.at(0));
          final second = tester.getRect(chips.at(1));
          final action = tester.getRect(find.text(en.learnContinueLesson));
          expect(first.width, lessThan(80));
          expect(second.top, first.top);
          expect(action.bottom, lessThan(first.top));
          expect(action.bottom, lessThan(size.height));
          expect(find.text(en.learnContinueLesson), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'long Classic learned set shows newest and expands all characters',
    (tester) async {
      final training = await _pumpClassic(
        tester,
        size: const Size(320, 640),
        scale: 1.8,
        lesson: 42,
      );
      final learned = training.controller.learnedChars;
      expect(learned.length, greaterThan(10));
      var chips = tester.widgetList<LearnedCharChip>(
        find.byType(LearnedCharChip),
      );
      expect(chips.length, lessThanOrEqualTo(10));
      expect(
        chips.any((chip) => chip.char == training.controller.newestChar),
        isTrue,
      );
      final newestChip = find.widgetWithText(
        LearnedCharChip,
        training.controller.newestChar,
      );
      expect(tester.getRect(newestChip).bottom, lessThanOrEqualTo(640));
      expect(newestChip.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(find.text(en.learnContinueLesson)).bottom,
        lessThan(640),
      );
      final toggle = find.byKey(const ValueKey('learned-chars-toggle'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      chips = tester.widgetList<LearnedCharChip>(find.byType(LearnedCharChip));
      expect(chips.map((chip) => chip.char), learned);
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.byType(LearnedCharChip), findsNWidgets(10));
      expect(tester.takeException(), isNull);
    },
  );
}
