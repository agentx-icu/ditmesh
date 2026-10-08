import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';

const _ms = Duration(milliseconds: 1);

// dit 100, dah 300, gap 100 -- explicit values, no MorseTiming getters.
const KeyerTiming _timing = KeyerTiming(
  dit: Duration(milliseconds: 100),
  dah: Duration(milliseconds: 300),
  gap: Duration(milliseconds: 100),
);

void main() {
  late FakeClock clock;
  late RecordingSink sink;
  late RecordingKeyTarget target;

  IambicKeyer keyer(IambicMode mode) => IambicKeyer(
        timing: _timing,
        target: target,
        sink: sink,
        clock: clock,
        mode: mode,
      );

  setUp(() {
    clock = FakeClock();
    sink = RecordingSink(clock: clock);
    target = RecordingKeyTarget();
  });

  test('single dit paddle held repeats dits with PARIS spacing', () async {
    final k = keyer(IambicMode.b);
    addTearDown(k.dispose);
    k.ditPaddle(true, clock.now());
    clock.advance(_ms * 350);
    k.ditPaddle(false, clock.now()); // during the second dit
    clock.advance(_ms * 1000);

    expect(target.log, <(bool, int)>[
      (true, 0),
      (false, 100),
      (true, 200),
      (false, 300), // element in flight completes, then stops
    ]);
    expect(sink.log, target.log);
    expect(k.isKeying, isFalse);
    expect(clock.pendingTimers, 0);
  });

  test('finish keeps the element in flight whole and keys nothing more',
      () async {
    final k = keyer(IambicMode.b);
    addTearDown(k.dispose);
    k.dahPaddle(true, clock.now()); // held: would repeat dahs
    clock.advance(_ms * 60);
    k.finish();
    // The dah reports its full 300 ms, not the 60 ms that had passed.
    expect(target.log, <(bool, int)>[(true, 0), (false, 300)]);
    expect(k.isKeying, isFalse);
    clock.advance(_ms * 2000);
    expect(target.log, hasLength(2));
    expect(clock.pendingTimers, 0);
  });

  test('squeezing both paddles alternates dit / dah', () async {
    final k = keyer(IambicMode.b);
    addTearDown(k.dispose);
    k.ditPaddle(true, clock.now());
    k.dahPaddle(true, clock.now());
    clock.advance(_ms * 1150);

    // dit 0-100, gap, dah 200-500, gap, dit 600-700, gap, dah 800-1100 ...
    expect(target.log.take(8), <(bool, int)>[
      (true, 0),
      (false, 100),
      (true, 200),
      (false, 500),
      (true, 600),
      (false, 700),
      (true, 800),
      (false, 1100),
    ]);
    expect(k.currentElement, isNull); // in the gap 1100-1200 at t = 1150
    clock.advance(_ms * 50);
    expect(k.currentElement, MorseElementKind.dit); // next dit at t = 1200
    k.reset(clock.now());
  });

  test('dah first then squeeze starts with dah', () async {
    final k = keyer(IambicMode.b);
    addTearDown(k.dispose);
    k.dahPaddle(true, clock.now());
    clock.advance(_ms * 50);
    k.ditPaddle(true, clock.now());
    clock.advance(_ms * 500);
    expect(target.log, <(bool, int)>[
      (true, 0),
      (false, 300),
      (true, 400),
      (false, 500),
    ]);
    k.reset(clock.now());
  });

  test('mode B: releasing both during a dah sends one extra dit', () async {
    final k = keyer(IambicMode.b);
    addTearDown(k.dispose);
    k.ditPaddle(true, clock.now());
    clock.advance(_ms * 10);
    k.dahPaddle(true, clock.now());
    clock.advance(_ms * 290); // t = 300: inside the dah (200-500)
    expect(k.currentElement, MorseElementKind.dah);
    k.ditPaddle(false, clock.now());
    k.dahPaddle(false, clock.now());
    clock.advance(_ms * 2000);

    expect(target.log, <(bool, int)>[
      (true, 0),
      (false, 100),
      (true, 200),
      (false, 500),
      (true, 600), // the latched extra dit
      (false, 700),
    ]);
    expect(k.isKeying, isFalse);
  });

  test('mode A: releasing both during a dah stops after the dah', () async {
    final k = keyer(IambicMode.a);
    addTearDown(k.dispose);
    k.ditPaddle(true, clock.now());
    clock.advance(_ms * 10);
    k.dahPaddle(true, clock.now());
    clock.advance(_ms * 290);
    k.ditPaddle(false, clock.now());
    k.dahPaddle(false, clock.now());
    clock.advance(_ms * 2000);

    expect(target.log, <(bool, int)>[
      (true, 0),
      (false, 100),
      (true, 200),
      (false, 500),
    ]);
    expect(k.isKeying, isFalse);
  });

  test('mode A keeps single-paddle memory (a tap during a dah is sent)',
      () async {
    final k = keyer(IambicMode.a);
    addTearDown(k.dispose);
    k.dahPaddle(true, clock.now()); // dah 0-300
    clock.advance(_ms * 50);
    k.ditPaddle(true, clock.now());
    clock.advance(_ms * 20);
    k.ditPaddle(false, clock.now()); // dah still held: not a squeeze release
    clock.advance(_ms * 330); // t = 400: gap ended, dit should start
    expect(target.log.last, (true, 400));
    k.reset(clock.now());
  });

  test('emitted events and timing setter', () async {
    final k = keyer(IambicMode.b);
    addTearDown(k.dispose);
    final seen = <MorseKeyEvent>[];
    k.events.listen(seen.add);
    k.ditPaddle(true, clock.now());
    clock.advance(_ms * 150);
    k.timing = KeyerTiming.standard(_ms * 50); // speed up mid-stream
    clock.advance(_ms * 50); // t = 200: next dit at new 50 ms length
    clock.advance(_ms * 50);
    k.ditPaddle(false, clock.now());
    clock.advance(_ms * 500);

    expect(seen, <MorseKeyEvent>[
      MorseKeyEvent.down(Duration.zero),
      MorseKeyEvent.up(_ms * 100),
      MorseKeyEvent.down(_ms * 200),
      MorseKeyEvent.up(_ms * 250),
    ]);
  });

  test('KeyerTiming helpers', () {
    expect(KeyerTiming.standard(_ms * 60),
        const KeyerTiming(dit: Duration(milliseconds: 60), dah: Duration(milliseconds: 180), gap: Duration(milliseconds: 60)));
    expect(KeyerTiming.fromWpm(20).dit, _ms * 60);
    expect(_timing.durationOf(MorseElementKind.wordGap), _ms * 700);
  });
}
