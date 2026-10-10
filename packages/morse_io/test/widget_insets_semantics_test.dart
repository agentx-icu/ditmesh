// Mobile-device review (2026-10-08, T2 / T10 / T11): the on-screen keys
// under Android gesture navigation and under a screen reader.
//
// * `systemGestureInsets.left/right` are the system back-gesture zones; a
//   paddle press that starts there and drifts inward becomes "back". The
//   paddles stay clear of those zones (SafeArea does not remove them).
// * Each key announces its label once: the printed text is excluded from
//   semantics so VoiceOver / TalkBack do not read "KEY, KEY".
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

const Size _phone = Size(390, 844);
const double _gestureZone = 30;

void _setView(WidgetTester tester, {bool gestureNav = false}) {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1.0;
  tester.view.systemGestureInsets = gestureNav
      ? const FakeViewPadding(
          left: _gestureZone,
          right: _gestureZone,
          bottom: _gestureZone,
        )
      : FakeViewPadding.zero;
  addTearDown(tester.view.reset);
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Align(alignment: Alignment.topLeft, child: child),
  ),
);

/// The two paddle surfaces (raw listeners inside [PaddleButtons]).
Finder get _paddles => find.descendant(
  of: find.byType(PaddleButtons),
  matching: find.byType(Listener),
);

void main() {
  group('gesture navigation', () {
    testWidgets('paddles stay clear of the back-gesture zones', (tester) async {
      _setView(tester, gestureNav: true);
      await tester.pumpWidget(
        _host(PaddleButtons(input: _FakePaddles(), clock: FakeClock())),
      );
      final Rect left = tester.getRect(_paddles.first);
      final Rect right = tester.getRect(_paddles.last);
      expect(left.left, greaterThanOrEqualTo(_gestureZone));
      expect(right.right, lessThanOrEqualTo(_phone.width - _gestureZone));
      for (final Rect pad in <Rect>[left, right]) {
        expect(pad.width, greaterThanOrEqualTo(PaddleButtons.minTouchTarget));
        expect(pad.height, greaterThanOrEqualTo(PaddleButtons.minTouchTarget));
      }
    });

    testWidgets('without gesture navigation the paddles use the full width', (
      tester,
    ) async {
      _setView(tester);
      await tester.pumpWidget(
        _host(PaddleButtons(input: _FakePaddles(), clock: FakeClock())),
      );
      expect(tester.getRect(_paddles.first).left, 0);
      expect(tester.getRect(_paddles.last).right, _phone.width);
    });
  });

  group('screen reader', () {
    testWidgets('the straight key announces its label once, with dit and '
        'dah actions', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      _setView(tester);
      await tester.pumpWidget(
        _host(
          StraightKeyButton(
            input: _FakeStraightKey(),
            clock: FakeClock(),
            label: 'KEY',
            semanticDit: const Duration(milliseconds: 60),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(StraightKeyButton)),
        matchesSemantics(
          label: 'KEY',
          isButton: true,
          isFocusable: true,
          hasFocusAction: true,
          customActions: <CustomSemanticsAction>[
            const CustomSemanticsAction(label: 'dit'),
            const CustomSemanticsAction(label: 'dah'),
          ],
        ),
      );
      handle.dispose();
    });

    testWidgets('each paddle announces its label once', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      _setView(tester);
      await tester.pumpWidget(
        _host(PaddleButtons(input: _FakePaddles(), clock: FakeClock())),
      );
      final Finder buttons = find.descendant(
        of: find.byType(PaddleButtons),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.button == true,
        ),
      );
      expect(buttons, findsNWidgets(2));
      expect(
        tester.getSemantics(buttons.first),
        matchesSemantics(label: 'DIT', isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(buttons.last),
        matchesSemantics(label: 'DAH', isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });
  });
}
