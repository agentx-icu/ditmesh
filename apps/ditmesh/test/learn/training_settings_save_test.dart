import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/training/training_settings_store.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/ui/learn/settings/training_settings_screen.dart';

import 'helpers/fake_playback.dart';
import 'helpers/l10n.dart';

final class _ControlledSettingsStore implements TrainingSettingsStore {
  _ControlledSettingsStore(this.saved);

  TrainingSettings saved;
  bool fail = true;
  bool controlled = false;
  final pending = <Completer<void>>[];

  @override
  Future<TrainingSettings?> load() async => saved;

  @override
  Future<void> save(TrainingSettings settings) async {
    if (controlled) {
      final wait = Completer<void>();
      pending.add(wait);
      await wait.future;
    }
    if (fail) throw StateError('simulated disk full');
    saved = settings;
  }

  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets('an older failed save does not replace the newer draft', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = _ControlledSettingsStore(TrainingSettings.defaults)
      ..controlled = true
      ..fail = false;
    final controller = TrainingController(
      progressStore: InMemoryTrainerStore(),
      settingsStore: store,
    );
    await controller.load();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      l10nApp(
        home: TrainingSettingsScreen(
          controller: controller,
          playback: FakeLearnPlaybackFactory(),
          hapticAvailability: () async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final toggle = find.ancestor(
      of: find.text(en.learnSound),
      matching: find.byType(SwitchListTile),
    );
    final errors = <Object>[];
    runZonedGuarded(
      () => tester.widget<SwitchListTile>(toggle).onChanged!(false),
      (error, stack) => errors.add(error),
    );
    await tester.pump();
    runZonedGuarded(
      () => tester.widget<SwitchListTile>(toggle).onChanged!(true),
      (error, stack) => errors.add(error),
    );
    await tester.pump();
    store.pending.first.completeError(StateError('first write failed'));
    await tester.pumpAndSettle();
    expect(errors, isEmpty);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect(controller.settings.soundEnabled, isTrue);
    expect(store.pending, hasLength(2));
    store.pending.last.complete();
    await tester.pumpAndSettle();
    expect(store.saved.soundEnabled, isTrue);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
  });

  testWidgets(
    'failed output save restores the UI and playback to saved settings',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final store = _ControlledSettingsStore(
        const TrainingSettings(hapticEnabled: true),
      );
      final controller = TrainingController(
        progressStore: InMemoryTrainerStore(),
        settingsStore: store,
      );
      await controller.load();
      addTearDown(controller.dispose);
      final playback = FakeLearnPlaybackFactory();
      await tester.pumpWidget(
        l10nApp(
          home: TrainingSettingsScreen(
            controller: controller,
            playback: playback,
            hapticAvailability: () async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final toggle = find.ancestor(
        of: find.text(en.learnHaptic),
        matching: find.byType(SwitchListTile),
      );
      final errors = <Object>[];
      runZonedGuarded(
        () => tester.widget<SwitchListTile>(toggle).onChanged!(false),
        (error, stack) => errors.add(error),
      );
      await tester.pumpAndSettle();
      expect(
        errors,
        isEmpty,
        reason: 'failed persistence is handled on screen',
      );
      expect(controller.settings.hapticEnabled, isTrue);
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(en.learnSettingsSaveFailed), findsOneWidget);
      await tester.tap(find.byTooltip(en.learnPlaySample));
      await tester.pump();
      expect(playback.created.single.hapticEnabled, isTrue);

      store.fail = false;
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(controller.settings.hapticEnabled, isFalse);
      expect(store.saved.hapticEnabled, isFalse);
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      await tester.tap(find.byTooltip(en.learnPlaySample));
      await tester.pump();
      expect(playback.created.last.hapticEnabled, isFalse);
    },
  );
}
