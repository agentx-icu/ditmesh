import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';
import 'package:ditmesh/keying/profile_keyer.dart';

void main() {
  test('sidetone disabled keeps non-audio feedback without a tone member', () {
    final flash = RecordingSink(clock: FakeClock());
    final haptic = RecordingSink(clock: FakeClock());
    final echo = ProfileKeyer.gateSidetone(
      CompositeSink([flash, haptic]),
      null,
      () => false,
    );
    echo.on();
    expect(flash.isOn, isTrue);
    expect(haptic.isOn, isTrue);
    echo.off();
    expect(flash.isOn, isFalse);
    expect(haptic.isOn, isFalse);
  });

  test('a bare audio sink still follows the sidetone switch', () {
    final audio = RecordingSink(clock: FakeClock());
    var enabled = false;
    final echo = ProfileKeyer.gateSidetone(audio, null, () => enabled);
    echo.on();
    expect(audio.isOn, isFalse);
    enabled = true;
    echo.on();
    expect(audio.isOn, isTrue);
    enabled = false;
    echo.off();
    expect(audio.isOn, isFalse);
  });

  test('an implicit device tone is gated separately from its flash', () async {
    final api = _AudioApi();
    final tone = SidetoneSink(api: api);
    final flash = RecordingSink(clock: FakeClock());
    var enabled = false;
    final echo = ProfileKeyer.gateSidetone(
      CompositeSink([tone, flash]),
      null,
      () => enabled,
    );
    await echo.prepare();
    addTearDown(echo.dispose);
    echo.on();
    expect(tone.isOn, isFalse);
    expect(flash.isOn, isTrue);
    enabled = true;
    echo.on();
    expect(tone.isOn, isTrue);
    enabled = false;
    echo.off();
    expect(tone.isOn, isFalse);
    expect(flash.isOn, isFalse);
  });
}

final class _AudioApi implements SoloudApi {
  @override
  bool isInitialized = false;

  @override
  Future<void> init() async => isInitialized = true;

  @override
  Future<SidetoneSource> loadSineWaveform() async => const SidetoneSource(1);

  @override
  void setWaveformFrequency(SidetoneSource source, double hz) {}

  @override
  SidetoneVoice playLooping(SidetoneSource source, {required double volume}) =>
      const SidetoneVoice(1);

  @override
  void setVolume(SidetoneVoice voice, double volume) {}

  @override
  void fadeVolume(SidetoneVoice voice, double to, Duration over) {}

  @override
  void resumeVoice(SidetoneVoice voice) {}

  @override
  Future<void> stop(SidetoneVoice voice) async {}

  @override
  Future<void> disposeSource(SidetoneSource source) async {}

  @override
  Future<void> deinit() async => isInitialized = false;
}
