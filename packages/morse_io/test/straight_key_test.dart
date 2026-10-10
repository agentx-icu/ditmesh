import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';

const _ms = Duration(milliseconds: 1);

void main() {
  late FakeClock clock;
  late RecordingSink sink;
  late RecordingKeyTarget target;
  late StraightKey key;

  setUp(() {
    clock = FakeClock();
    sink = RecordingSink(clock: clock);
    target = RecordingKeyTarget();
    key = StraightKey(target: target, sink: sink);
  });

  tearDown(() => key.dispose());

  test('press / release forward timestamps and toggle the sink', () {
    final seen = <MorseKeyEvent>[];
    key.events.listen(seen.add);

    key.press(_ms * 5);
    expect(key.isDown, isTrue);
    expect(sink.isOn, isTrue);
    expect(target.log, <(bool, int)>[(true, 5)]);

    key.release(_ms * 95);
    expect(key.isDown, isFalse);
    expect(sink.isOn, isFalse);
    expect(target.log, <(bool, int)>[(true, 5), (false, 95)]);
    expect(seen, <MorseKeyEvent>[
      MorseKeyEvent.down(_ms * 5),
      MorseKeyEvent.up(_ms * 95),
    ]);
  });

  test('sink is keyed before the decoder is told', () {
    clock.advance(_ms * 7);
    key.press(clock.now());
    // Sink recorded at the same instant means it ran synchronously within
    // press(); order inside press() is sink first by construction.
    expect(sink.log.single, (true, 7));
    expect(target.log.single, (true, 7));
  });

  test('redundant transitions are ignored', () {
    key
      ..press(_ms * 1)
      ..press(_ms * 2)
      ..release(_ms * 3)
      ..release(_ms * 4);
    expect(target.log, <(bool, int)>[(true, 1), (false, 3)]);
    expect(sink.events.length, 2);
  });

  test(
    'dispose while down silences the sink without a decoder key-up',
    () async {
      key.press(_ms * 1);
      await key.dispose();
      expect(sink.isOn, isFalse);
      expect(target.log, <(bool, int)>[(true, 1)]);
      key = StraightKey(target: target); // so tearDown has something to dispose
    },
  );

  test('works without a sink', () {
    final silent = StraightKey(target: target);
    silent
      ..press(_ms * 1)
      ..release(_ms * 2);
    expect(target.log, <(bool, int)>[(true, 1), (false, 2)]);
  });
}
