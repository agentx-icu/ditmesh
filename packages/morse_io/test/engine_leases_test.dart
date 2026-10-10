import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';

/// Stands in for the SoLoud singleton: counts starts and stops.
final class _Engine {
  bool running = false;
  int inits = 0;
  int deinits = 0;
  Completer<void>? initGate;
  Object? initError;

  late final EngineLeases leases = EngineLeases(
    isInitialized: () => running,
    deinit: () {
      deinits++;
      running = false;
    },
  );

  Future<void> init() async {
    inits++;
    final gate = initGate;
    if (gate != null) await gate.future;
    final error = initError;
    if (error != null) throw error;
    running = true;
  }
}

void main() {
  late _Engine engine;

  setUp(() => engine = _Engine());

  test(
    'overlapping holders: the engine stops only with the last lease',
    () async {
      await engine.leases.acquire(engine.init); // A
      await engine.leases.acquire(engine.init); // B
      expect(engine.inits, 1);
      await engine.leases.release(); // A leaves while B still plays
      expect(engine.running, isTrue);
      expect(engine.deinits, 0);
      await engine.leases.release(); // B
      expect(engine.running, isFalse);
      expect(engine.deinits, 1);
    },
  );

  test('concurrent acquires start the engine exactly once', () async {
    engine.initGate = Completer<void>();
    final a = engine.leases.acquire(engine.init);
    final b = engine.leases.acquire(engine.init);
    await pumpEventQueue();
    engine.initGate!.complete();
    await Future.wait(<Future<void>>[a, b]);
    expect(engine.inits, 1);
    expect(engine.leases.count, 2);
  });

  test('a release queued behind a pending init waits for it', () async {
    await engine.leases.acquire(engine.init);
    await engine.leases.release();
    engine.initGate = Completer<void>();
    final acquire = engine.leases.acquire(engine.init);
    final release = engine.leases.release();
    await pumpEventQueue();
    expect(engine.deinits, 1, reason: 'nothing torn down mid-init');
    engine.initGate!.complete();
    await Future.wait(<Future<void>>[acquire, release]);
    expect(engine.running, isFalse);
    expect(engine.deinits, 2);
  });

  test('an engine somebody else started is never shut down', () async {
    engine.running = true;
    await engine.leases.acquire(engine.init);
    await engine.leases.release();
    expect(engine.inits, 0);
    expect(engine.deinits, 0);
    expect(engine.running, isTrue);
  });

  test('extra releases do not underflow', () async {
    await engine.leases.release();
    await engine.leases.acquire(engine.init);
    await engine.leases.release();
    await engine.leases.release();
    expect(engine.leases.count, 0);
    expect(engine.deinits, 1);
    await engine.leases.acquire(engine.init);
    expect(engine.leases.count, 1);
    expect(engine.running, isTrue);
  });

  test('a failed init takes no lease and does not block the queue', () async {
    engine.initError = StateError('no audio device');
    await expectLater(engine.leases.acquire(engine.init), throwsStateError);
    expect(engine.leases.count, 0);
    engine.initError = null;
    await engine.leases.acquire(engine.init);
    expect(engine.leases.count, 1);
    expect(engine.running, isTrue);
  });

  test('an engine stopped behind our back is restarted on acquire', () async {
    await engine.leases.acquire(engine.init);
    engine.running = false; // someone called SoLoud.deinit directly
    await engine.leases.acquire(engine.init);
    expect(engine.inits, 2);
    expect(engine.running, isTrue);
  });
}
