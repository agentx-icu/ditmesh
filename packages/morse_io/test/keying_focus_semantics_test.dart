// Keys held on the keyboard when focus moves away, and the screen-reader
// actions on the on-screen keys (2026-10-03 Learn review).
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';

final class _FakeStraightKey implements StraightKeyInput {
  final List<(bool, Duration)> log = <(bool, Duration)>[];

  @override
  void press(Duration at) => log.add((true, at));

  @override
  void release(Duration at) => log.add((false, at));
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

Widget _host(Widget child, FocusNode other) => MaterialApp(
  home: Scaffold(
    body: Column(
      children: <Widget>[
        child,
        Focus(focusNode: other, child: const SizedBox(width: 10, height: 10)),
      ],
    ),
  ),
);

/// Hosts the key built for the current generation; bumping [generation]
/// replaces it with a new widget under a new [Key] and a new input.
Widget _swapHost(ValueNotifier<int> generation, Widget Function(int) build) =>
    MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder<int>(
          valueListenable: generation,
          builder: (context, n, _) => build(n),
        ),
      ),
    );

Future<void> _swapStraightKeyMidPress(
  WidgetTester tester, {
  required bool cancel,
}) async {
  final a = _FakeStraightKey();
  final b = _FakeStraightKey();
  final generation = ValueNotifier<int>(1);
  addTearDown(generation.dispose);
  await tester.pumpWidget(
    _swapHost(
      generation,
      (n) => StraightKeyButton(
        key: ValueKey<String>('straight-key-$n'),
        input: n == 1 ? a : b,
        clock: FakeClock(),
        keyboard: false,
      ),
    ),
  );
  final finger = await tester.startGesture(
    tester.getCenter(find.byType(StraightKeyButton)),
  );
  expect(a.log.map((e) => e.$1), <bool>[true]);

  generation.value = 2;
  await tester.pump();
  // dispose released the old input once.
  expect(a.log.map((e) => e.$1), <bool>[true, false]);

  // The lift still travels the old hit-test path to the disposed state.
  if (cancel) {
    await finger.cancel();
  } else {
    await finger.up();
  }
  await tester.pump();
  expect(tester.takeException(), isNull);
  expect(a.log.map((e) => e.$1), <bool>[true, false]);
  expect(b.log, isEmpty);
}

Future<void> _swapPaddlesMidPress(
  WidgetTester tester, {
  required bool cancel,
}) async {
  final a = _FakePaddles();
  final b = _FakePaddles();
  final generation = ValueNotifier<int>(1);
  addTearDown(generation.dispose);
  await tester.pumpWidget(
    _swapHost(
      generation,
      (n) => SizedBox(
        width: 400,
        child: PaddleButtons(
          key: ValueKey<String>('paddles-$n'),
          input: n == 1 ? a : b,
          clock: FakeClock(),
          keyboard: false,
          ditLabel: 'DIT',
          dahLabel: 'DAH',
        ),
      ),
    ),
  );
  final finger = await tester.startGesture(tester.getCenter(find.text('DIT')));
  expect(a.log, <String>['dit down']);

  generation.value = 2;
  await tester.pump();
  expect(a.log, <String>['dit down', 'dit up']);

  if (cancel) {
    await finger.cancel();
  } else {
    await finger.up();
  }
  await tester.pump();
  expect(tester.takeException(), isNull);
  expect(a.log, <String>['dit down', 'dit up']);
  expect(b.log, isEmpty);
}

void main() {
  testWidgets('losing focus releases a straight key held on the keyboard', (
    tester,
  ) async {
    final key = _FakeStraightKey();
    final other = FocusNode();
    addTearDown(other.dispose);
    await tester.pumpWidget(
      _host(
        StraightKeyButton(input: key, clock: FakeClock(), autofocus: true),
        other,
      ),
    );
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    expect(key.log.map((e) => e.$1), <bool>[true]);

    other.requestFocus();
    await tester.pump();
    expect(key.log.map((e) => e.$1), <bool>[true, false]);

    // The key-up now lands elsewhere; nothing more reaches the key.
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    expect(key.log, hasLength(2));
  });

  testWidgets('losing focus keeps a finger on the key down', (tester) async {
    final key = _FakeStraightKey();
    final other = FocusNode();
    addTearDown(other.dispose);
    await tester.pumpWidget(
      _host(
        StraightKeyButton(input: key, clock: FakeClock(), autofocus: true),
        other,
      ),
    );
    await tester.pump();
    final finger = await tester.startGesture(
      tester.getCenter(find.byType(StraightKeyButton)),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    other.requestFocus();
    await tester.pump();
    expect(key.log.map((e) => e.$1), <bool>[true]);
    await finger.up();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    expect(key.log.map((e) => e.$1), <bool>[true, false]);
  });

  testWidgets('losing focus releases paddles held on the keyboard', (
    tester,
  ) async {
    final paddles = _FakePaddles();
    final other = FocusNode();
    addTearDown(other.dispose);
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 400,
          child: PaddleButtons(
            input: paddles,
            clock: FakeClock(),
            autofocus: true,
          ),
        ),
        other,
      ),
    );
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlRight);
    other.requestFocus();
    await tester.pump();
    expect(paddles.log, <String>['dit down', 'dah down', 'dit up', 'dah up']);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlRight);
    expect(paddles.log, hasLength(4));
  });

  testWidgets('screen-reader actions key a timed dit and dah', (tester) async {
    final handle = tester.ensureSemantics();
    final key = _FakeStraightKey();
    final clock = FakeClock();
    const dit = Duration(milliseconds: 60);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StraightKeyButton(
            input: key,
            clock: clock,
            label: 'KEY',
            semanticDit: dit,
            semanticDitLabel: 'Dit',
            semanticDahLabel: 'Dah',
          ),
        ),
      ),
    );
    final node = tester.getSemantics(find.bySemanticsLabel(RegExp('KEY')));
    final actions = node.getSemanticsData().customSemanticsActionIds!;
    expect(actions, hasLength(2));
    final owner = node.owner!;

    owner.performAction(
      node.id,
      SemanticsAction.customAction,
      CustomSemanticsAction.getIdentifier(
        const CustomSemanticsAction(label: 'Dah'),
      ),
    );
    await tester.pump();
    expect(key.log.map((e) => e.$1), <bool>[true]);
    await tester.pump(dit * 3);
    expect(key.log.map((e) => e.$1), <bool>[true, false]);

    owner.performAction(
      node.id,
      SemanticsAction.customAction,
      CustomSemanticsAction.getIdentifier(
        const CustomSemanticsAction(label: 'Dit'),
      ),
    );
    await tester.pump(dit);
    expect(key.log.map((e) => e.$1), <bool>[true, false, true, false]);
    handle.dispose();
  });

  testWidgets('without a dit length the key offers no custom actions', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StraightKeyButton(
            input: _FakeStraightKey(),
            clock: FakeClock(),
            label: 'KEY',
          ),
        ),
      ),
    );
    final node = tester.getSemantics(find.bySemanticsLabel(RegExp('KEY')));
    expect(node.getSemanticsData().customSemanticsActionIds, isEmpty);
    handle.dispose();
  });

  testWidgets('a semantic tap on a paddle sends one press and release', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final paddles = _FakePaddles();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: PaddleButtons(
              input: paddles,
              clock: FakeClock(),
              ditLabel: 'DIT',
              dahLabel: 'DAH',
            ),
          ),
        ),
      ),
    );
    final node = tester.getSemantics(find.bySemanticsLabel(RegExp('DAH')));
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump();
    expect(paddles.log, <String>['dah down', 'dah up']);
    handle.dispose();
  });
  testWidgets('a finger lifted after the straight key is replaced is dropped', (
    tester,
  ) async {
    await _swapStraightKeyMidPress(tester, cancel: false);
  });

  testWidgets(
    'a pointer cancel after the straight key is replaced is dropped',
    (tester) async {
      await _swapStraightKeyMidPress(tester, cancel: true);
    },
  );

  testWidgets('a finger lifted after the paddles are replaced is dropped', (
    tester,
  ) async {
    await _swapPaddlesMidPress(tester, cancel: false);
  });

  testWidgets('a pointer cancel after the paddles are replaced is dropped', (
    tester,
  ) async {
    await _swapPaddlesMidPress(tester, cancel: true);
  });
}
