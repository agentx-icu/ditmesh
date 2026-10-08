import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  group('TrainerSettings', () {
    test('defaults', () {
      const s = TrainerSettings();
      expect(s.characterWpm, 20);
      expect(s.farnsworthWpm, 8);
      expect(s.toneHz, 700);
      expect(s.sessionLengthChars, 50);
      expect(s.sessionLengthSeconds, isNull);
      expect(s.isFarnsworth, isTrue);
    });

    test('toTiming maps wpm fields', () {
      // Only the constructor fields are asserted; MorseTiming's derived
      // getters may still be unimplemented in morse_core.
      final t = const TrainerSettings().toTiming();
      expect(t.wpm, 20);
      expect(t.farnsworthWpm, 8);
      expect(t.isFarnsworth, isTrue);

      final plain = const TrainerSettings(farnsworthWpm: null).toTiming();
      expect(plain.wpm, 20);
      expect(plain.farnsworthWpm, isNull);
      expect(plain.isFarnsworth, isFalse);

      final fast = const TrainerSettings(
        characterWpm: 15,
        farnsworthWpm: 20,
      ).toTiming();
      expect(fast.isFarnsworth, isFalse);
    });

    test('JSON round trip including nulls', () {
      const s = TrainerSettings(
        characterWpm: 25,
        farnsworthWpm: null,
        toneHz: 600,
        sessionLengthChars: 80,
        sessionLengthSeconds: 120,
        groupSize: 4,
      );
      final back = TrainerSettings.fromJson(s.toJson());
      expect(back, s);
      expect(back.hashCode, s.hashCode);
      expect(back.farnsworthWpm, isNull);
    });

    test('fromJson falls back to defaults for missing keys', () {
      final s = TrainerSettings.fromJson(<String, Object?>{'toneHz': 550});
      expect(s.toneHz, 550);
      expect(s.characterWpm, 20);
      expect(s.farnsworthWpm, 8);
      expect(s.sessionLengthSeconds, isNull);
    });

    test('copyWith clears', () {
      const s = TrainerSettings(sessionLengthSeconds: 60);
      final c = s.copyWith(
        clearFarnsworth: true,
        clearSessionLengthSeconds: true,
      );
      expect(c.farnsworthWpm, isNull);
      expect(c.sessionLengthSeconds, isNull);
      expect(s.copyWith(characterWpm: 30).characterWpm, 30);
    });
  });
}
