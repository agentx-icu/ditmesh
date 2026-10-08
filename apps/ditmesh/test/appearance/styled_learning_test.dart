import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/ui/appearance/radio_mascot.dart';
import 'package:ditmesh/ui/appearance/ui_style.dart';
import 'package:ditmesh/ui/learn/learn_home.dart';
import 'package:ditmesh/ui/learn/learn_home_widgets.dart';
import 'package:ditmesh/ui/theme.dart';

import '../learn/helpers/fake_playback.dart';
import '../learn/helpers/l10n.dart';
import '../learn/helpers/test_controller.dart';

void main() {
  testWidgets('five characters also fit a narrow 320 pixel phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final training = await TestTraining.create(
      progress: TrainerProgress(currentLesson: 4),
    );
    addTearDown(training.controller.dispose);
    await tester.pumpWidget(
      l10nApp(
        theme: DitmeshTheme.light(style: UiStyle.cartoon),
        home: LearnHome(
          controller: training.controller,
          playback: FakeLearnPlaybackFactory(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<LearnedCharChip>(find.byType(LearnedCharChip))
          .map(
            (chip) => tester
                .getTopLeft(find.widgetWithText(LearnedCharChip, chip.char))
                .dy,
          )
          .toSet(),
      hasLength(1),
    );
  });
  for (final style in UiStyle.values.where((s) => s != UiStyle.classic)) {
    testWidgets('$style keeps the full course readable with large phone text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final training = await TestTraining.create();
      addTearDown(training.controller.dispose);
      await training.controller.setLesson(training.controller.lessonCount);
      final theme = DitmeshTheme.light(style: style);
      await tester.pumpWidget(
        l10nApp(
          theme: theme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 740),
              textScaler: TextScaler.linear(1.8),
            ),
            child: LearnHome(
              controller: training.controller,
              playback: FakeLearnPlaybackFactory(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(LearnedCharChip),
        findsNWidgets(training.controller.learnedChars.length),
      );
      for (final chip in find.byType(LearnedCharChip).evaluate()) {
        // The widest test-font glyph plus padding and the selected border
        // must fit inside a tile at the user's selected text scale.
        final character = (chip.widget as LearnedCharChip).char;
        final fontSize = tester
            .widget<Text>(
              find.descendant(
                of: find.byWidget(chip.widget),
                matching: find.text(character),
              ),
            )
            .style!
            .fontSize!;
        expect(
          tester.getSize(find.byWidget(chip.widget)).width,
          greaterThanOrEqualTo(fontSize * 1.8 + 20),
        );
      }
      final button = find.widgetWithText(FilledButton, en.learnContinueLesson);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expect(button.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets('$style places five character tiles and Continue on phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final training = await TestTraining.create(
        progress: TrainerProgress(currentLesson: 4),
      );
      addTearDown(training.controller.dispose);
      await tester.pumpWidget(
        l10nApp(
          theme: DitmeshTheme.light(style: style),
          home: LearnHome(
            controller: training.controller,
            playback: FakeLearnPlaybackFactory(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final positions = tester
          .widgetList<LearnedCharChip>(find.byType(LearnedCharChip))
          .map(
            (chip) => tester.getTopLeft(
              find.widgetWithText(LearnedCharChip, chip.char),
            ),
          )
          .toList();
      expect(positions.map((p) => p.dy).toSet(), hasLength(1));
      final button = find.widgetWithText(FilledButton, en.learnContinueLesson);
      expect(tester.getRect(button).bottom, lessThan(600));
      expect(find.text('..-'), findsOneWidget);
      if (style == UiStyle.cartoon) {
        expect(find.byType(RadioMascot), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
