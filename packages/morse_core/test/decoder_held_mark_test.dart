import 'package:morse_core/morse_core.dart';
import 'package:test/test.dart';

void main() {
  const dit = Duration(milliseconds: 60);

  MorseDecoder decoder() =>
      MorseDecoder(config: const DecoderConfig(initialDit: dit));

  test('clearText drops a held mark so the next dit decodes as E', () {
    final d = decoder()..keyDown(Duration.zero);
    d.clearText();
    expect(d.isKeyDown, isFalse);
    d
      ..keyDown(const Duration(seconds: 1))
      ..keyUp(const Duration(seconds: 1) + dit);
    expect(d.flush(), 'E');
  });

  test('cancelMark drops a held mark but keeps the decoded text', () {
    final d = decoder()
      ..keyDown(Duration.zero)
      ..keyUp(dit)
      ..tick(const Duration(milliseconds: 300))
      ..keyDown(const Duration(milliseconds: 400));
    d.cancelMark();
    expect(d.isKeyDown, isFalse);
    expect(d.text.trim(), 'E');
    d
      ..keyDown(const Duration(milliseconds: 500))
      ..keyUp(const Duration(milliseconds: 500) + dit);
    expect(d.flush().replaceAll(' ', ''), 'EE');
  });
}
