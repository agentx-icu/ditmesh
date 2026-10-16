import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/local_message_sends.dart';
import 'package:ditmesh/ui/chat/message_input.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import 'test_support.dart';

/// A send that commits its row at once (the outbox holds it) and returns
/// only when [release] completes: the window in which the composer has not
/// cleared the draft yet. Records every draft write.
class _CommitThenBlock implements ChatService {
  _CommitThenBlock(this.delegate);
  final FakeChatService delegate;
  final Completer<void> release = Completer<void>();
  final List<String> writes = [];
  int sends = 0;

  @override
  int get maxMessageBytes => delegate.maxMessageBytes;

  @override
  Future<ChatMessage> sendText(
    String id,
    String text, {
    KeyedRecording? recording,
  }) async {
    sends++;
    final ChatMessage row = await delegate.sendText(
      id,
      text,
      recording: recording,
    );
    await release.future;
    return row;
  }

  @override
  Future<void> setDraft(String id, String text) async {
    writes.add(text);
    await delegate.setDraft(id, text);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The composer's half of "D1, draft after kill" (doc/VALIDATION.md): while
/// a send is in flight the text being sent is the send's, and once it
/// committed nothing may leave that text behind as the draft.
void main() {
  final String id = 'c2c_$kPeerKey';

  String stored(ChatHarness h) =>
      h.service.conversations.where((c) => c.id == id).firstOrNull?.draft ?? '';

  Widget composer(ChatHarness h, ChatService service, {Key? key}) =>
      MessageInput(
        key: key,
        service: service,
        conversationId: id,
        playback: h.playback,
      );

  Future<(ChatHarness, _CommitThenBlock)> setup(
    WidgetTester t, {
    Size size = kPhone,
  }) async {
    final h = ChatHarness()..addAnn(withMessage: false);
    final service = _CommitThenBlock(h.service);
    await pumpChat(
      t,
      (h) => Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: composer(h, service),
        ),
      ),
      harness: h,
      size: size,
    );
    return (h, service);
  }

  String field(WidgetTester t) =>
      t.widget<TextField>(find.byType(TextField).first).controller!.text;

  for (final (String name, Size size) in [
    ('phone', kPhone),
    ('desktop', kDesktop),
  ]) {
    testWidgets('$name: the text being sent is not saved while the send '
        'is in flight', (t) async {
      final (h, service) = await setup(t, size: size);
      await keyIn(t, 'CQ DE W1AW');
      // Sent before the debounce saved it; the debounce fires mid-send.
      await t.tap(find.byTooltip(s.chatSend));
      await t.pump(const Duration(milliseconds: 450));
      // Going to the background flushes too.
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      expect(
        service.writes,
        isEmpty,
        reason: 'saving it would supersede the send with the sent text',
      );
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        t.binding.handleAppLifecycleStateChanged(state);
      }
      service.release.complete();
      await t.pump();
      await t.pump(const Duration(milliseconds: 450));
      expect(field(t), '');
      expect(stored(h), '');
      expect(service.writes, isNot(contains('CQ DE W1AW')));
    });

    testWidgets('$name: a composer closed during the send clears the '
        'stored draft', (t) async {
      final (h, service) = await setup(t, size: size);
      await keyIn(t, 'CQ DE W1AW');
      await t.pump(const Duration(milliseconds: 450));
      expect(stored(h), 'CQ DE W1AW');
      await t.tap(find.byTooltip(s.chatSend));
      await t.pump();
      // The route is popped while the send is in flight.
      await t.pumpWidget(h.wrap(const SizedBox()));
      service.release.complete();
      await t.pump();
      await t.pump();
      expect(t.takeException(), isNull);
      expect(stored(h), '', reason: 'reopening must not offer it again');
    });
  }

  testWidgets('an edit away and back during the send is saved after it', (
    t,
  ) async {
    final (h, service) = await setup(t);
    await keyIn(t, 'FIRST');
    await t.pump(const Duration(milliseconds: 450));
    expect(service.writes, ['FIRST']);
    await t.tap(find.byTooltip(s.chatSend));
    await keyIn(t, 'SECOND');
    await keyIn(t, 'FIRST');
    service.release.complete();
    await t.pump();
    await t.pump(const Duration(milliseconds: 450));
    expect(field(t), 'FIRST');
    // Written again although the stored text is the same: this write is
    // what supersedes the send's intent (else recovery would remove it).
    expect(service.writes, ['FIRST', 'FIRST']);
    expect(stored(h), 'FIRST');
  });

  testWidgets('an editor still sharing the text is cleared when the sending '
      'one left', (t) async {
    final h = ChatHarness()..addAnn(withMessage: false);
    final service = _CommitThenBlock(h.service);
    Widget both({required bool first}) => Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (first) composer(h, service, key: const ValueKey('pane')),
          composer(h, service, key: const ValueKey('route')),
        ],
      ),
    );
    await pumpChat(t, (h) => both(first: true), harness: h, size: kDesktop);
    // Both editors show one shared controller.
    t.widget<TextField>(find.byType(TextField).first).controller!.text = 'CQ';
    await t.pump();
    await t.pump(const Duration(milliseconds: 450));
    await t.tap(find.byTooltip(s.chatSend).first);
    await t.pump();
    // The pane collapses during the send; the route's editor stays.
    await t.pumpWidget(h.wrap(both(first: false)));
    service.release.complete();
    await t.pump();
    await t.pump(const Duration(milliseconds: 450));
    expect(field(t), '');
    expect(stored(h), '');
  });

  testWidgets('a send completing after the identity was replaced neither '
      'publishes nor touches the drafts', (t) async {
    final h = ChatHarness()..addAnn(withMessage: false);
    final service = _CommitThenBlock(h.service);
    final identity = FakeIdentityService();
    addTearDown(identity.dispose);
    await identity.create(displayName: 'Me');
    await pumpChat(
      t,
      (h) => Provider<IdentityService>.value(
        value: identity,
        child: Scaffold(body: composer(h, service)),
      ),
      harness: h,
    );
    await keyIn(t, 'CQ');
    await t.pump(const Duration(milliseconds: 450));
    final writes = service.writes.length;
    await t.tap(find.byTooltip(s.chatSend));
    await t.pump();
    await identity.deleteIdentity();
    await identity.create(displayName: 'Other');
    await t.pump();
    service.release.complete();
    await t.pump();
    await t.pump(const Duration(milliseconds: 450));
    expect(LocalMessageSends.forService(service).latest, isNull);
    expect(service.writes.length, writes);
  });
}
