// Phone-form-factor regressions: small portrait phones (320x568), phones in
// landscape (~375-390 px tall, notch + home-indicator insets), the soft
// keyboard covering half the screen, and a 2.0 text scale. Each case here
// overflowed (or lost state) before the fix it guards.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh/ui/account/identity_card.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/reference/reference_screen.dart';
import 'package:ditmesh/ui/reference/translator_screen.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../account/test_app.dart';
import '../chat/test_support.dart' as chat;
import '../learn/helpers/l10n.dart';
import '../learn/helpers/unavailable_training.dart';
import '../reference/reference_test_support.dart';
import 'phone_support.dart';

void main() {
  group('shell', () {
    testWidgets('rotating across the rail breakpoint keeps tab state', (
      tester,
    ) async {
      setPhone(tester, const Size(390, 844));
      await bootApp(tester);
      await tester.tap(navLabel(en.navReference));
      await settle(tester);
      final State before = tester.state(find.byType(ReferenceScreen));

      tester.view.physicalSize = kLandscapePhone;
      tester.view.padding = phonePaddingFor(kLandscapePhone);
      await settle(tester);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(tester.state(find.byType(ReferenceScreen)), same(before));

      tester.view.physicalSize = const Size(390, 844);
      tester.view.padding = phonePaddingFor(const Size(390, 844));
      await settle(tester);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.state(find.byType(ReferenceScreen)), same(before));
    });

    testWidgets('the rail fits a landscape phone at 2x text', (tester) async {
      setPhone(tester, kLandscapePhone, textScale: 2);
      await bootApp(tester);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(tester.takeException(), isNull);
      // The last destination is still reachable by scrolling the rail.
      await tester.scrollUntilVisible(
        navLabel(en.navMe),
        50,
        scrollable: find.descendant(
          of: find.byType(NavigationRail),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(navLabel(en.navMe));
      await settle(tester);
      expect(find.byType(IdentityCard), findsOneWidget);
    });

    testWidgets('identity card fits a 320 px phone at 2x text', (tester) async {
      setPhone(tester, kSmallPhone, textScale: 2);
      await bootApp(tester);
      await tester.tap(navLabel(en.navMe));
      await settle(tester);
      expect(find.byType(IdentityCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('training data placeholder', () {
    // Regression: the loading / identity-required placeholder was a fixed
    // Column and overflowed by 181 px on a 320 pt phone at 2x text; CI only
    // caught it when the controller load was slow enough to paint a frame.
    for (final bool loading in <bool>[true, false]) {
      testWidgets('${loading ? 'loading' : 'identity required'} fits a '
          '320 px phone at 2x text', (tester) async {
        setPhone(tester, kSmallPhone, textScale: 2);
        await tester.pumpWidget(
          l10nApp(
            home: unavailableTrainingSettings(
              UnavailableIdentityService(loading: loading),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          find.text(en.learnIdentityRequired),
          loading ? findsNothing : findsOneWidget,
        );
      });
    }
  });

  group('chat composer', () {
    final cases = <(Size, double)>[
      (kLandscapeSmallPhone, 1),
      (kLandscapePhone, 2),
      (kLandscapeSmallPhone, 2),
      (kSmallPhone, 2),
    ];
    for (final (Size size, double scale) in cases) {
      for (final bool paddles in <bool>[false, true]) {
        testWidgets('${paddles ? 'paddles' : 'straight key'} fit $size at '
            '${scale}x', (tester) async {
          final h = chat.ChatHarness();
          addTearDown(h.dispose);
          setPhone(tester, size, textScale: scale);
          h.addAnn();
          await tester.pumpWidget(
            h.wrap(
              ConversationScreen(
                target: ConversationTarget(
                  id: 'c2c_${chat.kPeerKey}',
                  title: 'Ann',
                  kind: ConversationKind.c2c,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (paddles) {
            await tester.tap(find.byTooltip(chat.s.chatModePaddles));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          final Finder pad = paddles
              ? find.byType(PaddleButtons)
              : find.byType(StraightKeyButton);
          expect(pad, findsOneWidget);
          expect(
            tester.getSize(pad).height,
            greaterThanOrEqualTo(StraightKeyButton.minTouchTarget),
          );
        });
      }
    }
  });

  group('translator', () {
    final cases = <(Size, double, double)>[
      (kSmallPhone, 1, 260), // portrait, soft keyboard up
      (kSmallPhone, 2, 0),
      (kSmallPhone, 2, 260),
      (kLandscapePhone, 1, 0),
      (kLandscapePhone, 1, 200), // landscape, soft keyboard up
      (kLandscapePhone, 2, 0),
    ];
    for (final (Size size, double scale, double keyboard) in cases) {
      for (final TranslatorMode mode in TranslatorMode.values) {
        testWidgets('${mode.name} fits $size at ${scale}x, keyboard '
            '$keyboard', (tester) async {
          setPhone(tester, size, textScale: scale, keyboard: keyboard);
          final fake = FakeReferencePlayer();
          await pumpScreen(
            tester,
            TranslatorScreen(
              playerFactory: fake.create,
              clock: fake.clock,
              initialMode: mode,
            ),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('the straight key still keys when the pane scrolls', (
      tester,
    ) async {
      setPhone(tester, kLandscapePhone);
      final fake = FakeReferencePlayer();
      await pumpScreen(
        tester,
        TranslatorScreen(
          playerFactory: fake.create,
          clock: fake.clock,
          initialMode: TranslatorMode.key,
        ),
      );
      final Finder key = find.byType(StraightKeyButton);
      await tester.ensureVisible(key);
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(tester.getCenter(key));
      await tester.pump();
      fake.clock.advance(const Duration(milliseconds: 60));
      await gesture.up();
      await tester.pump();
      expect(fake.onCount, 1);
    });
  });
}
