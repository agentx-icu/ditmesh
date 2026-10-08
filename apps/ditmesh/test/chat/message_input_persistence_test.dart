import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/message_input.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import 'test_support.dart';

final class _DraftStore implements ChatService {
  bool fail = true;
  String saved = '';
  @override
  int get maxMessageBytes => 1322;
  @override
  Future<void> setDraft(String conversationId, String draft) async {
    if (fail) throw StateError('disk unavailable');
    saved = draft;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late ChatHarness harness;
  late FakeIdentityService identity;
  late _DraftStore store;

  Future<IdentityDataStore> mount(WidgetTester tester) async {
    harness = ChatHarness();
    identity = FakeIdentityService();
    await identity.create(displayName: 'Me');
    store = _DraftStore();
    addTearDown(harness.dispose);
    addTearDown(identity.dispose);
    await tester.pumpWidget(
      harness.wrap(
        Provider<IdentityService>.value(
          value: identity,
          child: MessageInput(
            service: store,
            conversationId: 'c2c_$kPeerKey',
            playback: harness.playback,
          ),
        ),
      ),
    );
    return tester.state(find.byType(MessageInput)) as IdentityDataStore;
  }

  testWidgets('failed draft flush blocks a durability barrier and can retry', (
    tester,
  ) async {
    final participant = await mount(tester);
    await keyIn(tester, 'CQ');
    await expectLater(participant.flush(), throwsStateError);
    store.fail = false;
    await participant.flush();
    expect(store.saved, 'CQ');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a committed same-key restore rejects stale editor changes', (
    tester,
  ) async {
    final participant = await mount(tester);
    store.fail = false;
    final backup = await identity.exportBackup();
    await participant.prepareForReplacement();
    await identity.deleteIdentity();
    await identity.importBackup(backup);
    await tester.pump();
    await keyIn(tester, 'STALE CQ');
    await participant.flush();
    expect(store.saved, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('same-key restore gives a new route a fresh shared editor', (
    tester,
  ) async {
    final participant = await mount(tester);
    store.fail = false;
    await keyIn(tester, 'OLD CQ');
    await participant.flush();
    final backup = await identity.exportBackup();
    await participant.prepareForReplacement();
    await identity.deleteIdentity();
    await identity.importBackup(backup);
    await tester.pump();
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => Provider<IdentityService>.value(
            value: identity,
            child: Scaffold(
              body: MessageInput(
                service: store,
                conversationId: 'c2c_$kPeerKey',
                playback: harness.playback,
                initialDraft: 'RESTORED CQ',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'RESTORED CQ',
    );
    await keyIn(tester, 'NEW CQ');
    final restored =
        tester.state(find.byType(MessageInput)) as IdentityDataStore;
    await restored.flush();
    expect(store.saved, 'NEW CQ');
    nav.pop();
    await tester.pumpAndSettle();
    await participant.flush();
    expect(store.saved, 'NEW CQ');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('disposed failed drafts cannot cross a same-key restore', (
    tester,
  ) async {
    final participant = await mount(tester);
    final backup = await identity.exportBackup();
    await keyIn(tester, 'FAILED OLD CQ');
    await expectLater(participant.flush(), throwsStateError);
    await tester.pumpWidget(harness.wrap(const SizedBox()));
    await tester.pump();
    await identity.deleteIdentity();
    await identity.importBackup(backup);
    await tester.pump();
    store.fail = false;
    store.saved = 'RESTORED CQ';
    await tester.pumpWidget(
      harness.wrap(
        Provider<IdentityService>.value(
          value: identity,
          child: MessageInput(
            service: store,
            conversationId: 'c2c_$kPeerKey',
            playback: harness.playback,
            initialDraft: store.saved,
          ),
        ),
      ),
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'RESTORED CQ',
    );
    final restored =
        tester.state(find.byType(MessageInput)) as IdentityDataStore;
    await restored.flush();
    expect(store.saved, 'RESTORED CQ');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a paused queued draft can retry after replacement rollback', (
    tester,
  ) async {
    final participant = await mount(tester);
    store.fail = false;
    await keyIn(tester, 'QUEUED CQ');
    final saving = participant.flush();
    final preparing = participant.prepareForReplacement();
    await Future.wait([saving, preparing]);
    await identity.updateProfile(displayName: 'Old identity republished');
    await tester.pump();
    await participant.flush();
    expect(store.saved, 'QUEUED CQ');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an aborted identity replacement resumes the old draft editor', (
    tester,
  ) async {
    final participant = await mount(tester);
    store.fail = false;
    await participant.prepareForReplacement();
    await identity.updateProfile(displayName: 'Old identity republished');
    await tester.pump();
    await keyIn(tester, 'STILL HERE');
    await participant.flush();
    expect(store.saved, 'STILL HERE');
    await tester.pumpWidget(const SizedBox());
  });
}
