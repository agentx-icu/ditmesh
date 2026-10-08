import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';

final class _FakeStraightKey implements StraightKeyInput {
  final List<(bool, int)> log = <(bool, int)>[];

  @override
  void press(Duration at) => log.add((true, at.inMilliseconds));

  @override
  void release(Duration at) => log.add((false, at.inMilliseconds));
}

final class _FakePaddles implements PaddleInput {
  final List<String> log = <String>[];

  @override
  void ditPaddle(bool down, Duration at) =>
      log.add('dit ${down ? 'down' : 'up'} @${at.inMilliseconds}');

  @override
  void dahPaddle(bool down, Duration at) =>
      log.add('dah ${down ? 'down' : 'up'} @${at.inMilliseconds}');
}

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('StraightKeyButton', () {
    testWidgets('pointer down / up drives the key with clock times',
        (tester) async {
      final clock = FakeClock();
      final key = _FakeStraightKey();
      await tester.pumpWidget(
        _host(StraightKeyButton(input: key, clock: clock)),
      );
      final gesture = await tester.press(find.byType(StraightKeyButton));
      await tester.pump();
      expect(key.log, <(bool, int)>[(true, 0)]);

      clock.advance(const Duration(milliseconds: 80));
      await gesture.up();
      await tester.pump();
      expect(key.log, <(bool, int)>[(true, 0), (false, 80)]);
    });

    testWidgets('stays down until the last of two fingers lifts',
        (tester) async {
      final key = _FakeStraightKey();
      await tester.pumpWidget(
        _host(StraightKeyButton(input: key, clock: FakeClock())),
      );
      final center = tester.getCenter(find.byType(StraightKeyButton));
      final first = await tester.startGesture(center, pointer: 1);
      final second =
          await tester.startGesture(center + const Offset(10, 10), pointer: 2);
      await first.up();
      await tester.pump();
      expect(key.log, <(bool, int)>[(true, 0)]);
      await second.up();
      await tester.pump();
      expect(key.log, <(bool, int)>[(true, 0), (false, 0)]);
    });

    testWidgets('space bar keys it when focused; repeats are ignored',
        (tester) async {
      final key = _FakeStraightKey();
      await tester.pumpWidget(
        _host(StraightKeyButton(
          input: key,
          clock: FakeClock(),
          autofocus: true,
        )),
      );
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      expect(key.log, <(bool, int)>[(true, 0), (false, 0)]);
    });

    testWidgets('losing focus while the space bar is held releases the key',
        (tester) async {
      final key = _FakeStraightKey();
      final other = FocusNode();
      addTearDown(other.dispose);
      await tester.pumpWidget(
        _host(Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StraightKeyButton(input: key, clock: FakeClock(), autofocus: true),
            Focus(focusNode: other, child: const SizedBox(width: 10, height: 10)),
          ],
        )),
      );
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      expect(key.log, <(bool, int)>[(true, 0)]);
      // A menu or sheet takes focus; its key-up never reaches the key.
      other.requestFocus();
      await tester.pump();
      expect(key.log, <(bool, int)>[(true, 0), (false, 0)]);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      expect(key.log, hasLength(2));
    });

    testWidgets('backgrounding releases a held key (touch or keyboard)',
        (tester) async {
      final key = _FakeStraightKey();
      await tester.pumpWidget(
        _host(StraightKeyButton(input: key, clock: FakeClock(), autofocus: true)),
      );
      await tester.pump();
      final gesture = await tester.press(find.byType(StraightKeyButton));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      expect(key.log, <(bool, int)>[(true, 0)]);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(key.log, <(bool, int)>[(true, 0), (false, 0)]);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await gesture.up();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(key.log, hasLength(2));
    });

    testWidgets('a touch takes keyboard focus back', (tester) async {
      final key = _FakeStraightKey();
      final other = FocusNode();
      addTearDown(other.dispose);
      await tester.pumpWidget(
        _host(Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StraightKeyButton(input: key, clock: FakeClock()),
            Focus(focusNode: other, child: const SizedBox(width: 10, height: 10)),
          ],
        )),
      );
      other.requestFocus();
      await tester.pump();
      await tester.tap(find.byType(StraightKeyButton));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      expect(key.log, hasLength(4));
    });

    testWidgets('respects the minimum touch target', (tester) async {
      await tester.pumpWidget(
        _host(StraightKeyButton(input: _FakeStraightKey(), size: 10)),
      );
      final size = tester.getSize(find.byType(StraightKeyButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('PaddleButtons', () {
    testWidgets('two simultaneous pointers squeeze both paddles',
        (tester) async {
      final clock = FakeClock();
      final paddles = _FakePaddles();
      await tester.pumpWidget(
        _host(SizedBox(
          width: 400,
          child: PaddleButtons(input: paddles, clock: clock),
        )),
      );
      final rect = tester.getRect(find.byType(PaddleButtons));
      final left = Offset(rect.left + rect.width * 0.25, rect.center.dy);
      final right = Offset(rect.left + rect.width * 0.75, rect.center.dy);

      final ditFinger = await tester.startGesture(left, pointer: 1);
      clock.advance(const Duration(milliseconds: 10));
      final dahFinger = await tester.startGesture(right, pointer: 2);
      await tester.pump();
      expect(paddles.log, <String>['dit down @0', 'dah down @10']);

      clock.advance(const Duration(milliseconds: 10));
      await ditFinger.up();
      clock.advance(const Duration(milliseconds: 10));
      await dahFinger.up();
      await tester.pump();
      expect(paddles.log, <String>[
        'dit down @0',
        'dah down @10',
        'dit up @20',
        'dah up @30',
      ]);
    });

    testWidgets('swapPaddles puts dah on the left', (tester) async {
      final paddles = _FakePaddles();
      await tester.pumpWidget(
        _host(SizedBox(
          width: 400,
          child: PaddleButtons(
            input: paddles,
            clock: FakeClock(),
            swapPaddles: true,
          ),
        )),
      );
      final rect = tester.getRect(find.byType(PaddleButtons));
      final gesture = await tester.startGesture(
        Offset(rect.left + rect.width * 0.25, rect.center.dy),
      );
      await gesture.up();
      await tester.pump();
      expect(paddles.log, <String>['dah down @0', 'dah up @0']);
    });

    testWidgets('ctrl keys drive dit / dah when focused', (tester) async {
      final paddles = _FakePaddles();
      await tester.pumpWidget(
        _host(SizedBox(
          width: 400,
          child: PaddleButtons(
            input: paddles,
            clock: FakeClock(),
            autofocus: true,
          ),
        )),
      );
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlRight);
      expect(paddles.log, <String>[
        'dit down @0',
        'dah down @0',
        'dit up @0',
        'dah up @0',
      ]);
    });

    testWidgets('losing focus releases keyboard-held paddles', (tester) async {
      final paddles = _FakePaddles();
      final other = FocusNode();
      addTearDown(other.dispose);
      await tester.pumpWidget(
        _host(Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 400,
              child: PaddleButtons(
                input: paddles,
                clock: FakeClock(),
                autofocus: true,
              ),
            ),
            Focus(focusNode: other, child: const SizedBox(width: 10, height: 10)),
          ],
        )),
      );
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      other.requestFocus();
      await tester.pump();
      expect(paddles.log, <String>['dit down @0', 'dit up @0']);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(paddles.log, hasLength(2));
    });
  });

  group('FlashOverlay', () {
    testWidgets('paints onColor while the sink is on', (tester) async {
      final sink = FlashSink(platformOverride: TargetPlatform.linux);
      addTearDown(sink.dispose);
      await tester.pumpWidget(
        _host(SizedBox(
          width: 100,
          height: 100,
          child: FlashOverlay(
            isOn: sink.isOn,
            onColor: const Color(0xFFFF0000),
            child: const SizedBox.expand(),
          ),
        )),
      );
      ColoredBox box() => tester.widget<ColoredBox>(
            find.descendant(
              of: find.byType(FlashOverlay),
              matching: find.byType(ColoredBox),
            ),
          );
      expect(box().color, const Color(0x00000000));
      sink.on();
      await tester.pump();
      expect(box().color, const Color(0xFFFF0000));
      sink.off();
      await tester.pump();
      expect(box().color, const Color(0x00000000));
    });
  });
}
