import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/appearance/ui_style.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/chat/message_bubble.dart';
import 'package:ditmesh/ui/chat/morse_playback_controller.dart';
import 'package:ditmesh/ui/chat/morse_playback_settings.dart';
import 'package:ditmesh/ui/pages/groups_page.dart';
import 'package:ditmesh/ui/theme.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../chat/test_support.dart';

Widget _styledApp(
  ChatHarness harness,
  Widget child, {
  required ThemeData theme,
  required Locale locale,
  required double textScale,
}) => MultiProvider(
  providers: [
    Provider<ChatService>.value(value: harness.service),
    Provider<IdentityService>.value(value: harness.identity),
    ChangeNotifierProvider<MorsePlaybackSettings>.value(
      value: harness.settings,
    ),
    ChangeNotifierProvider<MorsePlaybackController>.value(
      value: harness.playback,
    ),
  ],
  child: MaterialApp(
    theme: theme,
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    locale: locale,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: child,
  ),
);

double _contrast(Color foreground, Color background) {
  final painted = Color.alphaBlend(foreground, background).computeLuminance();
  final base = background.computeLuminance();
  return painted > base
      ? (painted + 0.05) / (base + 0.05)
      : (base + 0.05) / (painted + 0.05);
}

void _expectReadableBubbles(WidgetTester tester) {
  final bubbles = find.byType(MessageBubble);
  expect(bubbles, findsNWidgets(2));
  for (final bubble in bubbles.evaluate()) {
    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byWidget(bubble.widget),
            matching: find.byType(Material),
          )
          .first,
    );
    final text = tester.widget<SelectableText>(
      find.descendant(
        of: find.byWidget(bubble.widget),
        matching: find.byType(SelectableText),
      ),
    );
    expect(
      _contrast(text.style!.color!, material.color!),
      greaterThanOrEqualTo(4.5),
    );
  }
}

void main() {
  var languageIndex = 0;
  for (final style in UiStyle.values) {
    for (final dark in [false, true]) {
      for (final phone in [true, false]) {
        final locale =
            S.supportedLocales[languageIndex++ % S.supportedLocales.length];
        final strings = lookupS(locale);
        final theme = dark
            ? DitmeshTheme.dark(style: style)
            : DitmeshTheme.light(style: style);
        final size = phone ? const Size(320, 740) : kDesktop;
        final label =
            '${style.name}/${dark ? 'dark' : 'light'}/'
            '${phone ? 'phone-large-text' : 'desktop'}/${locale.toLanguageTag()}';
        for (final group in [false, true]) {
          testWidgets(
            'Morse-only ${group ? 'group' : 'DM'} remains usable: $label',
            (tester) async {
              tester.view.physicalSize = size;
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              final harness = ChatHarness();
              addTearDown(harness.dispose);
              late final ConversationTarget target;
              if (group) {
                final joined = harness.service.addFakeGroup(
                  const Group(
                    id: 'tox_1',
                    name: 'Net 40m',
                    kind: GroupKind.group,
                  ),
                );
                target = ConversationTarget.fromGroup(joined);
              } else {
                harness.addAnn(online: true, withMessage: false);
                target = ConversationTarget(
                  id: 'c2c_$kPeerKey',
                  title: 'Ann',
                  kind: ConversationKind.c2c,
                );
              }
              harness.service.receiveMessage(
                target.id,
                'CQ DE ANN',
                senderId: kPeerKey,
                senderName: 'Ann',
              );
              if (group) {
                await tester.pumpWidget(
                  _styledApp(
                    harness,
                    const GroupsPage(),
                    theme: theme,
                    locale: locale,
                    textScale: phone ? 1.6 : 1,
                  ),
                );
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                await tester.tap(find.text('Net 40m'));
                await tester.pumpAndSettle();
              } else {
                await tester.pumpWidget(
                  _styledApp(
                    harness,
                    ConversationScreen(target: target),
                    theme: theme,
                    locale: locale,
                    textScale: phone ? 1.6 : 1,
                  ),
                );
                await tester.pumpAndSettle();
              }
              expect(find.byType(ConversationScreen), findsOneWidget);
              expect(
                tester.widget<TextField>(find.byType(TextField)).readOnly,
                isTrue,
              );
              expect(
                find.byTooltip(strings.chatSend).hitTestable(),
                findsOneWidget,
              );
              expect(tester.takeException(), isNull);
              await keyIn(tester, 'K');
              await tester.tap(find.byTooltip(strings.chatSend));
              await tester.pumpAndSettle();
              expect(find.byIcon(Icons.check), findsOneWidget);
              expect(find.text('-.-'), findsOneWidget);
              _expectReadableBubbles(tester);
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox());
              await tester.pump();
            },
          );
        }
      }
    }
  }
}
