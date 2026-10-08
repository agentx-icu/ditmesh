// T6 (mobile review): the group members sheet on a 320 px phone at 2x and
// 3x text. The sheet's list scrolls, so overflow is not the question; the
// last member's menu must still end above the home indicator (the sheet is
// edge-to-edge) and the member rows must settle without an exception.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/groups/group_members_sheet.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../chat/test_support.dart';
import 'phone_support.dart';

const int kMembers = 6;

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
  for (final double scale in <double>[2, 3]) {
    testWidgets('member menus stay above the home indicator at ${scale}x', (
      tester,
    ) async {
      setPhone(tester, kSmallPhone, textScale: scale);
      late Group group;
      await pumpChat(tester, (h) {
        group = h.service.addFakeGroup(
          const Group(id: 'tox_1', name: 'Net 40m', kind: GroupKind.group),
        );
        for (int i = 0; i < kMembers; i++) {
          h.service.addFakeGroupMember(
            'tox_1',
            GroupMember(
              publicKey: '${'A' * 63}$i',
              displayName: 'Member $i',
              online: i.isEven,
            ),
          );
        }
        return _opener(h, group);
      }, size: kSmallPhone);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Scroll the list to its very end: the last row then sits at the
      // sheet's bottom edge, which is the screen's bottom edge.
      final Finder list = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Scrollable),
      );
      final Finder lastMenu = find.byKey(
        ValueKey<String>('member-menu-${'A' * 63}${kMembers - 1}'),
      );
      await tester.scrollUntilVisible(lastMenu, 100, scrollable: list);
      await tester.drag(list, const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(lastMenu, findsOneWidget);
      expect(
        tester.getRect(lastMenu).bottom,
        lessThanOrEqualTo(kSmallPhone.height - phonePaddingFor(kSmallPhone).bottom),
      );
      expect(lastMenu.hitTestable(), findsOneWidget);
    });
  }
}
