import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/message_input.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_support.dart';

class _DelayedService implements ChatService {
  _DelayedService(this.delegate);
  final ChatService delegate;

  @override
  Set<String> get blockedPeers => delegate.blockedPeers;
  @override
  Stream<Set<String>> get blockedPeerChanges => delegate.blockedPeerChanges;
  @override
  Future<void> blockPeer(String publicKey) => delegate.blockPeer(publicKey);
  @override
  Future<void> unblockPeer(String publicKey) => delegate.unblockPeer(publicKey);
  final Completer<void> sent = Completer<void>();
  final List<String> writes = [];
  final List<Completer<void>> writeGates = [];
  bool delayWrites = false;
  bool failDraftWrites = false;

  @override
  int get maxMessageBytes => delegate.maxMessageBytes;

  @override
  Future<ChatMessage> sendText(
    String id,
    String text, {
    KeyedRecording? recording,
  }) async {
    await sent.future;
    return delegate.sendText(id, text, recording: recording);
  }

  @override
  Future<void> setDraft(String id, String text) async {
    writes.add(text);
    if (delayWrites) {
      final gate = Completer<void>();
      writeGates.add(gate);
      await gate.future;
    }
    if (failDraftWrites) throw StateError('disk unavailable');
    await delegate.setDraft(id, text);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const id = 'c2c_';

  Future<(ChatHarness, _DelayedService, String)> setup(
    WidgetTester tester,
  ) async {
    final h = ChatHarness()..addAnn(withMessage: false);
    final service = _DelayedService(h.service);
    final conversation = '$id$kPeerKey';
    await pumpChat(
      tester,
      (h) => Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: MessageInput(
            service: service,
            conversationId: conversation,
            playback: h.playback,
          ),
        ),
      ),
      harness: h,
    );
    return (h, service, conversation);
  }

  String draft(ChatHarness h, String id) =>
      h.service.conversations.where((c) => c.id == id).firstOrNull?.draft ?? '';

  testWidgets('a delayed send preserves and persists a newer draft', (t) async {
    final (h, service, id) = await setup(t);
    await keyIn(t, 'FIRST');
    await t.pump();
    await t.tap(find.byTooltip(s.chatSend));
    await keyIn(t, 'SECOND DRAFT');
    service.sent.complete();
    await t.pump();
    await t.pump(const Duration(milliseconds: 450));
    expect(
      t.widget<TextField>(find.byType(TextField)).controller!.text,
      'SECOND DRAFT',
    );
    expect(draft(h, id), 'SECOND DRAFT');
  });

  testWidgets('editing back to the sent text still preserves that draft', (
    t,
  ) async {
    final (_, service, _) = await setup(t);
    await keyIn(t, 'FIRST');
    await t.pump();
    await t.tap(find.byTooltip(s.chatSend));
    await keyIn(t, 'SECOND');
    await keyIn(t, 'FIRST');
    service.sent.complete();
    await t.pump();
    expect(
      t.widget<TextField>(find.byType(TextField)).controller!.text,
      'FIRST',
    );
    await t.pump(const Duration(milliseconds: 450));
  });

  testWidgets('an unchanged draft clears after success', (t) async {
    final (h, service, id) = await setup(t);
    await keyIn(t, 'FIRST');
    await t.pump();
    await t.tap(find.byTooltip(s.chatSend));
    service.sent.complete();
    await t.pump();
    await t.pump(const Duration(milliseconds: 450));
    expect(t.widget<TextField>(find.byType(TextField)).controller!.text, '');
    expect(draft(h, id), '');
  });

  testWidgets('a failed send leaves the edited draft intact', (t) async {
    final (h, service, id) = await setup(t);
    await keyIn(t, 'FIRST');
    await t.pump();
    await t.tap(find.byTooltip(s.chatSend));
    await keyIn(t, 'SECOND');
    service.sent.completeError(StateError('offline'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 450));
    expect(
      t.widget<TextField>(find.byType(TextField)).controller!.text,
      'SECOND',
    );
    expect(draft(h, id), 'SECOND');
  });

  testWidgets('send finishing after disposal cannot clear a reopened draft', (
    t,
  ) async {
    final (h, service, id) = await setup(t);
    await keyIn(t, 'FIRST');
    await t.pump();
    await t.tap(find.byTooltip(s.chatSend));
    await keyIn(t, 'SECOND');
    await t.pumpWidget(h.wrap(const SizedBox()));
    await h.service.setDraft(id, 'REOPENED');
    service.sent.complete();
    await t.pump();
    expect(t.takeException(), isNull);
    expect(draft(h, id), 'REOPENED');
  });

  testWidgets('draft writes finish in edit order even with slow storage', (
    t,
  ) async {
    final (h, service, id) = await setup(t);
    service.delayWrites = true;
    await keyIn(t, 'FIRST');
    await t.pump(const Duration(milliseconds: 450));
    await keyIn(t, 'SECOND');
    await t.pump(const Duration(milliseconds: 450));
    expect(service.writes, ['FIRST']);
    service.writeGates.first.complete();
    await t.pump();
    expect(service.writes, ['FIRST', 'SECOND']);
    service.writeGates.last.complete();
    await t.pump();
    expect(draft(h, id), 'SECOND');
  });

  testWidgets(
    'reopening shares pending writes and restores the newest queued draft',
    (t) async {
      final (h, service, id) = await setup(t);
      service.delayWrites = true;
      await keyIn(t, 'FIRST');
      await t.pump(const Duration(milliseconds: 450));
      await keyIn(t, 'SECOND');
      await t.pumpWidget(h.wrap(const SizedBox()));
      await t.pumpWidget(
        h.wrap(
          Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: MessageInput(
                service: service,
                conversationId: id,
                playback: h.playback,
              ),
            ),
          ),
        ),
      );
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        'SECOND',
      );
      await keyIn(t, 'REOPENED');
      await t.pump(const Duration(milliseconds: 450));
      for (var i = 0; i < 3; i++) {
        service.writeGates[i].complete();
        await t.pump();
      }
      expect(service.writes, ['FIRST', 'SECOND', 'REOPENED']);
      expect(draft(h, id), 'REOPENED');
    },
  );

  Future<IdentityDataStore> reopen(
    WidgetTester t,
    ChatHarness h,
    _DelayedService service,
    String id,
  ) async {
    await t.pumpWidget(
      h.wrap(
        Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: MessageInput(
              service: service,
              conversationId: id,
              playback: h.playback,
              initialDraft: draft(h, id),
            ),
          ),
        ),
      ),
    );
    return t.state(find.byType(MessageInput)) as IdentityDataStore;
  }

  testWidgets('reopened pending draft flush waits without another edit', (
    t,
  ) async {
    final (h, service, id) = await setup(t);
    service.delayWrites = true;
    await keyIn(t, 'PENDING CQ');
    await t.pump(const Duration(milliseconds: 450));
    await t.pumpWidget(h.wrap(const SizedBox()));
    final participant = await reopen(t, h, service, id);
    var flushed = false;
    final saving = participant.flush().then((_) => flushed = true);
    await t.pump();
    try {
      expect(flushed, isFalse);
    } finally {
      service.writeGates.first.complete();
      await t.pump();
      await saving;
    }
    expect(draft(h, id), 'PENDING CQ');
    await t.pumpWidget(h.wrap(const SizedBox()));
  });

  testWidgets('reopened pending draft shares failures and retries unchanged', (
    t,
  ) async {
    final (h, service, id) = await setup(t);
    service.delayWrites = true;
    await keyIn(t, 'FIRST');
    await t.pump(const Duration(milliseconds: 450));
    await keyIn(t, 'SECOND');
    await t.pumpWidget(h.wrap(const SizedBox()));
    final participant = await reopen(t, h, service, id);
    service.writeGates.first.complete();
    await t.pump();
    service.failDraftWrites = true;
    service.writeGates.last.complete();
    await t.pump();
    expect(draft(h, id), 'FIRST');
    expect(
      t.widget<TextField>(find.byType(TextField)).controller!.text,
      'SECOND',
    );
    service.delayWrites = false;
    await expectLater(participant.flush(), throwsStateError);
    service.failDraftWrites = false;
    await participant.flush();
    expect(draft(h, id), 'SECOND');
    await t.pumpWidget(h.wrap(const SizedBox()));
  });

  testWidgets(
    'editing back to saved text supersedes a pending different draft',
    (t) async {
      final (h, service, id) = await setup(t);
      await keyIn(t, 'FIRST');
      await t.pump(const Duration(milliseconds: 450));
      service.delayWrites = true;
      await keyIn(t, 'SECOND');
      await t.pump(const Duration(milliseconds: 450));
      await keyIn(t, 'FIRST');
      await t.pump(const Duration(milliseconds: 450));
      service.writeGates.first.complete();
      await t.pump();
      service.writeGates.last.complete();
      await t.pump();
      expect(service.writes, ['FIRST', 'SECOND', 'FIRST']);
      expect(draft(h, id), 'FIRST');
      await t.pumpWidget(h.wrap(const SizedBox()));
    },
  );

  testWidgets('a failed disposed draft stays recoverable for retry', (t) async {
    final (h, service, id) = await setup(t);
    service.failDraftWrites = true;
    await keyIn(t, 'FAILED CQ');
    await t.pump(const Duration(milliseconds: 450));
    await t.pumpWidget(h.wrap(const SizedBox()));
    await t.pump();
    service.failDraftWrites = false;
    final participant = await reopen(t, h, service, id);
    expect(
      t.widget<TextField>(find.byType(TextField)).controller!.text,
      'FAILED CQ',
    );
    await participant.flush();
    expect(draft(h, id), 'FAILED CQ');
    await t.pumpWidget(h.wrap(const SizedBox()));
  });

  testWidgets('a mounted older editor cannot clear another route’s new draft', (
    t,
  ) async {
    final (h, service, id) = await setup(t);
    await keyIn(t, 'FIRST');
    await t.pump();
    await t.tap(find.byTooltip(s.chatSend));
    final nav = t.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: MessageInput(
                service: service,
                conversationId: id,
                playback: h.playback,
                initialDraft: draft(h, id),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await keyIn(t, 'SECOND DRAFT');
    await t.pump(const Duration(milliseconds: 450));
    service.sent.complete();
    await t.pumpAndSettle();
    expect(draft(h, id), 'SECOND DRAFT');
    nav.pop();
    await t.pumpAndSettle();
    expect(
      t.widget<TextField>(find.byType(TextField)).controller!.text,
      'SECOND DRAFT',
    );
    await t.pumpWidget(h.wrap(const SizedBox()));
    await t.pump();
    expect(draft(h, id), 'SECOND DRAFT');
  });
}
