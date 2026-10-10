// Regression tests for the 2026-10-03 Learn review (Codex findings on the
// app's training layer, receive drill and training settings).
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart' show FlashOverlay;
import 'package:morse_io/testing.dart' show FakeClock, RecordingSink;
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/chat_copy_session.dart';
import 'package:ditmesh/training/receive_session.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/training/training_settings_store.dart';
import 'package:ditmesh/ui/learn/learn_playback.dart';
import 'package:ditmesh/ui/learn/receive/answer_keypad.dart';
import 'package:ditmesh/ui/learn/receive/receive_drill_screen.dart';
import 'package:ditmesh/ui/learn/settings/training_settings_screen.dart';
import 'package:path/path.dart' as p;

import 'helpers/fake_playback.dart';
import 'helpers/l10n.dart';
import 'helpers/test_controller.dart';

/// Fails the first [failures] saves, then behaves like the in-memory store.
final class _FlakyStore implements TrainerStore {
  _FlakyStore(this.failures);

  int failures;
  final InMemoryTrainerStore inner = InMemoryTrainerStore();

  @override
  Future<TrainerProgress?> load() => inner.load();

  @override
  Future<void> save(TrainerProgress progress) async {
    if (failures > 0) {
      failures--;
      throw const FileSystemException('disk full');
    }
    await inner.save(progress);
  }

  @override
  Future<void> clear() => inner.clear();
}

Future<(TrainingController, _FlakyStore)> _flakyController(int failures) async {
  final store = _FlakyStore(failures);
  final c = TrainingController(
    progressStore: store,
    settingsStore: InMemoryTrainingSettingsStore(kShortSettings),
    now: () => kTestNow,
    random: Random(1),
  );
  await c.load();
  return (c, store);
}

/// [LearnPlaybackFactory] whose creations finish only when the test says so.
final class _GatedPlaybackFactory implements LearnPlaybackFactory {
  final FakeClock clock = FakeClock();
  late final RecordingSink sink = RecordingSink(clock: clock);

  /// Settings of every [create] call, oldest first.
  final List<TrainingSettings> requested = <TrainingSettings>[];
  final List<Completer<LearnPlayback>> _pending = <Completer<LearnPlayback>>[];

  /// Index of every created bundle whose dispose ran.
  final Set<int> disposed = <int>{};

  @override
  Future<LearnPlayback> create(TrainingSettings settings) {
    requested.add(settings);
    final c = Completer<LearnPlayback>();
    _pending.add(c);
    return c.future;
  }

  /// Finishes creation [index] with a bundle using [flash].
  void complete(int index, {ValueListenable<bool>? flash}) {
    _pending[index].complete(
      LearnPlayback(
        sink: sink,
        clock: clock,
        flash: flash,
        dispose: () async => disposed.add(index),
      ),
    );
  }
}

void _setPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('a failed progress save', () {
    test('still returns the outcome and retrying credits it once', () async {
      final (c, _) = await _flakyController(1);
      addTearDown(c.dispose);
      final session = c.startFocusSession(<String>['K', 'M'])!;
      while (!session.isComplete) {
        session.submit(session.currentDrill.text);
      }
      final outcome = await c.recordReceiveSession(session);
      expect(outcome.saved, isFalse);
      expect(c.progress.history, hasLength(1));

      expect(await c.retryProgressSave(), isTrue);
      expect(c.progress.history, hasLength(1));
      expect(c.progress.sessionCount, 1);
    });
  });

  group('settings file bounds', () {
    late Directory tmp;
    setUp(() async => tmp = await Directory.systemTemp.createTemp('mcq_'));
    tearDown(() => tmp.delete(recursive: true));

    test('absurd speeds and tones are clamped to the slider ranges', () async {
      final file = File(p.join(tmp.path, 'settings.json'));
      final store = FileTrainingSettingsStore(file);
      await store.save(
        const TrainingSettings(
          trainer: TrainerSettings(
            characterWpm: 1e300,
            farnsworthWpm: 1,
            toneHz: 20000,
            sessionLengthChars: 100000,
          ),
        ),
      );
      final t = (await store.load())!.trainer;
      expect(t.characterWpm, TrainingSettings.maxCharacterWpm);
      expect(t.farnsworthWpm, TrainingSettings.minFarnsworthWpm);
      expect(t.toneHz, TrainingSettings.maxToneHz);
      expect(t.sessionLengthChars, TrainingSettings.maxSessionChars);
      expect(t.toTiming().dit, greaterThan(Duration.zero));
    });
  });

  testWidgets(
    'backgrounding a phone drill stops playback; no auto-play',
    (tester) async {
      _setPhone(tester);
      final t = await TestTraining.create(settings: kShortSettings);
      addTearDown(t.controller.dispose);
      final playback = FakeLearnPlaybackFactory();
      final ReceiveSession session = t.controller.startFocusSession(<String>[
        'K',
        'M',
      ])!;
      await tester.pumpWidget(
        l10nApp(
          home: ReceiveDrillScreen(
            controller: t.controller,
            playback: playback,
            session: session,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(playback.sink.events, isNotEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final before = playback.sink.events.length;
      playback.clock.advance(const Duration(seconds: 30));
      await tester.pump();
      expect(playback.sink.isOn, isFalse);
      expect(playback.sink.events.length, before);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.tap(find.text(en.learnReplay));
      await tester.pump();
      expect(playback.sink.events.length, greaterThan(before));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('keypad keys share rows on a phone', (tester) async {
    _setPhone(tester);
    final chars = KochCourse().order;
    await tester.pumpWidget(
      l10nApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AnswerKeypad(
              chars: chars,
              onChar: (_) {},
              onBackspace: () {},
              onSpace: () {},
            ),
          ),
        ),
      ),
    );
    final k = tester.getRect(find.text('K'));
    final m = tester.getRect(find.text('M'));
    expect(m.top, k.top, reason: 'K and M share the first row');
    final keypad = tester.getSize(find.byType(AnswerKeypad));
    expect(keypad.height, lessThan(844));
  });

  testWidgets('the sample follows the sound switch after it played once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final t = await TestTraining.create();
    addTearDown(t.controller.dispose);
    final playback = FakeLearnPlaybackFactory();
    await tester.pumpWidget(
      l10nApp(
        home: TrainingSettingsScreen(
          controller: t.controller,
          playback: playback,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(en.learnPlaySample));
    await tester.pump();
    expect(playback.created.single.soundEnabled, isTrue);
    playback.clock.advance(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.learnSound));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(en.learnPlaySample));
    await tester.pump();
    expect(playback.created, hasLength(2));
    expect(playback.created.last.soundEnabled, isFalse);
    expect(playback.disposeCalls, 1);
  });

  testWidgets('a sample created for old switches is replaced, never doubled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final t = await TestTraining.create(
      settings: const TrainingSettings(flashEnabled: true),
    );
    addTearDown(t.controller.dispose);
    final playback = _GatedPlaybackFactory();
    await tester.pumpWidget(
      l10nApp(
        home: TrainingSettingsScreen(
          controller: t.controller,
          playback: playback,
        ),
      ),
    );
    await tester.pumpAndSettle();
    IconButton playButton() => tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(en.learnPlaySample),
        matching: find.byType(IconButton),
      ),
    );

    await tester.tap(find.byTooltip(en.learnPlaySample));
    await tester.pump();
    expect(playback.requested, hasLength(1));
    expect(playback.requested.single.soundEnabled, isTrue);

    // Flip the sound off while the first bundle is still being built.
    await tester.tap(find.text(en.learnSound));
    await tester.pump();
    expect(playButton().onPressed, isNull);
    await tester.tap(find.byTooltip(en.learnPlaySample), warnIfMissed: false);
    await tester.pump();
    expect(playback.requested, hasLength(1), reason: 'one creation at a time');

    // The stale bundle is thrown away and rebuilt for the new switches.
    playback.complete(0);
    await tester.pump();
    expect(playback.disposed, <int>{0});
    expect(playback.requested, hasLength(2));
    expect(playback.requested.last.soundEnabled, isFalse);
    expect(playback.requested.last.flashEnabled, isTrue);

    final flash = ValueNotifier<bool>(false);
    addTearDown(flash.dispose);
    playback.complete(1, flash: flash);
    await tester.pump();
    expect(playback.requested, hasLength(2));
    expect(playback.disposed, <int>{0}, reason: 'only bundle 1 is live');
    // Flash-only sample: the overlay is up while it plays.
    expect(playback.sink.events, isNotEmpty);
    expect(playButton().onPressed, isNull, reason: 'still playing');
    expect(find.byType(FlashOverlay), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(playback.disposed, <int>{0, 1});
  });

  test('a haptic-only profile falls back to the flash on desktop', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final playback = await const DevicePlaybackFactory().create(
      const TrainingSettings(soundEnabled: false, hapticEnabled: true),
    );
    addTearDown(playback.dispose);
    expect(playback.flash, isNotNull);
  });
}
