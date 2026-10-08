import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/chat/keying_input.dart';

/// The chat composer's on-screen keys used to fall back to morse_io's English
/// defaults ('KEY' / 'DIT' / 'DAH') in every locale; they must show the same
/// localized labels as Learn, both as text and as the semantics label.
void main() {
  Future<void> pump(WidgetTester tester, KeyingMode mode) async {
    final FakeClock clock = FakeClock();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: KeyingInput(
            mode: mode,
            timing: const MorseTiming(wpm: 20),
            sink: RecordingSink(clock: clock),
            clock: clock,
            onText: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  final S zh = lookupS(const Locale('zh'));

  testWidgets('straight key shows the localized label under zh', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pump(tester, KeyingMode.straightKey);

    expect(zh.learnStraightKeyLabel, '电键');
    expect(find.text('电键'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StraightKeyButton),
        matching: find.bySemanticsLabel(RegExp('电键')),
      ),
      findsOneWidget,
    );
    expect(find.text('KEY'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('KEY')), findsNothing);

    // Dispose the input so its periodic decoder tick is cancelled.
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });

  testWidgets('paddles show the localized dit/dah labels under zh', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pump(tester, KeyingMode.paddles);

    for (final String label in <String>[zh.learnDitLabel, zh.learnDahLabel]) {
      expect(find.text(label), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PaddleButtons),
          matching: find.bySemanticsLabel(RegExp(label)),
        ),
        findsOneWidget,
      );
    }
    for (final String english in <String>['DIT', 'DAH', 'KEY']) {
      expect(find.text(english), findsNothing);
      expect(find.bySemanticsLabel(RegExp(english)), findsNothing);
    }

    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });
}
