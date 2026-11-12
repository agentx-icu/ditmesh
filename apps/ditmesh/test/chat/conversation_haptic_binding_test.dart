import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/training/training_controller_host.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/training/training_settings_store.dart';
import 'package:ditmesh/ui/chat/conversation_haptic_binding.dart';
import 'package:ditmesh/ui/chat/morse_playback_controller.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

final class _Identity implements IdentityService {
  _Identity(this.current);
  @override
  Identity? current;
  final changes = StreamController<Identity?>.broadcast(sync: true);
  @override
  Stream<Identity?> get identityChanges => changes.stream;
  void switchTo(String key) {
    current = Identity(toxId: key.padRight(76, '0'), displayName: key);
    changes.add(current);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final class _Haptics implements HapticApi {
  final calls = <String>[];
  @override
  Future<bool> supportsContinuousVibration() async => true;
  @override
  Future<void> heavyImpact() async => calls.add('impact');
  @override
  Future<void> vibrate(Duration duration) async => calls.add('vibrate');
  @override
  Future<void> cancel() async => calls.add('cancel');
}

Future<TrainingController> _controller(bool enabled) async {
  final c = TrainingController(
    progressStore: InMemoryTrainerStore(),
    settingsStore: InMemoryTrainingSettingsStore(
      TrainingSettings(hapticEnabled: enabled),
    ),
  );
  await c.load();
  return c;
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Identity identity;
  late FakeClock clock;
  late RecordingSink sound;
  late _Haptics haptics;
  late MorsePlaybackController playback;
  late List<ConversationHapticBinding> bindings;
  late List<TrainingControllerHost> hosts;

  setUp(() {
    identity = _Identity(
      Identity(toxId: 'A'.padRight(76, '0'), displayName: 'A'),
    );
    clock = FakeClock();
    sound = RecordingSink(clock: clock);
    haptics = _Haptics();
    playback = MorsePlaybackController(
      sink: sound,
      haptic: HapticSink(
        api: haptics,
        platformOverride: TargetPlatform.android,
      ),
      clock: clock,
    );
    bindings = [];
    hosts = [];
  });
  tearDown(() async {
    for (final binding in bindings) {
      binding.dispose();
    }
    playback.dispose();
    for (final host in hosts) {
      await host.dispose();
    }
    await identity.changes.close();
  });

  ConversationHapticBinding bind({TrainingControllerHost? host}) {
    final binding = ConversationHapticBinding(
      identity: identity,
      playback: playback,
      training: host,
    );
    bindings.add(binding);
    return binding;
  }

  test('disabling keying sidetone preserves enabled vibration', () async {
    final release = playback.bindHaptics(() => true);
    await playback.prepare();
    final key = (playback.keyingSink as LiveKeyingSink).withSidetone(
      () => false,
    );
    key.on();
    await _settle();
    expect(sound.isOn, isFalse);
    expect(haptics.calls, contains('vibrate'));
    key.off();
    release();
  });

  TrainingControllerHost host(Future<TrainingController> Function() factory) {
    final host = TrainingControllerHost(identity, factory: (_) => factory());
    hosts.add(host);
    return host;
  }

  test(
    'missing training host keeps keying and playback vibration off',
    () async {
      await bind().start();
      await playback.prepare();
      playback.keyingSink.on();
      expect(sound.isOn, isTrue);
      expect(haptics.calls, isEmpty);
      playback.keyingSink.off();
      clock.advance(MorsePlaybackController.keyingHoldoff);
      await playback.play('bubble', 'E', const MorseTiming(wpm: 20));
      expect(sound.isOn, isTrue);
      expect(haptics.calls, isEmpty);
    },
  );

  test(
    'saved enable applies to both outputs; disabling cancels only vibration',
    () async {
      final c = await _controller(true);
      await bind(host: host(() async => c)).start();
      await playback.prepare();
      playback.keyingSink.on();
      expect(haptics.calls, ['vibrate']);
      await c.updateSettings(c.settings.copyWith(hapticEnabled: false));
      expect(haptics.calls, ['vibrate', 'cancel']);
      expect(sound.isOn, isTrue, reason: 'the audio preference did not change');
      playback.keyingSink.off();
      clock.advance(MorsePlaybackController.keyingHoldoff);
      await c.updateSettings(c.settings.copyWith(hapticEnabled: true));
      await playback.play('bubble', 'T', const MorseTiming(wpm: 20));
      expect(haptics.calls.last, 'vibrate');
      await c.updateSettings(c.settings.copyWith(hapticEnabled: false));
      expect(haptics.calls.last, 'cancel');
      expect(sound.isOn, isTrue);
      clock.advance(const Duration(seconds: 1));
      final before = haptics.calls.where((call) => call == 'vibrate').length;
      await playback.play('bubble2', 'E', const MorseTiming(wpm: 20));
      expect(
        haptics.calls.where((call) => call == 'vibrate'),
        hasLength(before),
      );
    },
  );

  test(
    'identity switch cancels the pulse before the next settings load',
    () async {
      final c = await _controller(true);
      final next = Completer<TrainingController>();
      var loads = 0;
      final binding = bind(
        host: host(() => ++loads == 1 ? Future.value(c) : next.future),
      );
      await binding.start();
      await playback.prepare();
      playback.keyingSink.on();
      expect(haptics.calls.last, 'vibrate');
      identity.switchTo('B');
      expect(haptics.calls.last, 'cancel');
      expect(playback.hapticEnabled, isFalse);
      final b = await _controller(false);
      next.complete(b);
      await _settle();
      playback.keyingSink.off();
      playback.keyingSink.on();
      expect(haptics.calls.where((call) => call == 'vibrate'), hasLength(1));
    },
  );

  test(
    'late settings for the previous identity cannot enable vibration',
    () async {
      final pending = <Completer<TrainingController>>[];
      final binding = bind(
        host: host(() {
          final result = Completer<TrainingController>();
          pending.add(result);
          return result.future;
        }),
      );
      final starting = binding.start();
      expect(playback.hapticEnabled, isFalse);
      identity.switchTo('B');
      expect(pending, hasLength(2));
      pending.first.complete(await _controller(true));
      await starting;
      expect(playback.hapticEnabled, isFalse);
      pending.last.complete(await _controller(false));
      await _settle();
      expect(playback.hapticEnabled, isFalse);
    },
  );

  test(
    'disposal cancels vibration and ignores a late enabled settings load',
    () async {
      final ready = Completer<TrainingController>();
      final binding = bind(host: host(() => ready.future));
      final starting = binding.start();
      binding.dispose();
      ready.complete(await _controller(true));
      await starting;
      await playback.prepare();
      playback.keyingSink.on();
      expect(haptics.calls, isEmpty);
      expect(sound.isOn, isTrue);
    },
  );

  test('closing an enabled binding cancels its current pulse', () async {
    final c = await _controller(true);
    final binding = bind(host: host(() async => c));
    await binding.start();
    await playback.prepare();
    playback.keyingSink.on();
    binding.dispose();
    expect(haptics.calls, ['vibrate', 'cancel']);
    expect(playback.hapticEnabled, isFalse);
  });

  test('releasing an old binding preserves the latest owner', () async {
    final old = playback.bindHaptics(() => true);
    final current = playback.bindHaptics(() => true);
    old();
    expect(playback.hapticEnabled, isTrue);
    current();
    expect(playback.hapticEnabled, isFalse);
  });
}
