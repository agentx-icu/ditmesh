import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/groups/group_list.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_support.dart';

/// The group list with one NGC group (has a chat id) and one conference.
Future<(ChatHarness, List<Group>)> _pump(WidgetTester tester) async {
  final List<Group> opened = <Group>[];
  final ChatHarness h = await pumpChat(tester, (h) {
    h.service.addFakeGroup(
      Group(
        id: 'tox_1',
        name: 'Net 40m',
        kind: GroupKind.group,
        chatId: 'C' * 64,
      ),
    );
    h.service.addFakeGroup(
      const Group(id: 'tox_2', name: 'Old net', kind: GroupKind.conference),
    );
    return Scaffold(
      body: GroupList(service: h.service, onOpen: opened.add),
    );
  });
  return (h, opened);
}

void main() {
  testWidgets('tapping a group opens it; a conference carries its badge', (
    tester,
  ) async {
    final (_, opened) = await _pump(tester);
    expect(find.text('Net 40m'), findsOneWidget);
    expect(find.textContaining(s.chatConferenceBadge), findsOneWidget);
    await tester.tap(find.text('Net 40m'));
    expect(opened.map((g) => g.id), ['tox_1']);
  });

  testWidgets('the overflow menu offers copy only for NGC groups', (
    tester,
  ) async {
    await _pump(tester);
    // Groups are sorted by name: "Net 40m" first, "Old net" second.
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    expect(find.text(s.chatMembers), findsOneWidget);
    expect(find.text(s.chatCopyChatId), findsOneWidget);
    expect(find.text(s.chatLeaveGroup), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>).last);
    await tester.pumpAndSettle();
    expect(find.text(s.chatMembers), findsOneWidget);
    expect(find.text(s.chatCopyChatId), findsNothing);
    expect(find.text(s.chatLeaveGroup), findsOneWidget);
  });

  testWidgets('copy puts the chat id on the clipboard and confirms', (
    tester,
  ) async {
    final List<MethodCall> calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
    await _pump(tester);
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatCopyChatId));
    await tester.pumpAndSettle();
    final MethodCall copy = calls.singleWhere(
      (c) => c.method == 'Clipboard.setData',
    );
    expect((copy.arguments as Map<Object?, Object?>)['text'], 'C' * 64);
    expect(find.text(s.chatCopied), findsOneWidget);
  });

  testWidgets('members opens the members sheet', (tester) async {
    await _pump(tester);
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatMembers));
    await tester.pumpAndSettle();
    expect(find.text(s.chatMembersTitleCount(1)), findsOneWidget);
    expect(find.text(s.chatMemberSelf('Me')), findsOneWidget);
  });

  testWidgets('leave asks first; cancel keeps, confirm removes', (
    tester,
  ) async {
    final (h, _) = await _pump(tester);
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatLeaveGroup));
    await tester.pumpAndSettle();
    expect(find.text(s.chatLeaveGroupTitle), findsOneWidget);
    await tester.tap(find.text(s.actionCancel));
    await tester.pumpAndSettle();
    expect(h.service.groups.map((g) => g.id), containsAll(['tox_1', 'tox_2']));

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatLeaveGroup));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatLeave));
    await tester.pumpAndSettle();
    expect(h.service.groups.map((g) => g.id), ['tox_2']);
    expect(find.text('Net 40m'), findsNothing);
  });

  testWidgets('a failed leave surfaces the error in a snack bar', (
    tester,
  ) async {
    final (h, _) = await _pump(tester);
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatLeaveGroup));
    await tester.pumpAndSettle();
    expect(find.text(s.chatLeaveGroupTitle), findsOneWidget);
    // The group goes away underneath the dialog (another device left it),
    // so confirming now makes leaveGroup throw group_not_found.
    await h.service.leaveGroup('tox_1');
    await tester.pump();
    await tester.tap(find.text(s.chatLeave));
    await tester.pumpAndSettle();
    expect(find.text(s.errorGroupNotFound), findsOneWidget);
    expect(h.service.groups.map((g) => g.id), ['tox_2']);
  });

  testWidgets('long press opens the same actions as a context menu', (
    tester,
  ) async {
    await _pump(tester);
    await tester.longPress(find.text('Net 40m'));
    await tester.pumpAndSettle();
    expect(find.text(s.chatMembers), findsOneWidget);
    expect(find.text(s.chatCopyChatId), findsOneWidget);
    await tester.tap(find.text(s.chatMembers));
    await tester.pumpAndSettle();
    expect(find.text(s.chatMembersTitleCount(1)), findsOneWidget);
  });
}
