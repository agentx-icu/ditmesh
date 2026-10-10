// T9 (mobile review): iOS "Larger Accessibility Sizes" reach ~3.1x and
// Android bold text adds width. The inherited 2x phone cases from
// phone_layout_test.dart are repeated at 3x; overflow is accepted only where
// a scroll view exists, so every case here must settle without an exception.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/ui/account/identity_card.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/learn/learn_scope.dart';
import 'package:ditmesh/ui/reference/translator_screen.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../account/test_app.dart';
import '../chat/test_support.dart' as chat;
import '../learn/helpers/l10n.dart';
import '../reference/reference_test_support.dart';
import 'phone_support.dart';

const double kAccessibilityScale = 3;

void main() {
  group('shell at 3x', () {
    testWidgets('bottom navigation fits a 320 px phone', (tester) async {
      setPhone(tester, kSmallPhone, textScale: kAccessibilityScale);
      await bootApp(tester);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(navLabel(en.navMe));
      await settle(tester);
      expect(find.byType(IdentityCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the rail fits a landscape phone', (tester) async {
      setPhone(tester, kLandscapePhone, textScale: kAccessibilityScale);
      await bootApp(tester);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(tester.takeException(), isNull);
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
      expect(tester.takeException(), isNull);
    });
  });

  group('learn placeholder at 3x', () {
    for (final bool loading in <bool>[true, false]) {
      testWidgets('${loading ? 'loading' : 'identity required'} fits a '
          '320 px phone', (tester) async {
        setPhone(tester, kSmallPhone, textScale: kAccessibilityScale);
        final Completer<TrainingController> never =
            Completer<TrainingController>();
        await tester.pumpWidget(
          l10nApp(
            home: LearnScope(
              controllerFactory: loading
                  ? (_) => never.future
                  : (_) => Future<TrainingController>.error('no identity'),
              description: en.learnIdentityRequired,
              builder: (_, _, _) => const SizedBox(),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('chat composer at 3x', () {
    for (final Size size in <Size>[
      kSmallPhone,
      kLandscapeSmallPhone,
      kLandscapePhone,
    ]) {
      for (final bool paddles in <bool>[false, true]) {
        testWidgets('${paddles ? 'paddles' : 'straight key'} fit $size', (
          tester,
        ) async {
          final h = chat.ChatHarness();
          addTearDown(h.dispose);
          setPhone(tester, size, textScale: kAccessibilityScale);
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
          // The composer is capped at 75 % of the height and scrolls: the
          // send button may start below the fold but must be reachable.
          final Finder send = find.byTooltip(chat.s.chatSend);
          await tester.ensureVisible(send);
          await tester.pumpAndSettle();
          expect(send.hitTestable(), findsOneWidget);
        });
      }
    }
  });

  group('translator at 3x', () {
    final cases = <(Size, double)>[
      (kSmallPhone, 0),
      (kSmallPhone, 260),
      (kLandscapePhone, 0),
      (kLandscapePhone, 200),
    ];
    for (final (Size size, double keyboard) in cases) {
      for (final TranslatorMode mode in TranslatorMode.values) {
        testWidgets('${mode.name} fits $size, keyboard $keyboard', (
          tester,
        ) async {
          setPhone(
            tester,
            size,
            textScale: kAccessibilityScale,
            keyboard: keyboard,
          );
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
  });
}
