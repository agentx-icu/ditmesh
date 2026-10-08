import 'package:morse_core/morse_core.dart';
import 'package:test/test.dart';

void main() {
  group('MorseElement', () {
    test('on is true only for marks', () {
      const Duration d = Duration(milliseconds: 60);
      expect(const MorseElement(MorseElementKind.dit, d).on, isTrue);
      expect(const MorseElement(MorseElementKind.dah, d).on, isTrue);
      expect(const MorseElement(MorseElementKind.intraGap, d).on, isFalse);
      expect(const MorseElement(MorseElementKind.charGap, d).on, isFalse);
      expect(const MorseElement(MorseElementKind.wordGap, d).on, isFalse);
    });

    test('equality and hash follow kind and duration', () {
      const MorseElement a = MorseElement(MorseElementKind.dit, Duration(milliseconds: 60));
      const MorseElement b = MorseElement(MorseElementKind.dit, Duration(milliseconds: 60));
      const MorseElement c = MorseElement(MorseElementKind.dah, Duration(milliseconds: 60));
      const MorseElement d = MorseElement(MorseElementKind.dit, Duration(milliseconds: 61));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a, isNot(d));
      final List<MorseElement> all = <MorseElement>[a, b, c, d];
      expect(all.toSet(), hasLength(3));
    });

    test('toString names the kind and the length in ms', () {
      expect(
        const MorseElement(MorseElementKind.charGap, Duration(milliseconds: 180)).toString(),
        'MorseElement(charGap, 180ms)',
      );
    });
  });
}
