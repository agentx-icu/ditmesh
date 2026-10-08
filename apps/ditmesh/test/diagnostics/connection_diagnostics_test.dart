import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/diagnostics/connection_diagnostics.dart';
import 'package:ditmesh/lifecycle/lifecycle_hint.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';

import '../notifications/support/stub_identity_service.dart';

void main() {
  final peer = 'A' * 64;
  final c2c = 'c2c_$peer';
  late StubIdentityService identity;
  late FakeChatService chat;
  late StreamController<LifecycleHint> hints;
  late DateTime now;
  late ConnectionDiagnostics diag;

  ConnectionDiagnostics build({Future<Object?> Function()? reconnect}) =>
      ConnectionDiagnostics(
        identity: identity,
        chat: chat,
        lifecycleHints: hints.stream,
        reconnect: reconnect,
        now: () => now,
      )..start();

  setUp(() {
    now = DateTime.utc(2026, 10, 4, 9);
    identity = StubIdentityService();
    chat = FakeChatService(selfPublicKey: 'F' * 64, clock: () => now);
    chat.addFakeFriend(Friend(publicKey: peer, displayName: 'K1ABC'));
    hints = StreamController<LifecycleHint>.broadcast();
    diag = build();
  });

  tearDown(() async {
    diag.dispose();
    await hints.close();
    await chat.dispose();
    await identity.dispose();
  });

  Future<void> status(ConnectionStatus s) async {
    identity.setStatus(s);
    await pumpEventQueue();
  }

  test('observes state changes and the moment the connection ended', () async {
    var snap = diag.snapshot();
    expect(snap.status, ConnectionStatus.offline);
    expect(snap.statusSinceKind, StatusSinceKind.firstObserved);
    expect(snap.lastOnlineAt, isNull, reason: 'no connection observed yet');

    now = now.add(const Duration(minutes: 1));
    await status(ConnectionStatus.online);
    snap = diag.snapshot();
    expect(snap.status, ConnectionStatus.online);
    expect(snap.statusSince, now);
    expect(snap.statusSinceKind, StatusSinceKind.changed);

    final dropped = now = now.add(const Duration(minutes: 5));
    await status(ConnectionStatus.offline);
    snap = diag.snapshot();
    expect(snap.lastOnlineAt, dropped);
    expect(snap.statusSince, dropped);
  });

  test('local online / peer offline differs from local offline / peer '
      'unknown', () async {
    await status(ConnectionStatus.online);
    expect(diag.snapshot(conversationId: c2c).peer, PeerAvailability.offline);
    chat.setFriendOnline(peer, true);
    expect(diag.snapshot(conversationId: c2c).peer, PeerAvailability.online);

    // Offline ourselves: the friend's last state is stale, not "online".
    await status(ConnectionStatus.offline);
    expect(diag.snapshot(conversationId: c2c).peer, PeerAvailability.unknown);
    expect(
      diag.snapshot(conversationId: 'group_tox_1').peer,
      PeerAvailability.unknown,
    );
    expect(diag.snapshot().peer, PeerAvailability.notApplicable);
  });

  test('pending count comes from the whole outbox, not a loaded page', () async {
    for (var i = 0; i < 60; i++) {
      now = now.add(const Duration(seconds: 1));
      await chat.sendText(c2c, 'CQ $i');
    }
    // A screen would load the latest 50; the outbox still has all 60.
    expect((await chat.loadHistory(c2c)).length, 50);
    final snap = diag.snapshot(conversationId: c2c);
    expect(snap.pending, isNotNull);
    expect(snap.pending!.count, 60);
    expect(snap.pending!.oldest, DateTime.utc(2026, 10, 4, 9, 0, 1));
    expect(diag.snapshot().pending!.count, 60);
    expect(diag.snapshot(conversationId: 'c2c_${'B' * 64}').pending!.count, 0);
  });

  test('a service without the outbox capability reports unknown', () async {
    final plain = _PlainChat(chat);
    final d = ConnectionDiagnostics(identity: identity, chat: plain)..start();
    addTearDown(d.dispose);
    await chat.sendText(c2c, 'CQ');
    expect(d.snapshot(conversationId: c2c).pending, isNull);
  });

  test('repeated reconnect taps start one operation', () async {
    final gate = Completer<Object?>();
    var calls = 0;
    diag.dispose();
    diag = build(
      reconnect: () {
        calls++;
        return gate.future;
      },
    );
    final a = diag.reconnect();
    final b = diag.reconnect();
    expect(identical(a, b), isTrue);
    expect(diag.snapshot().reconnect, ReconnectState.running);
    expect(calls, 1);
    gate.complete(null);
    await a;
    expect(diag.snapshot().reconnect, ReconnectState.idle);
    // Finished does not mean online: the status still follows events.
    expect(diag.snapshot().status, ConnectionStatus.offline);
  });

  test('a failed reconnect keeps a code and leaves the outbox alone', () async {
    await chat.sendText(c2c, 'CQ');
    diag.dispose();
    diag = build(
      reconnect: () async => const ChatException('timeout', 'no DHT'),
    );
    await diag.reconnect();
    final snap = diag.snapshot(conversationId: c2c);
    expect(snap.reconnect, ReconnectState.failed);
    expect(snap.errorCode, 'timeout');
    expect(snap.pending!.count, 1);
    // Default call path: a thrown non-chat error maps to `unknown`.
    identity.connectError = StateError('boom');
    final d = ConnectionDiagnostics(identity: identity, chat: chat)..start();
    addTearDown(d.dispose);
    await d.reconnect();
    expect(d.snapshot().errorCode, 'unknown');
    expect(identity.connectCalls, 1);
  });

  test('a new identity starts clean and ignores the old reconnect', () async {
    await status(ConnectionStatus.online);
    await status(ConnectionStatus.offline);
    expect(diag.snapshot().lastOnlineAt, isNotNull);

    final gate = Completer<Object?>();
    diag.dispose();
    diag = build(reconnect: () => gate.future);
    await status(ConnectionStatus.online);
    await status(ConnectionStatus.offline);
    final old = diag.reconnect();

    identity.setIdentity(Identity(toxId: 'B' * 76, displayName: 'New'));
    await pumpEventQueue();
    var snap = diag.snapshot();
    expect(snap.identityKey, 'B' * 64);
    expect(snap.lastOnlineAt, isNull);
    expect(snap.reconnect, ReconnectState.idle);

    gate.complete(const ChatException('timeout', 'late'));
    await old;
    snap = diag.snapshot();
    expect(snap.reconnect, ReconnectState.idle, reason: 'old session result');
    expect(snap.errorCode, isNull);
  });

  test('no identity: nothing to observe, reconnect is a no-op', () async {
    identity.setIdentity(null);
    await pumpEventQueue();
    final snap = diag.snapshot(conversationId: c2c);
    expect(snap.identityKey, isNull);
    expect(snap.pending, isNull);
    await diag.reconnect();
    expect(identity.connectCalls, 0);
  });

  test('return from a suspension re-reads state without claiming the gap', () async {
    await status(ConnectionStatus.online);
    final left = now = now.add(const Duration(minutes: 1));
    hints.add(LifecycleHint.background);
    await pumpEventQueue();
    now = now.add(const Duration(minutes: 10));
    hints.add(LifecycleHint.mayBeDisconnected);
    await pumpEventQueue();
    // The node is still reported online when we come back.
    final back = now = now.add(const Duration(minutes: 20));
    hints.add(LifecycleHint.foreground);
    await pumpEventQueue();
    final snap = diag.snapshot();
    expect(snap.status, ConnectionStatus.online);
    expect(snap.statusSince, back);
    expect(snap.statusSinceKind, StatusSinceKind.resumed);
    expect(snap.lastOnlineAt, left, reason: 'last moment actually observed');
  });

  test('a short background period keeps the observation', () async {
    await status(ConnectionStatus.online);
    final since = diag.snapshot().statusSince;
    hints.add(LifecycleHint.background);
    hints.add(LifecycleHint.foreground);
    await pumpEventQueue();
    expect(diag.snapshot().statusSince, since);
    expect(diag.snapshot().statusSinceKind, StatusSinceKind.changed);
  });

  test('a connection loss delivered on thaw, before the foreground hint, '
      'never claims the gap', () async {
    await status(ConnectionStatus.online);
    final left = now = now.add(const Duration(minutes: 1));
    hints.add(LifecycleHint.background);
    await pumpEventQueue();
    now = now.add(const Duration(minutes: 10));
    hints.add(LifecycleHint.mayBeDisconnected);
    await pumpEventQueue();
    now = now.add(const Duration(minutes: 20));
    await status(ConnectionStatus.connecting); // queued during the freeze
    hints.add(LifecycleHint.foreground);
    await pumpEventQueue();
    expect(diag.snapshot().lastOnlineAt, left);
  });

  test('a status that precedes the identity event is filed under the new '
      'identity', () async {
    await status(ConnectionStatus.online);
    await status(ConnectionStatus.offline);
    // Replace the identity without announcing it yet; a status arrives first.
    identity.clearIdentity();
    identity.setIdentityQuietly(Identity(toxId: 'C' * 76, displayName: 'C'));
    await status(ConnectionStatus.connecting);
    final snap = diag.snapshot();
    expect(snap.identityKey, 'C' * 64);
    expect(snap.lastOnlineAt, isNull, reason: 'the old identity\'s observation');
  });

  test('group conversations scope the outbox and leave the peer unknown', () async {
    final g = chat.addFakeGroup(const Group(id: 'tox_1', name: 'Net', kind: GroupKind.group));
    chat.setGroupConnected(g.id, false);
    await status(ConnectionStatus.online);
    await chat.sendText('group_tox_1', 'CQ NET');
    await chat.sendText(c2c, 'CQ');
    expect(diag.snapshot(conversationId: 'group_tox_1').pending!.count, 1);
    expect(diag.snapshot(conversationId: 'group_tox_1').peer, PeerAvailability.unknown);
    expect(diag.snapshot().pending!.count, 2);
  });
}

/// A [ChatService] that does not implement [OutboxInspector].
final class _PlainChat implements ChatService {
  _PlainChat(this._inner);

  final FakeChatService _inner;

  @override
  Stream<List<Friend>> get friendChanges => _inner.friendChanges;
  @override
  Stream<bool> get sessionChanges => _inner.sessionChanges;
  @override
  Stream<ChatMessage> get messageEvents => _inner.messageEvents;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
