import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/groups/group_members_sheet.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_support.dart';

/// A page with one button that opens the members sheet for [group].
Widget _opener(ChatHarness h, Group group) => Scaffold(
  body: Builder(
    builder: (context) => Center(
      child: FilledButton(
        onPressed: () =>
            showGroupMembersSheet(context, service: h.service, group: group),
        child: const Text('open'),
      ),
    ),
  ),
);

void main() {
  testWidgets('lists every member with the self label and short keys', (
    tester,
  ) async {
    late Group group;
    await pumpChat(tester, (h) {
      group = h.service.addFakeGroup(
        const Group(id: 'tox_1', name: 'Net 40m', kind: GroupKind.group),
      );
      h.service.addFakeGroupMember(
        'tox_1',
        GroupMember(publicKey: kPeerKey, displayName: 'Ann', online: false),
      );
      return _opener(h, group);
    });
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(s.chatMembersTitleCount(2)), findsOneWidget);
    expect(find.text(s.chatMemberSelf('Me')), findsOneWidget);
    expect(find.text('Ann'), findsOneWidget);
    expect(find.text('${kPeerKey.substring(0, 16)}…'), findsOneWidget);
    // One dot per member, offline rendered in the outline colour.
    final List<CircleAvatar> dots = tester
        .widgetList<CircleAvatar>(find.byType(CircleAvatar))
        .toList();
    expect(dots, hasLength(2));
    expect(dots.map((d) => d.backgroundColor), contains(Colors.green));
    expect(dots.where((d) => d.backgroundColor != Colors.green), hasLength(1));
  });

  testWidgets('a group we no longer belong to shows the error text', (
    tester,
  ) async {
    await pumpChat(
      tester,
      (h) => _opener(
        h,
        const Group(id: 'tox_404', name: 'Gone', kind: GroupKind.group),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(s.errorGroupNotFound), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });
}
