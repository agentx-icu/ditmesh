// Phone touch cases for the on-screen keys: the OS stealing a pointer
// (system edge gestures send PointerCancel), the key sitting in a scroll
// view whose drag recogniser wins the gesture arena, and a finger sliding
// from one paddle onto the other.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';

final class _FakeStraightKey implements StraightKeyInput {
  final List<bool> log = <bool>[];

  @override
  void press(Duration at) => log.add(true);

  @override
  void release(Duration at) => log.add(false);
}

final class _FakePaddles implements PaddleInput {
  final List<String> log = <String>[];

  @override
  void ditPaddle(bool down, Duration at) =>
      log.add('dit ${down ? 'down' : 'up'}');

  @override
  void dahPaddle(bool down, Duration at) =>
      log.add('dah ${down ? 'down' : 'up'}');
}

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('a cancelled pointer releases the straight key', (tester) async {
    final key = _FakeStraightKey();
    await tester.pumpWidget(
      _host(Center(child: StraightKeyButton(input: key, clock: FakeClock()))),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(StraightKeyButton)),
    );
    await tester.pump();
    await gesture.cancel();
    await tester.pump();
    expect(key.log, <bool>[true, false]);
  });

  testWidgets('a cancelled pointer releases its paddle only', (tester) async {
    final paddles = _FakePaddles();
    await tester.pumpWidget(
      _host(
        Center(
          child: SizedBox(
            width: 400,
            child: PaddleButtons(input: paddles, clock: FakeClock()),
          ),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(PaddleButtons));
    final dit = await tester.startGesture(
      Offset(rect.left + rect.width * 0.25, rect.center.dy),
      pointer: 1,
    );
    final dah = await tester.startGesture(
      Offset(rect.left + rect.width * 0.75, rect.center.dy),
      pointer: 2,
    );
    await dit.cancel();
    await tester.pump();
    expect(paddles.log, <String>['dit down', 'dah down', 'dit up']);
    await dah.up();
    await tester.pump();
    expect(paddles.log.last, 'dah up');
  });

  testWidgets('a scroll view winning the drag does not release the key early',
      (tester) async {
    final key = _FakeStraightKey();
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      _host(
        ListView(
          controller: scroll,
          children: <Widget>[
            const SizedBox(height: 200),
            Center(child: StraightKeyButton(input: key, clock: FakeClock())),
            const SizedBox(height: 2000),
          ],
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(StraightKeyButton)),
    );
    await tester.pump();
    // Well past touch slop: the list's vertical drag wins the arena.
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    expect(scroll.offset, greaterThan(0));
    expect(key.log, <bool>[true]);
    await gesture.up();
    await tester.pump();
    expect(key.log, <bool>[true, false]);
  });

  testWidgets('sliding from dit onto dah keeps only dit down', (tester) async {
    final paddles = _FakePaddles();
    await tester.pumpWidget(
      _host(
        Center(
          child: SizedBox(
            width: 400,
            child: PaddleButtons(input: paddles, clock: FakeClock()),
          ),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(PaddleButtons));
    final finger = await tester.startGesture(
      Offset(rect.left + rect.width * 0.25, rect.center.dy),
    );
    await finger.moveTo(Offset(rect.left + rect.width * 0.75, rect.center.dy));
    await tester.pump();
    expect(paddles.log, <String>['dit down']);
    await finger.up();
    await tester.pump();
    expect(paddles.log, <String>['dit down', 'dit up']);
  });
}
