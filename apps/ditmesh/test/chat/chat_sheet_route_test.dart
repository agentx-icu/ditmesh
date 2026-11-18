import 'dart:async';

import 'package:ditmesh/ui/contacts/add_friend_sheet.dart';
import 'package:ditmesh/ui/groups/create_group_sheet.dart';
import 'package:ditmesh/ui/groups/join_group_sheet.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

class _HeldChatActions implements ChatService {
  final completed = Completer<void>();
  static const group = Group(
    id: 'tox_1',
    name: 'New net',
    kind: GroupKind.group,
  );

  @override
  Future<void> addFriend(String toxId, {String message = 'ditmesh CQ'}) =>
      completed.future;

  @override
  Future<Group> createGroup(
    String name, {
    GroupKind kind = GroupKind.group,
  }) async {
    await completed.future;
    return group;
  }

  @override
  Future<void> joinGroup(String chatId, {String? password}) => completed.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final actions = [
    (
      open: (BuildContext context, ChatService service) =>
          showAddFriendSheet(context, service: service),
      input: kPeerToxId,
      submit: s.chatSendRequest,
      result: true,
    ),
    (
      open: (BuildContext context, ChatService service) =>
          showCreateGroupSheet(context, service: service),
      input: 'New net',
      submit: s.chatCreate,
      result: _HeldChatActions.group,
    ),
    (
      open: (BuildContext context, ChatService service) =>
          showJoinGroupSheet(context, service: service),
      input: 'C' * 64,
      submit: s.chatJoin,
      result: true,
    ),
  ];

  for (final action in actions) {
    testWidgets('${action.submit} completes the sheet under a newer route', (
      tester,
    ) async {
      final service = _HeldChatActions();
      NavigatorState? navigator;
      Object? result;
      await pumpChat(
        tester,
        (_) => Scaffold(
          body: Builder(
            builder: (context) {
              navigator = Navigator.of(context);
              return TextButton(
                onPressed: () async =>
                    result = await action.open(context, service),
                child: const Text('Open sheet'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, action.input);
      await tester.tap(find.widgetWithText(FilledButton, action.submit));
      await tester.pumpAndSettle();
      unawaited(
        navigator!.push<void>(
          MaterialPageRoute<void>(
            builder: (_) =>
                const Scaffold(body: Text('Conversation from notification')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      service.completed.complete();
      await tester.pumpAndSettle();
      expect(find.text('Conversation from notification'), findsOneWidget);
      expect(result, action.result);

      navigator!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Open sheet'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });
  }
}
