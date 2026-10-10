// The Me page's About notes: the background-receiving note (Android and iOS
// only, a backgrounded phone is paused and stops receiving) and the
// screen-reader keying note (every platform).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/account/identity_card.dart';
import 'package:ditmesh/ui/pages/me_notes.dart';
import 'package:ditmesh/ui/pages/me_page.dart';

import '../learn/helpers/l10n.dart' show l10nApp;
import '../mobile/phone_support.dart';
import 'test_app.dart';

final S en = lookupS(const Locale('en'));

Finder get _background => find.byKey(const ValueKey('me-note-background'));
Finder get _screenReader => find.byKey(const ValueKey('me-note-screen-reader'));

Future<void> _openMe(WidgetTester tester) async {
  await tester.tap(navLabel(MePage.title(en)));
  await settle(tester);
  expect(find.byType(IdentityCard), findsOneWidget);
}

void main() {
  testWidgets(
    'phones show both notes in the About section',
    (tester) async {
      await pumpApp(tester, identity: seededIdentityService());
      await _openMe(tester);
      await tester.ensureVisible(_screenReader);
      await settle(tester);
      expect(find.text(en.meNoteBackgroundTitle), findsOneWidget);
      expect(find.text(en.meNoteBackgroundBody), findsOneWidget);
      expect(find.text(en.meNoteScreenReaderTitle), findsOneWidget);
      expect(find.text(en.meNoteScreenReaderBody), findsOneWidget);
      // Both sit under the About header, above the site links.
      final about = tester.getTopLeft(find.text(en.accountSectionAbout)).dy;
      expect(tester.getTopLeft(_background).dy, greaterThan(about));
      expect(
        tester.getTopLeft(_screenReader).dy,
        greaterThan(tester.getTopLeft(_background).dy),
      );
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets(
    'desktop shows only the screen-reader note',
    (tester) async {
      await pumpApp(
        tester,
        identity: seededIdentityService(),
        size: const Size(1280, 800),
      );
      await _openMe(tester);
      await tester.ensureVisible(_screenReader);
      await settle(tester);
      expect(find.text(en.meNoteScreenReaderBody), findsOneWidget);
      expect(_background, findsNothing);
      expect(find.text(en.meNoteBackgroundBody), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.desktop(),
  );

  testWidgets('the Me page with the notes fits a 320 px phone at 3x', (
    tester,
  ) async {
    setPhone(tester, kSmallPhone, textScale: 3);
    await bootApp(tester);
    await tester.tap(navLabel(en.navMe));
    await settle(tester);
    for (final Finder note in <Finder>[_background, _screenReader]) {
      await tester.ensureVisible(note);
      await settle(tester);
      expect(tester.takeException(), isNull);
      final Rect rect = tester.getRect(note);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(kSmallPhone.width));
    }
  });

  group('every locale fits 320 px at 2x', () {
    for (final Locale locale in S.supportedLocales) {
      testWidgets('$locale', (tester) async {
        setPhone(tester, kSmallPhone, textScale: 2);
        await tester.pumpWidget(
          l10nApp(
            locale: locale,
            home: const Scaffold(body: SingleChildScrollView(child: MeNotes())),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final S s = lookupS(locale);
        expect(find.text(s.meNoteBackgroundBody), findsOneWidget);
        expect(find.text(s.meNoteScreenReaderBody), findsOneWidget);
        if (locale.languageCode != 'en') {
          // Translated, not an English placeholder.
          expect(s.meNoteBackgroundBody, isNot(en.meNoteBackgroundBody));
          expect(s.meNoteScreenReaderBody, isNot(en.meNoteScreenReaderBody));
        }
      });
    }
  });
}
