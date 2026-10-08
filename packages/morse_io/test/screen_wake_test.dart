import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';

/// A platform toggle whose calls complete only when the test says so, like
/// wakelock_plus on Linux, which stores its inhibit handle only after an
/// asynchronous DBus reply.
final class _DelayedToggle {
  final List<String> log = <String>[];
  final List<Completer<void>> pending = <Completer<void>>[];
  bool? state;

  Future<void> call(bool on) async {
    log.add('${on ? 'enable' : 'disable'} start');
    final done = Completer<void>();
    pending.add(done);
    await done.future;
    state = on;
    log.add('${on ? 'enable' : 'disable'} done');
  }

  void completeNext() => pending.removeAt(0).complete();
}

void main() {
  test('a disable issued while an enable is in flight runs after it', () async {
    // Regression: the disable found no inhibit handle yet, then the enable
    // completed and the display stayed awake for good.
    final toggle = _DelayedToggle();
    final wake = SerializedScreenWake(toggle.call);
    final enabling = wake.keepOn(true);
    await pumpEventQueue();
    final disabling = wake.keepOn(false);
    await pumpEventQueue();
    expect(toggle.log, <String>['enable start'], reason: 'disable must wait');
    toggle.completeNext();
    await pumpEventQueue();
    expect(toggle.log, <String>[
      'enable start',
      'enable done',
      'disable start',
    ]);
    toggle.completeNext();
    await Future.wait(<Future<void>>[enabling, disabling]);
    expect(toggle.state, isFalse);
  });

  test(
    'requests queued behind an in-flight toggle coalesce to the last',
    () async {
      final toggle = _DelayedToggle();
      final wake = SerializedScreenWake(toggle.call);
      final first = wake.keepOn(true);
      await pumpEventQueue();
      final second = wake.keepOn(false);
      final third = wake.keepOn(true);
      toggle.completeNext();
      await Future.wait(<Future<void>>[first, second, third]);
      expect(toggle.log, <String>['enable start', 'enable done']);
      expect(toggle.state, isTrue);
      final off = wake.keepOn(false);
      await pumpEventQueue();
      toggle.completeNext();
      await off;
      expect(toggle.state, isFalse);
      await wake.keepOn(false);
      expect(toggle.log.length, 4, reason: 'already off: no platform call');
    },
  );

  test(
    'a failing toggle is swallowed and the next request still applies',
    () async {
      final calls = <bool>[];
      var fail = true;
      final wake = SerializedScreenWake((on) async {
        calls.add(on);
        if (fail) {
          throw StateError('no plugin');
        }
      });
      await wake.keepOn(true);
      fail = false;
      await wake.keepOn(true);
      expect(calls, <bool>[true, true], reason: 'failure leaves state unknown');
    },
  );

  test('a toggle that throws synchronously does not wedge the queue', () {
    final calls = <bool>[];
    final wake = SerializedScreenWake((on) {
      calls.add(on);
      throw StateError('sync');
    });
    return wake.keepOn(true).then((_) async {
      await wake.keepOn(true);
      expect(calls, <bool>[true, true]);
    });
  });
}
