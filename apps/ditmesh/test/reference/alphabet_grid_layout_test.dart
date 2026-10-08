import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/reference/alphabet_grid.dart';
import 'package:ditmesh/ui/reference/morse_pattern_text.dart';
import 'package:ditmesh/ui/reference/reference_catalog.dart';
import 'package:ditmesh/ui/reference/reference_playback_controller.dart';
import 'package:ditmesh/ui/reference/reference_playback_settings.dart';
import 'package:ditmesh/ui/theme.dart';
import 'package:provider/provider.dart';

import 'reference_test_support.dart';

Finder _card(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(AlphabetCard));

Future<FakeReferencePlayer> _pumpGrid(
  WidgetTester tester, {
  required double width,
  required Locale locale,
  required double scale,
  TextScaler? textScaler,
}) async {
  setSurfaceSize(tester, Size(width, 800));
  final FakeReferencePlayer fake = FakeReferencePlayer();
  final ReferencePlaybackSettings settings = ReferencePlaybackSettings();
  final ReferencePlaybackController controller = ReferencePlaybackController(
    playerFactory: fake.create,
    settings: settings,
  );
  addTearDown(() {
    controller.dispose();
    settings.dispose();
  });
  await tester.pumpWidget(
    ChangeNotifierProvider<ReferencePlaybackController>.value(
      value: controller,
      child: MaterialApp(
        theme: DitmeshTheme.light(),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: textScaler ?? TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: AlphabetGrid(
            entries: ReferenceCatalog.alphabet
                .where(
                  (entry) => <String>['A', 'K', '0', '5'].contains(entry.label),
                )
                .toList(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}

Future<void> _expectFullPatterns(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  tester.state<ScrollableState>(find.byType(Scrollable)).position.jumpTo(0);
  await tester.pump();
  for (final String label in <String>['A', 'K', '0', '5']) {
    final Finder card = _card(label);
    await tester.scrollUntilVisible(card, 200);
    await tester.pump();
    final Finder pattern = find.descendant(
      of: card,
      matching: find.byType(MorsePatternText),
    );
    final Finder richText = find.descendant(
      of: pattern,
      matching: find.byType(RichText),
    );
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      richText,
    );
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: '$label retains every Morse mark',
    );
    final Rect cardRect = tester.getRect(card);
    final Rect patternRect = tester.getRect(richText);
    expect(patternRect.top, greaterThanOrEqualTo(cardRect.top));
    expect(patternRect.bottom, lessThanOrEqualTo(cardRect.bottom));
    expect(tester.getSize(card).shortestSide, greaterThanOrEqualTo(48));
  }
}

void main() {
  testWidgets('nonlinear accessibility scaling retains full patterns', (
    tester,
  ) async {
    await _pumpGrid(
      tester,
      width: 320,
      locale: const Locale('zh'),
      scale: 1,
      textScaler: const _NonlinearScaler(),
    );
    await _expectFullPatterns(tester);
  });
  for (final Locale locale in <Locale>[
    const Locale('en'),
    const Locale('zh'),
  ]) {
    for (final double width in <double>[320, 390, 900]) {
      for (final double scale in <double>[1, 1.8]) {
        testWidgets(
          'full Morse at $width ${locale.languageCode} scale $scale',
          (tester) async {
            final FakeReferencePlayer fake = await _pumpGrid(
              tester,
              width: width,
              locale: locale,
              scale: scale,
            );
            await _expectFullPatterns(tester);
            await tester.ensureVisible(_card('0'));
            await tester.pumpAndSettle();
            await tester.tap(_card('0'));
            await tester.pump();
            expect(fake.sink.isOn, isTrue);
            await _expectFullPatterns(tester);
            await tester.ensureVisible(_card('0'));
            await tester.pumpAndSettle();
            await tester.tap(_card('0'));
            await tester.pump();
            expect(fake.sink.isOn, isFalse);
            await tester.scrollUntilVisible(_card('A'), -200);
            await tester.pumpAndSettle();
            await tester.longPress(_card('A'));
            await tester.pumpAndSettle();
            expect(find.byType(AlertDialog), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.tap(find.text(lookupS(locale).referenceClose));
            await tester.pumpAndSettle();
          },
        );
      }
    }
  }
}

class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();

  @override
  double scale(double fontSize) => fontSize + 12;

  @override
  double get textScaleFactor => 1.8;
}
