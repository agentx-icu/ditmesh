import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/file_trainer_store.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/ui/learn/learn_home.dart';
import 'package:ditmesh/ui/learn/learn_home_widgets.dart';
import 'package:ditmesh/ui/learn/learn_scope.dart';
import 'package:ditmesh/ui/learn/settings/training_settings_screen.dart';
import 'package:ditmesh/ui/pages/learn_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'helpers/fake_playback.dart';
import 'helpers/l10n.dart';
import 'helpers/stub_identity_service.dart';
import 'helpers/test_controller.dart';

Future<void> _setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<TestTraining> _pumpHome(
  WidgetTester tester, {
  required Size size,
  TrainerProgress? progress,
}) async {
  await _setSize(tester, size);
  final t = await TestTraining.create(progress: progress);
  addTearDown(t.controller.dispose);
  await tester.pumpWidget(
    l10nApp(
      home: LearnHome(
        controller: t.controller,
        playback: FakeLearnPlaybackFactory(),
        subtitle: LearnPage.description(en),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return t;
}

void main() {
  group('LearnHome', () {
    testWidgets('shows lesson state from the store', (tester) async {
      final score = SessionScore.evaluate('KMRS KMRS', 'KMRS KMRS');
      final progress = TrainerProgress(
        currentLesson: 3,
        dailyGoalChars: 100,
      ).recordSession(score, now: kTestNow);
      await _pumpHome(tester, size: const Size(390, 844), progress: progress);

      expect(find.text(en.learnLessonOf(3, 42)), findsOneWidget);
      expect(find.text(en.learnCharsLearned(4)), findsOneWidget);
      for (final c in <String>['K', 'M', 'R', 'S']) {
        expect(
          find.descendant(
            of: find.byType(LearnedCharChip),
            matching: find.text(c),
          ),
          findsOneWidget,
        );
      }
      final newest = tester.widgetList<LearnedCharChip>(
        find.byType(LearnedCharChip),
      );
      expect(newest.where((c) => c.isNewest).map((c) => c.char), <String>['S']);
      // Lesson n teaches order[0..n]; lesson 3 = K M R S, so S is newest.
      expect(find.text(en.learnNewestCharIs('S')), findsOneWidget);
      expect(find.text(en.learnDailyGoalProgress(8, 100)), findsOneWidget);
      expect(find.text(en.learnStreakDays(1)), findsOneWidget);
      expect(find.text(en.learnContinueLesson), findsOneWidget);
      expect(find.text(en.learnReceivePractice), findsOneWidget);
      expect(find.text(en.learnSendPractice), findsOneWidget);
      expect(find.text(en.learnReviewDue), findsOneWidget);
      expect(find.text(LearnPage.description(en)), findsOneWidget);
    });

    testWidgets('lays out one column on a phone and two on a desktop', (
      tester,
    ) async {
      await _pumpHome(tester, size: const Size(390, 844));
      final phoneCard = tester.getTopLeft(find.byType(LessonCard));
      final phoneActions = tester.getTopLeft(find.byType(QuickActions));
      expect(phoneActions.dy, greaterThan(phoneCard.dy));
      expect(phoneActions.dx, phoneCard.dx);

      await tester.pumpWidget(const SizedBox());
      await _pumpHome(tester, size: const Size(1280, 800));
      final deskCard = tester.getTopLeft(find.byType(LessonCard));
      final deskActions = tester.getTopLeft(find.byType(QuickActions));
      expect(deskActions.dy, deskCard.dy);
      expect(deskActions.dx, greaterThan(deskCard.dx));
    });

    testWidgets('settings gear opens the training settings route', (
      tester,
    ) async {
      await _pumpHome(tester, size: const Size(390, 844));
      await tester.tap(find.byTooltip(en.learnSettings));
      await tester.pumpAndSettle();
      expect(find.byType(TrainingSettingsScreen), findsOneWidget);
      expect(find.text(en.learnSettingsTitle), findsOneWidget);
    });
  });

  group('LearnPage', () {
    testWidgets('without an IdentityService shows the identity placeholder', (
      tester,
    ) async {
      await _setSize(tester, const Size(390, 844));
      await tester.pumpWidget(
        l10nApp(home: LearnPage(playback: FakeLearnPlaybackFactory())),
      );
      await tester.pumpAndSettle();
      expect(find.text(en.learnIdentityRequired), findsOneWidget);
      expect(find.text(LearnPage.description(en)), findsOneWidget);
      expect(find.byType(LearnHome), findsNothing);
    });

    // The default wiring is covered in two deterministic halves rather than
    // one widget test: real file I/O racing the widget tester's fake clock
    // is flaky on a loaded box, and an exception inside `runAsync` is only
    // reported, never propagated, so such a test hangs instead of failing.
    test('controllerForIdentity reads <dataDirectory>/training/progress.json',
        () async {
      final tmp = await Directory.systemTemp.createTemp('ditmesh_learn_');
      addTearDown(() => tmp.delete(recursive: true));
      await FileTrainerStore.inDataDirectory(
        tmp.path,
      ).save(TrainerProgress(currentLesson: 5));
      final identity = StubIdentityService(tmp.path);

      final controller = await LearnScope.controllerForIdentity(identity);
      addTearDown(controller.dispose);

      expect(identity.dataDirectoryCalls, 1);
      expect(controller.isLoaded, isTrue);
      expect(controller.loadError, isNull);
      expect(controller.currentLesson, 5);
      // Settings had never been saved: defaults, and saving lands beside
      // the progress file.
      expect(controller.settings, TrainingSettings.defaults);
      await controller.updateSettings(
        const TrainingSettings(keyerMode: KeyerMode.straight),
      );
      expect(
        await File(p.join(tmp.path, 'training', 'settings.json')).exists(),
        isTrue,
      );
    });

    testWidgets('the Provider-supplied IdentityService reaches the scope', (
      tester,
    ) async {
      await _setSize(tester, const Size(390, 844));
      final identity = StubIdentityService('/unused');
      IdentityService? seen;
      final t = await TestTraining.create();
      await tester.pumpWidget(
        Provider<IdentityService>.value(
          value: identity,
          child: l10nApp(
            home: LearnPage(
              playback: FakeLearnPlaybackFactory(),
              controllerFactory: (context) async {
                seen = context.read<IdentityService>();
                return t.controller;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(seen, same(identity));
      expect(find.byType(LearnHome), findsOneWidget);
    });

    testWidgets('controllerFactory bypasses the identity lookup', (
      tester,
    ) async {
      await _setSize(tester, const Size(390, 844));
      final t = await TestTraining.create(
        progress: TrainerProgress(currentLesson: 2),
      );
      await tester.pumpWidget(
        l10nApp(
          home: LearnPage(
            playback: FakeLearnPlaybackFactory(),
            controllerFactory: (_) async => t.controller,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(en.learnLessonOf(2, 42)), findsOneWidget);
      expect(
        tester.widget<LearnHome>(find.byType(LearnHome)).controller,
        same(t.controller),
      );
      // A controller obtained from a factory stays owned by whoever backs
      // the factory (the app-wide TrainingControllerHost shares one instance
      // with the settings route), so dropping the page must NOT dispose it.
      await tester.pumpWidget(const SizedBox());
      expect(
        () => t.controller.addListener(() {}),
        returnsNormally,
        reason: 'factory-provided controllers are not disposed by the scope',
      );
      t.controller.dispose();
    });
  });

  test('TrainingController defaults do not need Flutter', () async {
    final t = await TestTraining.create();
    expect(t.controller, isA<TrainingController>());
  });
}
