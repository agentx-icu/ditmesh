import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ditmesh/desktop/shortcuts.dart';
import 'package:ditmesh/ui/chat/conversation_list.dart';
import 'package:ditmesh/ui/contacts/contacts_page.dart';
import 'package:ditmesh/ui/pages/groups_page.dart';
import 'package:ditmesh/ui/shell/shell_router.dart';

import '../account/test_app.dart';

Future<void> _pump(WidgetTester tester, TargetPlatform platform) async {
  expect(defaultTargetPlatform, platform);
  await pumpApp(tester, identity: seededIdentityService(), size: kDesktopSize);
}

LogicalKeyboardKey _primary(TargetPlatform platform) =>
    usesCommandModifier(platform)
    ? LogicalKeyboardKey.metaLeft
    : LogicalKeyboardKey.controlLeft;

Future<void> _chord(
  WidgetTester tester,
  LogicalKeyboardKey modifier,
  LogicalKeyboardKey key, {
  bool repeat = false,
}) async {
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyDownEvent(key);
  if (repeat) await tester.sendKeyRepeatEvent(key);
  await tester.sendKeyUpEvent(key);
  await tester.sendKeyUpEvent(modifier);
  await settle(tester);
}

SearchBar _search(WidgetTester tester) =>
    tester.widget<SearchBar>(find.byType(SearchBar, skipOffstage: false));

ShellRouter _router(WidgetTester tester) =>
    tester.element(find.byType(ConversationList)).read<ShellRouter>();

void main() {
  for (final platform in [
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
  ]) {
    group('$platform active shell keyboard events', () {
      void platformTest(
        String name,
        Future<void> Function(WidgetTester) body,
      ) => testWidgets(
        name,
        body,
        variant: TargetPlatformVariant.only(platform),
      );
      platformTest('only the primary modifier focuses search once', (
        tester,
      ) async {
        await _pump(tester, platform);
        final label = usesCommandModifier(platform) ? '⌘N' : 'Ctrl+N';
        expect(find.byTooltip('Contacts ($label)'), findsOneWidget);
        final primary = _primary(platform);
        final wrong = primary == LogicalKeyboardKey.metaLeft
            ? LogicalKeyboardKey.controlLeft
            : LogicalKeyboardKey.metaLeft;
        var requests = 0;
        final subscription = _router(
          tester,
        ).searchRequests.listen((_) => requests++);
        addTearDown(subscription.cancel);
        await _chord(tester, wrong, LogicalKeyboardKey.keyK);
        expect(_search(tester).focusNode!.hasFocus, isFalse);
        expect(requests, 0);
        await _chord(tester, primary, LogicalKeyboardKey.keyK, repeat: true);
        expect(requests, 1);
        expect(_search(tester).focusNode!.hasFocus, isTrue);
        expect(find.byType(ContactsPage), findsNothing);
      });

      platformTest('new message opens contacts once and preserves route', (
        tester,
      ) async {
        await _pump(tester, platform);
        var requests = 0;
        final subscription = _router(
          tester,
        ).contactsRequests.listen((_) => requests++);
        addTearDown(subscription.cancel);
        final primary = _primary(platform);
        final wrong = primary == LogicalKeyboardKey.metaLeft
            ? LogicalKeyboardKey.controlLeft
            : LogicalKeyboardKey.metaLeft;
        await _chord(tester, wrong, LogicalKeyboardKey.keyN);
        expect(requests, 0);
        expect(find.byType(ContactsPage), findsNothing);
        await _chord(tester, primary, LogicalKeyboardKey.keyN, repeat: true);
        expect(requests, 1);
        expect(find.byType(ContactsPage, skipOffstage: false), findsOneWidget);
        // Commands do not target the covered shell, even if repeated.
        await _chord(tester, primary, LogicalKeyboardKey.keyN);
        await _chord(tester, primary, LogicalKeyboardKey.keyK);
        expect(requests, 1);
        expect(find.byType(ContactsPage, skipOffstage: false), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await settle(tester);
        expect(find.byType(ConversationList), findsOneWidget);
        expect(find.byType(ContactsPage, skipOffstage: false), findsNothing);
      });

      platformTest('search selects the chat tab before focusing its field', (
        tester,
      ) async {
        await _pump(tester, platform);
        await _chord(tester, _primary(platform), LogicalKeyboardKey.keyK);
        await tester.enterText(find.byType(TextField).first, 'saved search');
        await tester.tap(find.byIcon(Icons.groups_outlined).first);
        await settle(tester);
        expect(find.byType(GroupsPage), findsOneWidget);
        await _chord(tester, _primary(platform), LogicalKeyboardKey.keyK);
        expect(find.byType(ConversationList), findsOneWidget);
        expect(find.byType(GroupsPage), findsNothing);
        expect(_search(tester).focusNode!.hasFocus, isTrue);
        expect(_search(tester).controller!.text, 'saved search');
      });

      platformTest('new message reuses contacts above the selected chat tab', (
        tester,
      ) async {
        await _pump(tester, platform);
        await tester.tap(find.byIcon(Icons.groups_outlined).first);
        await settle(tester);
        await _chord(tester, _primary(platform), LogicalKeyboardKey.keyN);
        expect(find.byType(ContactsPage, skipOffstage: false), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await settle(tester);
        expect(find.byType(ConversationList), findsOneWidget);
        expect(find.byType(GroupsPage), findsNothing);
      });

      platformTest('focused editor keeps text and IME composition', (
        tester,
      ) async {
        await _pump(tester, platform);
        await tester.tap(find.byType(SearchBar));
        await tester.pump();
        final search = _search(tester);
        const composing = TextEditingValue(
          text: 'ni',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 0, end: 2),
        );
        tester.testTextInput.updateEditingValue(composing);
        await tester.pump();
        await _chord(tester, _primary(platform), LogicalKeyboardKey.keyN);
        await _chord(tester, _primary(platform), LogicalKeyboardKey.keyK);
        expect(find.byType(ContactsPage), findsNothing);
        expect(search.focusNode!.hasFocus, isTrue);
        expect(search.controller!.value, composing);
        // A committed edit remains local too; no plain-letter app command.
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: 'nearby',
            selection: TextSelection.collapsed(offset: 6),
          ),
        );
        await tester.pump();
        await _chord(tester, _primary(platform), LogicalKeyboardKey.keyN);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
        await tester.pump();
        expect(find.byType(ContactsPage), findsNothing);
        expect(search.controller!.text, 'nearby');
      });
    });
  }

  testWidgets(
    'a covering dialog retains input and is not dismissed',
    (tester) async {
      await _pump(tester, TargetPlatform.linux);
      final context = tester.element(find.byType(ConversationList));
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) =>
              const AlertDialog(content: TextField(autofocus: true)),
        ),
      );
      await settle(tester);
      await _chord(
        tester,
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.keyN,
      );
      await _chord(
        tester,
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.keyK,
      );
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(ContactsPage, skipOffstage: false), findsNothing);
      expect(_search(tester).focusNode!.hasFocus, isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}
