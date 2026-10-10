import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';

const _ms = Duration(milliseconds: 1);

// dit 100 | gap 100 | dah 300 | char gap 300 | dit 100  => total 900 ms
final List<MorseElement> _timeline = <MorseElement>[
  MorseElement(MorseElementKind.dit, _ms * 100),
  MorseElement(MorseElementKind.intraGap, _ms * 100),
  MorseElement(MorseElementKind.dah, _ms * 300),
  MorseElement(MorseElementKind.charGap, _ms * 300),
  MorseElement(MorseElementKind.dit, _ms * 100),
];

void main() {
  late FakeClock clock;
  late RecordingSink sink;
  late MorsePlayer player;
  late List<PlayerEvent> events;

  setUp(() {
    clock = FakeClock();
    sink = RecordingSink(clock: clock);
    player = MorsePlayer(sink: sink, clock: clock);
    events = <PlayerEvent>[];
    player.events.listen(events.add);
  });

  tearDown(() => player.dispose());

  test('starting paused is silent until an explicit resume', () {
    player.play(_timeline, paused: true);
    expect(player.isPlaying, isTrue);
    expect(player.isPaused, isTrue);
    expect(sink.log, isEmpty);
    expect(clock.pendingTimers, 0);
    clock.advance(_ms * 500);
    expect(player.elapsed, Duration.zero);
    player.resume();
    expect(sink.log, [(true, 500)]);
    clock.advance(_ms * 100);
    expect(sink.log.last, (false, 600));
  });

  test('keys the exact on/off sequence with absolute timestamps', () {
    player.play(_timeline);
    expect(player.isPlaying, isTrue);
    expect(sink.log, <(bool, int)>[(true, 0)]);

    clock.advance(_ms * 900);

    expect(sink.log, <(bool, int)>[
      (true, 0),
      (false, 100),
      (true, 200),
      (false, 500),
      (true, 800),
      (false, 900),
    ]);
    expect(player.isPlaying, isFalse);
    expect(player.currentIndex, -1);
    expect(events.whereType<PlayerElementStarted>().map((e) => e.index), <int>[
      0,
      1,
      2,
      3,
      4,
    ]);
    expect(events.last, isA<PlayerCompleted>());
    expect(clock.pendingTimers, 0);
  });

  test('late timer callbacks do not accumulate drift', () {
    final lateClock = FakeClock(timerLatency: _ms * 20);
    final lateSink = RecordingSink(clock: lateClock);
    final latePlayer = MorsePlayer(sink: lateSink, clock: lateClock);
    addTearDown(latePlayer.dispose);

    latePlayer.play(_timeline);
    lateClock.advance(_ms * 1000);

    // Every boundary is exactly one latency late, never n * latency.
    expect(lateSink.log, <(bool, int)>[
      (true, 0),
      (false, 120),
      (true, 220),
      (false, 520),
      (true, 820),
      (false, 920),
    ]);
  });

  test('pause turns the sink off and resume shifts the schedule', () {
    player.play(_timeline);
    clock.advance(_ms * 50);
    player.pause();
    expect(player.isPaused, isTrue);
    expect(sink.isOn, isFalse);
    expect(sink.log.last, (false, 50));

    clock.advance(_ms * 200); // nothing fires while paused
    expect(sink.log.length, 2);

    player.resume(); // t = 250, 50 ms into the first dit remain
    expect(sink.log.last, (true, 250));
    clock.advance(_ms * 50);
    expect(sink.log.last, (false, 300)); // gap starts 200 ms later than nominal
    clock.advance(_ms * 800); // t = 1100 = nominal 900 + 200 ms pause
    expect(sink.log.last, (false, 900 + 200));
    expect(events.last, isA<PlayerCompleted>());
  });

  test('pausing during a gap does not key the sink on resume', () {
    player.play(_timeline);
    clock.advance(_ms * 150); // inside the intra gap
    player.pause();
    final before = sink.log.length;
    clock.advance(_ms * 100);
    player.resume();
    expect(sink.log.length, before, reason: 'gap resume must stay silent');
    clock.advance(_ms * 50); // gap ends at 100 + 100 shift = 300
    expect(sink.log.last, (true, 300));
  });

  test('stop mid-element turns the sink off and emits stopped', () {
    player.play(_timeline);
    clock.advance(_ms * 250); // inside the dah
    expect(sink.isOn, isTrue);

    player.stop();

    expect(sink.isOn, isFalse);
    expect(sink.log.last, (false, 250));
    expect(player.isPlaying, isFalse);
    expect(events.last, isA<PlayerStopped>());
    expect(clock.pendingTimers, 0);

    clock.advance(_ms * 1000);
    expect(sink.log.length, 4, reason: 'no further keying after stop');
  });

  test('play while playing restarts from zero and reports stopped', () {
    player.play(_timeline);
    clock.advance(_ms * 250);
    player.play(_timeline);
    expect(events.whereType<PlayerStopped>().length, 1);
    expect(sink.log.last, (true, 250));
    expect(player.currentIndex, 0);
  });

  test('empty timeline completes immediately', () {
    player.play(const <MorseElement>[]);
    expect(player.isPlaying, isFalse);
    expect(events.single, isA<PlayerCompleted>());
    expect(sink.log, isEmpty);
  });

  test('pause / resume / stop are no-ops when idle', () {
    player
      ..pause()
      ..resume()
      ..stop();
    expect(events, isEmpty);
    expect(sink.log, isEmpty);
  });

  test('CompositeSink fans out to every child', () async {
    final other = RecordingSink(clock: clock);
    final composite = CompositeSink(<MorseSink>[sink, other]);
    await composite.prepare();
    composite.on();
    clock.advance(_ms * 10);
    composite.off();
    await composite.dispose();

    for (final s in <RecordingSink>[sink, other]) {
      expect(s.prepareCalls, 1);
      expect(s.disposeCalls, 1);
      expect(s.log, <(bool, int)>[(true, 0), (false, 10)]);
    }
  });

  group('elapsed', () {
    test('advances with the clock while running', () {
      player.play(_timeline);
      expect(player.totalDuration, _ms * 900);
      expect(player.elapsed, Duration.zero);
      clock.advance(_ms * 250);
      expect(player.elapsed, _ms * 250);
      clock.advance(_ms * 400);
      expect(player.elapsed, _ms * 650);
      expect(player.isPlaying, isTrue);
    });

    test('freezes while paused and continues after resume', () {
      player.play(_timeline);
      clock.advance(_ms * 300);
      player.pause();
      expect(player.elapsed, _ms * 300);
      clock.advance(_ms * 1000);
      expect(player.elapsed, _ms * 300, reason: 'paused time is not elapsed');

      player.resume();
      expect(player.elapsed, _ms * 300);
      clock.advance(_ms * 200);
      expect(player.elapsed, _ms * 500);

      // A second pause/resume cycle shifts the timeline again.
      player.pause();
      clock.advance(_ms * 50);
      expect(player.elapsed, _ms * 500);
      player.resume();
      clock.advance(_ms * 100);
      expect(player.elapsed, _ms * 600);
    });

    test('a paused start counts from zero once resumed', () {
      player.play(_timeline, paused: true);
      clock.advance(_ms * 500);
      expect(player.elapsed, Duration.zero);
      player.resume();
      expect(player.elapsed, Duration.zero);
      clock.advance(_ms * 150);
      expect(player.elapsed, _ms * 150);
    });

    test('is clamped to the total duration while completion is late', () {
      final lateClock = FakeClock(timerLatency: _ms * 50);
      final latePlayer = MorsePlayer(
        sink: RecordingSink(clock: lateClock),
        clock: lateClock,
      );
      addTearDown(latePlayer.dispose);

      latePlayer.play(_timeline);
      // The final boundary is due at 900 ms but fires 50 ms late.
      lateClock.advance(_ms * 930);
      expect(latePlayer.isPlaying, isTrue);
      expect(latePlayer.elapsed, latePlayer.totalDuration);
      expect(latePlayer.elapsed, _ms * 900);

      lateClock.advance(_ms * 20);
      expect(latePlayer.isPlaying, isFalse);
      expect(latePlayer.elapsed, Duration.zero);
    });

    test('returns to zero after completion', () {
      player.play(_timeline);
      clock.advance(_ms * 900);
      expect(events.last, isA<PlayerCompleted>());
      expect(player.elapsed, Duration.zero);
      clock.advance(_ms * 100);
      expect(player.elapsed, Duration.zero);
    });

    test('returns to zero after stop, running or paused', () {
      player.play(_timeline);
      clock.advance(_ms * 250);
      player.stop();
      expect(player.elapsed, Duration.zero);
      clock.advance(_ms * 300);
      expect(player.elapsed, Duration.zero);

      player.play(_timeline);
      clock.advance(_ms * 100);
      player.pause();
      expect(player.elapsed, _ms * 100);
      player.stop();
      expect(player.elapsed, Duration.zero);
    });

    test('restarting from a running timeline counts from zero again', () {
      player.play(_timeline);
      clock.advance(_ms * 400);
      player.play(_timeline);
      expect(player.elapsed, Duration.zero);
      clock.advance(_ms * 50);
      expect(player.elapsed, _ms * 50);
    });
  });
}
