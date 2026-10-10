import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';

void main() {
  test('defaults: space = straight, ctrl left/right = dit/dah', () {
    final b = KeyboardKeyBinding.defaults;
    expect(b.actionFor(LogicalKeyboardKey.space), KeyerAction.straight);
    expect(b.actionFor(LogicalKeyboardKey.controlLeft), KeyerAction.dit);
    expect(b.actionFor(LogicalKeyboardKey.controlRight), KeyerAction.dah);
    expect(b.actionFor(LogicalKeyboardKey.keyA), isNull);
  });

  test('swapped exchanges dit and dah only', () {
    final b = KeyboardKeyBinding.defaults.swapped();
    expect(b.actionFor(LogicalKeyboardKey.controlLeft), KeyerAction.dah);
    expect(b.actionFor(LogicalKeyboardKey.controlRight), KeyerAction.dit);
    expect(b.actionFor(LogicalKeyboardKey.space), KeyerAction.straight);
  });

  test('copyWith replaces one set and keeps the others', () {
    final b = KeyboardKeyBinding.defaults.copyWith(
      dit: <LogicalKeyboardKey>{LogicalKeyboardKey.keyZ},
    );
    expect(b.actionFor(LogicalKeyboardKey.keyZ), KeyerAction.dit);
    expect(b.actionFor(LogicalKeyboardKey.controlLeft), isNull);
    expect(b.actionFor(LogicalKeyboardKey.controlRight), KeyerAction.dah);
  });

  test('actionForEvent ignores repeats', () {
    final b = KeyboardKeyBinding.defaults;
    const down = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.space,
      logicalKey: LogicalKeyboardKey.space,
      timeStamp: Duration.zero,
    );
    const repeat = KeyRepeatEvent(
      physicalKey: PhysicalKeyboardKey.space,
      logicalKey: LogicalKeyboardKey.space,
      timeStamp: Duration.zero,
    );
    const up = KeyUpEvent(
      physicalKey: PhysicalKeyboardKey.space,
      logicalKey: LogicalKeyboardKey.space,
      timeStamp: Duration.zero,
    );
    expect(b.actionForEvent(down), KeyerAction.straight);
    expect(b.actionForEvent(repeat), isNull);
    expect(b.actionForEvent(up), KeyerAction.straight);
  });

  test('sets are unmodifiable', () {
    expect(
      () => KeyboardKeyBinding.defaults.dit.add(LogicalKeyboardKey.keyA),
      throwsUnsupportedError,
    );
  });

  test('conflicts lists keys bound to more than one action', () {
    expect(KeyboardKeyBinding.defaults.hasConflicts, isFalse);
    final b = KeyboardKeyBinding(
      straight: {LogicalKeyboardKey.space},
      dit: {LogicalKeyboardKey.space, LogicalKeyboardKey.keyZ},
      dah: {LogicalKeyboardKey.keyZ, LogicalKeyboardKey.keyX},
    );
    expect(b.conflicts, {LogicalKeyboardKey.space, LogicalKeyboardKey.keyZ});
  });

  test('straightOnly turns every bound key into a straight key', () {
    final b = KeyboardKeyBinding.defaults.straightOnly();
    for (final k in [
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlRight,
    ]) {
      expect(b.actionFor(k), KeyerAction.straight);
    }
    expect(b.dit, isEmpty);
    expect(b.dah, isEmpty);
  });

  test(
    'a gated sink drops on() while closed but always passes off()',
    () async {
      final inner = RecordingSink(clock: FakeClock());
      var open = true;
      final gate = GatedSink(inner, () => open);
      gate.on();
      open = false; // switched off mid-mark
      gate.off();
      gate.on();
      gate.off();
      expect(inner.events.map((e) => e.on), [true, false, false]);
      expect(inner.isOn, isFalse, reason: 'no stuck tone');
    },
  );
}
