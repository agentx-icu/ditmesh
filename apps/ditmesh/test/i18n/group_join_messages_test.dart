import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/groups/group_join_feedback.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

/// Every locale tells the group-join refusals apart and names the group.
void main() {
  const String name = 'NET-40';
  final List<GroupJoinRefusal> refusals = <GroupJoinRefusal>[
    for (final GroupJoinRefusalReason r in GroupJoinRefusalReason.values)
      GroupJoinRefusal(groupId: 'tox_1', groupName: name, reason: r),
    const GroupJoinRefusal(
      groupId: 'tox_1',
      groupName: name,
      reason: GroupJoinRefusalReason.invalidPassword,
      established: true,
    ),
  ];

  for (final Locale locale in S.supportedLocales) {
    test('$locale', () {
      final S s = lookupS(locale);
      final List<String> texts = <String>[
        for (final GroupJoinRefusal r in refusals)
          groupJoinRefusalMessage(s, r),
        s.chatGroupPasswordTitle(name),
      ];
      expect(texts.toSet(), hasLength(texts.length));
      expect(texts.every((t) => t.contains(name)), isTrue);
      expect(s.chatAcceptWithPassword.trim(), isNotEmpty);
      expect(s.chatGroupPasswordField.trim(), isNotEmpty);
    });
  }

  test('a refusal without a name falls back to the short chat id', () {
    final GroupJoinRefusal r = GroupJoinRefusal(
      groupId: 'tox_2',
      chatId: 'A' * 64,
      reason: GroupJoinRefusalReason.unknown,
    );
    expect(refusedGroupLabel(r), '${'A' * 12}…');
    expect(
      refusedGroupLabel(
        const GroupJoinRefusal(
          groupId: 'tox_3',
          reason: GroupJoinRefusalReason.unknown,
        ),
      ),
      'tox_3',
    );
  });
}
