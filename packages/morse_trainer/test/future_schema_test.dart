import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  test('future trainer schema fails before interpreting fields', () {
    expect(() => TrainerProgress.fromJson({'version': 2}), throwsFormatException);
  });
  test('future telegraph schema never becomes an empty writable model', () {
    expect(() => TelegraphRecallStats.fromJson({'v': 2}), throwsFormatException);
  });
}
