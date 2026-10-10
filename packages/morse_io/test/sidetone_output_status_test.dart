import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';

final class _OutputApi implements SoloudApi {
  Object? resumeError;
  Object? playError;
  Object? fadeError;
  @override
  bool isInitialized = false;
  @override
  Future<void> init() async => isInitialized = true;
  @override
  Future<SidetoneSource> loadSineWaveform() async => const SidetoneSource(1);
  @override
  void setWaveformFrequency(SidetoneSource source, double hz) {}
  @override
  SidetoneVoice playLooping(SidetoneSource source, {required double volume}) {
    if (playError case final error?) throw error;
    return const SidetoneVoice(1);
  }

  @override
  void resumeVoice(SidetoneVoice voice) {
    if (resumeError case final error?) throw error;
  }

  @override
  void fadeVolume(SidetoneVoice voice, double to, Duration over) {
    if (fadeError case final error?) throw error;
  }

  @override
  void setVolume(SidetoneVoice voice, double volume) {}
  @override
  Future<void> stop(SidetoneVoice voice) async {}
  @override
  Future<void> disposeSource(SidetoneSource source) async {}
  @override
  Future<void> deinit() async => isInitialized = false;
}

void main() {
  test(
    'refused output exposes the actual API error without changing retry keying',
    () async {
      final api = _OutputApi();
      final sink = SidetoneSink(api: api);
      await sink.prepare();
      api.resumeError = StateError('resume refused');
      api.playError = StateError('new voice refused');
      sink.on();
      expect(sink.isOn, isFalse);
      expect(sink.lastOutputError, same(api.playError));
      expect(sink.lastOutputStackTrace, isNotNull);
      api.resumeError = null;
      api.playError = null;
      sink.on();
      expect(sink.isOn, isTrue);
      expect(sink.lastOutputError, isNull);
      await sink.dispose();
    },
  );

  test('a rejected fade does not claim that the sidetone sounded', () async {
    final api = _OutputApi();
    final sink = SidetoneSink(api: api);
    await sink.prepare();
    api.fadeError = StateError('fade refused');
    expect(sink.on, throwsA(same(api.fadeError)));
    expect(sink.isOn, isFalse);
    expect(sink.lastOutputError, same(api.fadeError));
    api.fadeError = null;
    sink.on();
    expect(sink.isOn, isTrue);
    expect(sink.lastOutputError, isNull);
    await sink.dispose();
  });
}
