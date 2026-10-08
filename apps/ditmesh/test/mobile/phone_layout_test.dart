// Phone-form-factor regressions: small portrait phones (320x568), phones in
// landscape (~375-390 px tall, notch + home-indicator insets), the soft
// keyboard covering half the screen, and a 2.0 text scale. Each case here
// overflowed (or lost state) before the fix it guards.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh/di/fake_backend_factory.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/main.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/ui/learn/learn_scope.dart';
import 'package:ditmesh/ui/account/backup_file_gateway.dart';
import 'package:ditmesh/ui/account/identity_card.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/learn/send/send_practice_screen.dart';
import 'package:ditmesh/ui/reference/reference_screen.dart';
import 'package:ditmesh/ui/reference/translator_screen.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';

import '../account/test_app.dart';
import '../chat/test_support.dart' as chat;
import '../learn/helpers/fake_playback.dart';
import '../learn/helpers/l10n.dart';
import '../learn/helpers/test_controller.dart';
import '../reference/reference_test_support.dart';

const Size kSmallPhone = Size(320, 568);
const Size kLandscapePhone = Size(844, 390);
const Size kLandscapeSmallPhone = Size(667, 375);

/// Sizes the view like a real phone: notch / home-indicator padding that
/// depends on orientation, an optional soft keyboard and a text scale.
void setPhone(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
  double keyboard = 0,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = _paddingFor(size);
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

FakeViewPadding _paddingFor(Size size) => size.width > size.height
    ? const FakeViewPadding(left: 47, right: 47, bottom: 21)
    : const FakeViewPadding(top: 47, bottom: 34);

Future<void> bootApp(WidgetTester tester) async {
  final identity = FakeIdentityService.withProfile(
    identity: Identity(
      toxId: FakeIdentityService.toxIdForSeed(1),
      displayName: 'Phone Tester',
    ),
    connectDelay: Duration.zero,
    dataDirectoryPath: freshDataDirectory(),
  );
  await tester.pumpWidget(
    DitmeshApp(
      backend: FakeBackendFactory(identityService: identity),
      backupFiles: FakeBackupFileGateway(),
      localeStore: acceptedTermsStore(),
    ),
  );
  await settle(tester);
}

Finder navLabel(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is NavigationBar || w is NavigationRail),
  matching: find.text(label),
);

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
      tester.view.padding = _paddingFor(kLandscapePhone);
      await settle(tester);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(tester.state(find.byType(ReferenceScreen)), same(before));

      tester.view.physicalSize = const Size(390, 844);
      tester.view.padding = _paddingFor(const Size(390, 844));
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

  group('learn placeholder', () {
    // Regression: the loading / identity-required placeholder was a fixed
    // Column and overflowed by 181 px on a 320 pt phone at 2x text; CI only
    // caught it when the controller load was slow enough to paint a frame.
    for (final bool loading in <bool>[true, false]) {
      testWidgets('${loading ? 'loading' : 'identity required'} fits a '
          '320 px phone at 2x text', (tester) async {
        setPhone(tester, kSmallPhone, textScale: 2);
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
        expect(
          find.text(en.learnIdentityRequired),
          loading ? findsOneWidget : findsNWidgets(2),
        );
      });
    }
  });

  group('send practice', () {
    for (final KeyerMode mode in <KeyerMode>[
      KeyerMode.straight,
      KeyerMode.iambicB,
    ]) {
      testWidgets('$mode app bar fits a 320 px phone at 2x text', (
        tester,
      ) async {
        setPhone(tester, kSmallPhone, textScale: 2);
        final t = await TestTraining.create(
          settings: TrainingSettings(keyerMode: mode),
        );
        addTearDown(t.controller.dispose);
        await tester.pumpWidget(
          l10nApp(
            home: SendPracticeScreen(
              controller: t.controller,
              playback: FakeLearnPlaybackFactory(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // The switch keeps its name even when the label becomes an icon.
        expect(
          tester.getSemantics(find.byType(Switch)),
          matchesSemantics(
            label: en.learnCopyFromMemory,
            hasToggledState: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(find.text(en.learnHiddenTarget), findsOneWidget);
      });
    }
  });

  group('send practice label', () {
    // Widget tests render Ahem (every glyph 1 em wide), so the cases keep a
    // clear margin; real-font frames come from tool/screenshots.
    final cases = <(String, Size, double, bool)>[
      // Regression: the fixed 420 threshold dropped the label on a 402 pt
      // iPhone although it fit.
      ('zh', const Size(402, 874), 1, true),
      ('en', const Size(600, 874), 1, true),
      ('de', kSmallPhone, 1.3, false),
      // Landscape: setPhone adds 47 pt notch insets per side; the label must
      // fit what is left, not the full width (else the title ellipsizes).
      ('en', const Size(560, 375), 1, true),
      ('en', const Size(450, 375), 1, false),
      ('en', kSmallPhone, 2, false),
    ];
    for (final (String lang, Size size, double scale, bool label) in cases) {
      testWidgets('$lang $size at ${scale}x shows '
          '${label ? 'the label' : 'the icon'}', (tester) async {
        setPhone(tester, size, textScale: scale);
        final t = await TestTraining.create();
        addTearDown(t.controller.dispose);
        await tester.pumpWidget(
          l10nApp(
            locale: Locale(lang),
            home: SendPracticeScreen(
              controller: t.controller,
              playback: FakeLearnPlaybackFactory(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final s = lookupS(Locale(lang));
        expect(
          find.text(s.learnCopyFromMemory),
          label ? findsOneWidget : findsNothing,
        );
        expect(
          find.byIcon(Icons.visibility_off_outlined),
          label ? findsNothing : findsOneWidget,
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
