// Layout review (2026-10-09): one fast case per defect the layout crawl
// (layout_crawl_test.dart, opt-in) found, at the window profile where it
// showed. Each failed before its fix.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/account/delete_identity_dialog.dart';
import 'package:ditmesh/ui/chat/conversation_header.dart';
import 'package:ditmesh/ui/chat/conversation_list.dart';
import 'package:ditmesh/ui/chat/conversation_tile.dart';
import 'package:ditmesh/ui/chat/message_input.dart';
import 'package:ditmesh/ui/common/app_bar_title.dart';
import 'package:ditmesh/ui/common/field_label.dart';
import 'package:ditmesh/ui/contacts/contacts_page.dart';
import 'package:ditmesh/ui/contacts/my_tox_id_sheet.dart';
import 'package:ditmesh/ui/learn/goal_ring.dart';
import 'package:ditmesh/ui/learn/receive/answer_keypad.dart';
import 'package:ditmesh/ui/learn/receive/receive_widgets.dart';
import 'package:ditmesh/ui/learn/settings/training_settings_screen.dart';
import 'package:ditmesh/ui/listen/listen_screen.dart';
import 'package:ditmesh/ui/listen/listen_widgets.dart';
import 'package:ditmesh/ui/pages/placeholder_page.dart';
import 'package:ditmesh/ui/reference/morse_to_text_view.dart';
import 'package:ditmesh/ui/reference/playback_settings_sheet.dart';
import 'package:ditmesh/ui/reference/reference_playback_settings.dart';
import 'package:ditmesh/ui/shell/app_shell.dart';
import 'package:ditmesh/ui/stats/char_grid.dart';
import 'package:ditmesh/ui/theme.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';

import '../account/test_app.dart' show settle;
import '../chat/test_support.dart' as chat;
import '../learn/helpers/fake_playback.dart';
import '../learn/helpers/test_controller.dart';
import '../listen/fake_pcm_source.dart';
import 'layout_profiles.dart';
import 'seeded_app.dart';

/// [home] in the app's theme and [locale], under [profile].
Future<void> _pump(
  WidgetTester tester,
  LayoutProfile profile,
  Widget home, {
  ThemeData? theme,
}) async {
  applyProfile(tester, profile);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: Locale(profile.locale),
      theme: theme ?? DitmeshTheme.light(),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

/// A page whose button runs [open] (a sheet or a dialog) with its context.
Widget _opener(void Function(BuildContext context) open) => Scaffold(
  body: Builder(
    builder: (context) => Center(
      child: TextButton(
        onPressed: () => open(context),
        child: const Text('open'),
      ),
    ),
  ),
);

void _expectInside(WidgetTester tester, Finder inner, Rect outer) {
  final Rect r = tester.getRect(inner);
  expect(
    r.left >= outer.left - 0.5 &&
        r.top >= outer.top - 0.5 &&
        r.right <= outer.right + 0.5 &&
        r.bottom <= outer.bottom + 0.5,
    isTrue,
    reason: '$r inside $outer',
  );
}

/// [text] is drawn whole (its paragraph is not cut to a smaller box than
/// the text needs) and inside [outer]; on one line unless it [wraps].
void _expectTextFits(
  WidgetTester tester,
  Finder text,
  Rect outer, {
  bool wraps = false,
}) {
  _expectInside(tester, text, outer);
  final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(text);
  if (!wraps) {
    expect(
      paragraph.size.width,
      greaterThanOrEqualTo(
        paragraph.getMaxIntrinsicWidth(double.infinity) - 0.5,
      ),
      reason: 'cut sideways',
    );
  }
  expect(
    paragraph.size.height,
    greaterThanOrEqualTo(
      paragraph.getMaxIntrinsicHeight(paragraph.size.width) - 0.5,
    ),
    reason: 'cut at the bottom',
  );
}

const LayoutProfile _phone2x = LayoutProfile(
  'phone-2x',
  Size(390, 844),
  dpr: 3,
  padding: FakeViewPadding(top: 47, bottom: 34),
  textScale: 2,
);

void main() {
  group('listen', () {
    for (final LayoutProfile profile in <LayoutProfile>[
      for (final String name in <String>[
        'phone-small',
        'phone-small-de',
        'phone-landscape-keyboard',
        'android-split',
        'phone-large-text',
      ])
        profileNamed(name),
      // The "decoded" header label next to the copy button (Codex review).
      const LayoutProfile(
        'phone-small-ru-3x',
        Size(320, 568),
        padding: FakeViewPadding(top: 24, bottom: 48),
        textScale: 3,
        locale: 'ru',
      ),
    ]) {
      testWidgets('a refused start keeps the screen in one piece at '
          '${profile.name}', (tester) async {
        await _pump(
          tester,
          profile,
          ListenScreen(source: FakePcmSource(permissionGranted: false)),
        );
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(MaterialBanner), findsOneWidget);
        // The decoded text keeps a usable height; the page scrolls instead.
        expect(
          tester.getSize(find.byType(ListenDecodedText)).height,
          greaterThanOrEqualTo(160 * profile.textScale - 0.5),
        );
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('sheets and dialogs', () {
    for (final String name in <String>[
      'phone-landscape-keyboard',
      'phone-large-text',
    ]) {
      testWidgets('reference playback settings scroll at $name', (
        tester,
      ) async {
        final settings = ReferencePlaybackSettings(farnsworthWpm: 8);
        addTearDown(settings.dispose);
        await _pump(
          tester,
          profileNamed(name),
          _opener((c) => showReferencePlaybackSettings(c, settings)),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final Finder last = find.byType(Slider).last;
        await tester.ensureVisible(last);
        await tester.pumpAndSettle();
        expect(last.hitTestable(), findsOneWidget);
      });
    }

    testWidgets('delete identity fits a landscape phone with the keyboard up', (
      tester,
    ) async {
      await _pump(
        tester,
        profileNamed('phone-landscape-keyboard'),
        _opener(confirmDeleteIdentity),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField).hitTestable(), findsOneWidget);
    });

    testWidgets('a dialog stops at 560 px on an ultrawide monitor', (
      tester,
    ) async {
      await _pump(
        tester,
        profileNamed('desktop-ultrawide'),
        _opener(confirmDeleteIdentity),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final Finder surface = find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Material),
          )
          .first;
      expect(tester.getSize(surface).width, lessThanOrEqualTo(560));
    });

    testWidgets('my Tox ID QR code fits a landscape phone', (tester) async {
      final LayoutProfile profile = profileNamed('phone-landscape');
      await _pump(
        tester,
        profile,
        _opener(
          (c) => showMyToxIdSheet(
            c,
            Identity(
              toxId: FakeIdentityService.toxIdForSeed(1),
              displayName: 'Ann',
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final Finder qr = find.byType(QrImageView);
      await tester.ensureVisible(qr);
      await tester.pumpAndSettle();
      _expectInside(tester, qr, Offset.zero & profile.size);
    });
  });

  group('shell', () {
    testWidgets('a pushed page keeps its rows clear of the landscape notch', (
      tester,
    ) async {
      final LayoutProfile profile = profileNamed('phone-landscape');
      applyProfile(tester, profile);
      await pumpSeededApp(tester);
      await tester.tap(find.byIcon(Icons.people_outline));
      await settle(tester);
      expect(find.byType(ContactsPage), findsOneWidget);
      final Finder tiles = find.descendant(
        of: find.byType(ContactsPage),
        matching: find.byType(ListTile),
      );
      expect(tiles, findsWidgets);
      for (final Element tile in tiles.evaluate()) {
        final Rect r = tester.getRect(
          find.byElementPredicate((e) => e == tile),
        );
        expect(r.left, greaterThanOrEqualTo(profile.padding.left));
        expect(
          r.right,
          lessThanOrEqualTo(profile.size.width - profile.padding.right),
        );
      }
      // The shell's rail still runs under the notch: edge_to_edge_test.dart.
    });

    testWidgets('the chat list keeps its height beside the rail with the '
        'keyboard up', (tester) async {
      // The rail layout's inset handling once re-read the keyboard inset
      // above the Scaffold and the list collapsed to nothing.
      applyProfile(tester, profileNamed('phone-landscape-keyboard'));
      await pumpSeededApp(tester);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(
        tester.getSize(find.byType(ConversationList)).height,
        greaterThan(72),
      );
      expect(find.byType(ConversationTile).hitTestable(), findsWidgets);
    });

    testWidgets('conversation rows fit a 320 px phone at 2x', (tester) async {
      // The name, the "Me" badge and the time did not fit beside the unread
      // badge and the menu: the time now moves under the name.
      applyProfile(
        tester,
        const LayoutProfile('phone-small-2x', Size(320, 568), textScale: 2),
      );
      await pumpSeededApp(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(ConversationTile), findsWidgets);
    });

    testWidgets('lists and the composer stop at a readable width', (
      tester,
    ) async {
      applyProfile(tester, profileNamed('desktop-ultrawide'));
      final seed = await pumpSeededApp(tester);
      await tester.tap(find.byKey(ValueKey<String>(seed.qsoConversationId)));
      await settle(tester);
      expect(
        tester.getSize(find.byType(MessageInput)).width,
        lessThanOrEqualTo(960),
      );
      await tester.tap(find.byIcon(Icons.people_outline));
      await settle(tester);
      for (final Element tile
          in find
              .descendant(
                of: find.byType(ContactsPage),
                matching: find.byType(ListTile),
              )
              .evaluate()) {
        expect(
          tester.getSize(find.byElementPredicate((e) => e == tile)).width,
          lessThanOrEqualTo(720),
        );
      }
    });

    testWidgets('German bottom-bar labels stay above the home indicator at '
        '2x on a 320 px phone', (tester) async {
      const LayoutProfile profile = LayoutProfile(
        'phone-small-de-2x',
        Size(320, 568),
        dpr: 2,
        padding: FakeViewPadding(top: 24, bottom: 34),
        textScale: 2,
        locale: 'de',
      );
      applyProfile(tester, profile);
      await pumpSeededApp(tester, locale: 'de');
      final double bottom = profile.size.height - profile.padding.bottom;
      final S de = lookupS(const Locale('de'));
      for (final ShellDestination d in kShellDestinations) {
        final Finder label = find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(d.label(de)),
        );
        expect(tester.getRect(label).bottom, lessThanOrEqualTo(bottom));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('the two-line conversation title stays below the status bar '
        'at 2x', (tester) async {
      applyProfile(tester, _phone2x);
      final seed = await pumpSeededApp(tester);
      await tester.tap(find.byKey(ValueKey<String>(seed.qsoConversationId)));
      await settle(tester);
      expect(
        tester.getRect(find.byType(ConversationTitle)).top,
        greaterThanOrEqualTo(_phone2x.padding.top),
      );
    });
  });

  group('training widgets', () {
    testWidgets('the goal ring keeps "100%" inside at 3x', (tester) async {
      await _pump(
        tester,
        const LayoutProfile('phone-3x', Size(390, 844), textScale: 3),
        const Scaffold(
          body: Center(
            child: GoalRing(fraction: 1, size: 72, child: Text('100%')),
          ),
        ),
      );
      _expectTextFits(
        tester,
        find.text('100%'),
        tester.getRect(find.byType(GoalRing)),
      );
    });

    testWidgets('the answer keypad wraps on a 320 px phone in German at 3x', (
      tester,
    ) async {
      await _pump(
        tester,
        const LayoutProfile(
          'phone-small-de-3x',
          Size(320, 568),
          textScale: 3,
          locale: 'de',
        ),
        Scaffold(
          body: SingleChildScrollView(
            child: AnswerKeypad(
              chars: const <String>['K', 'M', 'R', 'S', 'U'],
              onChar: (_) {},
              onBackspace: () {},
              onSpace: () {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('training settings fit a 320 px phone at 3x', (tester) async {
      final TestTraining t = await TestTraining.create();
      addTearDown(t.controller.dispose);
      await _pump(
        tester,
        const LayoutProfile('phone-small-3x', Size(320, 568), textScale: 3),
        TrainingSettingsScreen(
          controller: t.controller,
          playback: FakeLearnPlaybackFactory(),
        ),
      );
      // Every tile, not only the ones a lazy list builds on the first screen.
      for (var i = 0; i < 12; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the receive status and Replay share a 320 px row in German '
        'by wrapping', (tester) async {
      await _pump(
        tester,
        const LayoutProfile(
          'phone-small-de-2x',
          Size(320, 568),
          textScale: 2,
          locale: 'de',
        ),
        Scaffold(
          body: PlaybackStatusRow(
            playing: true,
            onReplay: () {},
            replayLabel: lookupS(const Locale('de')).learnReplay,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final S de = lookupS(const Locale('de'));
      _expectTextFits(
        tester,
        find.text(de.learnListen),
        Offset.zero & const Size(320, 568),
        wraps: true,
      );
    });

    test('the playing status is a whole word in every language', () {
      for (final Locale locale in S.supportedLocales) {
        final String status = lookupS(locale).learnListen;
        expect(status, isNot(endsWith('...')), reason: '$locale');
        expect(status, isNot(endsWith('…')), reason: '$locale');
      }
    });

    testWidgets('a prosign cell keeps <BT> whole at 3x', (tester) async {
      await _pump(
        tester,
        const LayoutProfile('phone-3x-plain', Size(390, 844), textScale: 3),
        const Scaffold(
          body: Center(
            child: CharCell(
              char: '<BT>',
              stats: CharStats(attempts: 3, correct: 3),
              learned: true,
            ),
          ),
        ),
      );
      _expectTextFits(
        tester,
        find.text('<BT>'),
        tester.getRect(find.byType(CharCell)),
      );
    });

    testWidgets('a character cell grows with the text at 2x', (tester) async {
      await _pump(
        tester,
        const LayoutProfile('phone-2x-plain', Size(390, 844), textScale: 2),
        const Scaffold(
          body: Center(
            child: CharCell(
              char: 'K',
              stats: CharStats(attempts: 12, correct: 10),
              learned: true,
            ),
          ),
        ),
      );
      _expectTextFits(
        tester,
        find.text('K'),
        tester.getRect(find.byType(CharCell)),
      );
    });
  });
  group('truncated text', () {
    /// Fails when [text]'s paragraph lost lines or ended in an ellipsis.
    void expectWhole(WidgetTester tester, Finder text) {
      for (final Element e in text.evaluate()) {
        final RenderObject? r = e.renderObject;
        if (r is RenderParagraph) {
          expect(r.didExceedMaxLines, isFalse, reason: r.text.toPlainText());
        }
      }
    }

    // 2x, not 3x: the test font's square glyphs make even "Search" wider
    // than the bar at 3x; real fonts fit it.
    testWidgets('the chat search falls back to a short hint on a 320 px '
        'phone at 2x', (tester) async {
      applyProfile(
        tester,
        const LayoutProfile('phone-small-2x', Size(320, 568), textScale: 2),
      );
      await pumpSeededApp(tester);
      expect(tester.takeException(), isNull);
      final Finder hint = find.descendant(
        of: find.byType(SearchBar),
        matching: find.byType(Text),
      );
      expect(hint, findsWidgets);
      expectWhole(tester, hint);
    });

    testWidgets('an old date under a conversation name stays whole beside a '
        '99+ badge at 2x', (tester) async {
      final h = chat.ChatHarness()..addAnn();
      addTearDown(h.dispose);
      final String id = 'c2c_${chat.kPeerKey}';
      for (var i = 0; i < 120; i++) {
        h.service.receiveMessage(id, 'CQ', timestamp: DateTime(2025, 9, 30));
      }
      applyProfile(
        tester,
        const LayoutProfile('phone-small-2x', Size(320, 568), textScale: 2),
      );
      await tester.pumpWidget(
        h.wrap(
          Scaffold(
            body: ConversationTile(
              conversation: h.service.conversations.firstWhere(
                (c) => c.id == id,
              ),
              selected: false,
              onTap: () {},
              onAction: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final Finder date = find.textContaining('2025');
      expect(date, findsOneWidget);
      expectWhole(tester, date);
    });

    testWidgets('the Morse input instructions stay whole in German at 2x on '
        'a 320 px phone', (tester) async {
      await _pump(
        tester,
        const LayoutProfile(
          'phone-small-de-2x',
          Size(320, 568),
          textScale: 2,
          locale: 'de',
        ),
        const Scaffold(body: MorseToTextView()),
      );
      final S de = lookupS(const Locale('de'));
      expectWhole(tester, find.text(de.referencePatternInputHint));
    });

    testWidgets('a long field label scales instead of ending in an ellipsis', (
      tester,
    ) async {
      await _pump(
        tester,
        const LayoutProfile(
          'phone-small-de-3x',
          Size(320, 568),
          textScale: 3,
          locale: 'de',
        ),
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                label: FieldLabel('Sicherungs-Passphrase wiederholen'),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
      );
      expectWhole(tester, find.text('Sicherungs-Passphrase wiederholen'));
      _expectInside(
        tester,
        find.text('Sicherungs-Passphrase wiederholen'),
        tester.getRect(find.byType(TextField)),
      );
    });

    testWidgets('a field error wraps on a 320 px phone', (tester) async {
      const String error = 'Tox ID must be exactly 76 hex characters';
      await _pump(
        tester,
        const LayoutProfile('phone-small', Size(320, 568)),
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: TextField(decoration: InputDecoration(errorText: error)),
          ),
        ),
      );
      expectWhole(tester, find.text(error));
    });

    for (final (int actions, bool centred) in <(int, bool)>[
      (0, true),
      (2, false),
    ]) {
      testWidgets('a wrapped app-bar title on iOS with $actions actions sits '
          '${centred ? 'centred' : 'at the start'}, like a one-line one', (
        tester,
      ) async {
        const String title = 'Ausstehende und fehlgeschlagene Nachrichten';
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
            home: Scaffold(
              appBar: AppBar(
                title: const AppBarTitle(title),
                actions: <Widget>[
                  for (var i = 0; i < actions; i++)
                    IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
                ],
              ),
            ),
          ),
        );
        final Rect text = tester.getRect(find.text(title));
        if (centred) {
          expect((text.center.dx - 160).abs(), lessThan(2));
        } else {
          expect(text.left, lessThan(NavigationToolbar.kMiddleSpacing + 2));
        }
      });
    }

    testWidgets('a long app-bar title stays whole on a 320 px phone in '
        'German at 2x', (tester) async {
      await _pump(
        tester,
        const LayoutProfile(
          'phone-small-de-2x',
          Size(320, 568),
          textScale: 2,
          locale: 'de',
        ),
        const PlaceholderPage(
          title: 'Ausstehende und fehlgeschlagene Nachrichten',
          description: 'x',
          icon: Icons.schedule,
        ),
      );
      expectWhole(
        tester,
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Ausstehende und fehlgeschlagene Nachrichten'),
        ),
      );
    });
  });
}
