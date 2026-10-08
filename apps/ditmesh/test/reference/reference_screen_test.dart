import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:morse_core/morse_core.dart';
import 'package:ditmesh/ui/reference/alphabet_grid.dart';
import 'package:ditmesh/ui/reference/morse_pattern_text.dart';
import 'package:ditmesh/ui/reference/reference_catalog.dart';
import 'package:ditmesh/ui/reference/reference_entry_tile.dart';
import 'package:ditmesh/ui/reference/reference_screen.dart';

import 'reference_test_support.dart';

const Duration _dit15 = Duration(milliseconds: 80); // 15 wpm default
final S en = kTestStrings;

Future<FakeReferencePlayer> _pump(
  WidgetTester tester, {
  Size size = kPhone,
  ReferenceSection initialSection = ReferenceSection.alphabet,
}) async {
  setSurfaceSize(tester, size);
  final fake = FakeReferencePlayer();
  await pumpScreen(
    tester,
    ReferenceScreen(playerFactory: fake.create, initialSection: initialSection),
  );
  return fake;
}

Finder _card(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byType(AlphabetCard),
    );

void main() {
  group('ReferenceScreen layout', () {
    testWidgets('phone shows tabs and the alphabet grid first', (tester) async {
      await _pump(tester);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(AlphabetGrid), findsOneWidget);
      expect(_card('A'), findsOneWidget);
      expect(find.text(displayMorsePattern('.-'), findRichText: true),
          findsWidgets);
    });

    testWidgets('wide window shows a section rail instead of tabs', (tester) async {
      await _pump(tester, size: kDesktop);
      expect(find.byType(TabBar), findsNothing);
      expect(find.byType(ReferenceSectionRail), findsOneWidget);
      await tester.tap(find.text(en.referenceSectionQCodes));
      await tester.pumpAndSettle();
      expect(find.text('QRL'), findsOneWidget);
      expect(find.byType(AlphabetGrid), findsNothing);
    });

    testWidgets('Koch order lists positions', (tester) async {
      await _pump(tester, initialSection: ReferenceSection.koch);
      final first = find.byType(ReferenceEntryTile).first;
      expect(find.descendant(of: first, matching: find.text('1')), findsOneWidget);
      expect(find.descendant(of: first, matching: find.text('K')), findsOneWidget);
      final second = find.byType(ReferenceEntryTile).at(1);
      expect(find.descendant(of: second, matching: find.text('2')), findsOneWidget);
      expect(find.descendant(of: second, matching: find.text('M')), findsOneWidget);
    });
  });

  group('search', () {
    testWidgets('filters every section and hides the tabs', (tester) async {
      await _pump(tester);
      await tester.enterText(find.byKey(ReferenceScreen.searchFieldKey), 'QRL');
      await tester.pumpAndSettle();
      expect(find.byType(TabBar), findsNothing);
      // find.text also matches the search field's EditableText, so scope
      // the hit to the result rows.
      expect(
        find.descendant(
          of: find.byType(ReferenceEntryTile),
          matching: find.text('QRL'),
        ),
        findsOneWidget,
      );
      expect(find.text('QRM'), findsNothing);
      expect(find.text(en.referenceSectionQCodes), findsOneWidget);
      expect(_card('A'), findsNothing);
    });

    testWidgets('matches meanings too', (tester) async {
      await _pump(tester);
      await tester.enterText(
        find.byKey(ReferenceScreen.searchFieldKey),
        'who is calling',
      );
      await tester.pumpAndSettle();
      expect(find.text('QRZ'), findsOneWidget);
    });

    testWidgets('a character appears under Alphabet and Koch order', (tester) async {
      await _pump(tester);
      // The mnemonic phrase for K only; a bare "K" would also hit every
      // meaning containing the letter and push the Koch header off-screen.
      await tester.enterText(find.byKey(ReferenceScreen.searchFieldKey), 'KANG');
      await tester.pumpAndSettle();
      expect(find.text(en.referenceSectionAlphabet), findsOneWidget);
      expect(find.text(en.referenceSectionKoch), findsOneWidget);
      expect(find.byType(ReferenceEntryTile), findsNWidgets(2));
    });

    testWidgets('no hits shows the empty message; clear restores tabs', (tester) async {
      await _pump(tester);
      await tester.enterText(find.byKey(ReferenceScreen.searchFieldKey), 'zzzzzz');
      await tester.pumpAndSettle();
      expect(find.text(en.referenceNoResults), findsOneWidget);
      await tester.tap(find.byTooltip(en.referenceClearSearch));
      await tester.pumpAndSettle();
      expect(find.byType(TabBar), findsOneWidget);
    });
  });

  group('playback', () {
    testWidgets('tapping a card plays it through the injected player', (tester) async {
      final fake = await _pump(tester);
      // The player is created lazily on first use, not when the screen is
      // built (the shell's IndexedStack must not touch the audio engine).
      expect(fake.players, isEmpty);
      await tester.tap(_card('K'));
      await tester.pump();
      expect(fake.players, hasLength(1));
      // K = -.- : the sink keys on immediately.
      expect(fake.sink.isOn, isTrue);
      expect(fake.onCount, 1);
      // Run the whole character (dah dit dah + 2 intra gaps = 9 dits).
      fake.clock.advance(_dit15 * 9);
      await tester.pump();
      expect(fake.onCount, 3);
      expect(fake.sink.isOn, isFalse);
      final elements = MorseEncoder.encode('K', const MorseTiming(wpm: 15));
      expect(elements.where((e) => e.on).length, 3);
    });

    testWidgets('only one entry plays at a time', (tester) async {
      final fake = await _pump(tester);
      await tester.tap(_card('K'));
      await tester.pump();
      fake.clock.advance(_dit15);
      await tester.pump();
      await tester.tap(_card('M'));
      await tester.pump();
      // Exactly one card shows the playing indicator.
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(
        find.descendant(of: _card('M'), matching: find.byIcon(Icons.volume_up)),
        findsOneWidget,
      );
      // K's dah was cut short (off), then M's first dah started (on).
      final log = fake.sink.log;
      expect(log.where((e) => !e.$1).length, 1);
      expect(fake.onCount, 2);
    });

    testWidgets('tapping the playing card stops it', (tester) async {
      final fake = await _pump(tester);
      await tester.tap(_card('K'));
      await tester.pump();
      await tester.tap(_card('K'));
      await tester.pump();
      expect(fake.sink.isOn, isFalse);
      expect(find.byIcon(Icons.volume_up), findsNothing);
    });

    testWidgets('list rows play from their play button', (tester) async {
      final fake = await _pump(tester, initialSection: ReferenceSection.qCodes);
      final row = find.ancestor(
        of: find.text('QRL'),
        matching: find.byType(ReferenceEntryTile),
      );
      await tester.tap(
        find.descendant(of: row, matching: find.byTooltip(en.referencePlay)),
      );
      await tester.pump();
      expect(fake.sink.isOn, isTrue);
      expect(
        find.descendant(of: row, matching: find.byTooltip(en.referenceStop)),
        findsOneWidget,
      );
    });

    testWidgets('disposing the screen stops playback and releases the sink',
        (tester) async {
      final fake = await _pump(tester);
      await tester.tap(_card('K'));
      await tester.pump();
      expect(fake.sink.isOn, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(fake.sink.isOn, isFalse);
      expect(fake.sink.disposeCalls, 1);
    });
  });

  group('mnemonics', () {
    testWidgets('long-pressing a card shows the mnemonic', (tester) async {
      await _pump(tester);
      await tester.longPress(_card('A'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('A: di-DAH'), findsOneWidget);
      await tester.tap(find.text(en.referenceClose));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
