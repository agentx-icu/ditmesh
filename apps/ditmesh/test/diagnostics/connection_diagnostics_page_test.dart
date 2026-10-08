import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/diagnostics/connection_diagnostics.dart';
import 'package:ditmesh/ui/diagnostics/connection_diagnostics_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:provider/provider.dart';

import '../learn/helpers/l10n.dart';
import '../notifications/support/stub_identity_service.dart';

void main() {
  final peer = 'A' * 64;
  final c2c = 'c2c_$peer';
  late StubIdentityService identity;
  late FakeChatService chat;
  late ConnectionDiagnostics diag;
  late Completer<Object?> gate;
  late int calls;

  setUp(() {
    identity = StubIdentityService();
    chat = FakeChatService(selfPublicKey: 'F' * 64);
    chat.addFakeFriend(Friend(publicKey: peer, displayName: 'K1ABC'));
    gate = Completer<Object?>();
    calls = 0;
    diag = ConnectionDiagnostics(
      identity: identity,
      chat: chat,
      reconnect: () {
        calls++;
        return gate.future;
      },
    )..start();
  });

  tearDown(() async {
    diag.dispose();
    await chat.dispose();
    await identity.dispose();
  });

  Future<void> pumpPage(WidgetTester tester, {String? conversationId}) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ConnectionDiagnostics>.value(
        value: diag,
        child: l10nApp(
          home: ConnectionDiagnosticsPage(conversationId: conversationId),
        ),
      ),
    );
    await tester.pump();
  }

  String summary(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('diag-summary'))).data!;

  testWidgets('local online / peer offline reads differently from offline', (
    tester,
  ) async {
    identity.setStatus(ConnectionStatus.online);
    await pumpPage(tester, conversationId: c2c);
    expect(summary(tester), en.diagSummaryOnlinePeerOffline);
    expect(find.text(en.connectionOffline), findsOneWidget); // the contact

    identity.setStatus(ConnectionStatus.offline);
    await tester.pump();
    await tester.pump();
    expect(summary(tester), en.diagSummaryOffline);
    expect(find.text(en.diagUnknown), findsOneWidget);
    expect(find.text(en.diagPeerUnknownHint), findsOneWidget);
    expect(find.text(en.diagLastOnlineHint), findsOneWidget);
  });

  testWidgets('shows the queued count and keeps it after a failed reconnect', (
    tester,
  ) async {
    // Created inside the test's zone so completing it runs under pump().
    gate = Completer<Object?>();
    await chat.sendText(c2c, 'CQ');
    await chat.sendText(c2c, 'DE K1ABC');
    await pumpPage(tester, conversationId: c2c);
    expect(find.text(en.diagPendingCount(2)), findsOneWidget);

    final button = find.byKey(const ValueKey('diag-reconnect'));
    await tester.scrollUntilVisible(button, 200);
    await tester.tap(button);
    await tester.pump();
    expect(find.text(en.diagReconnecting), findsOneWidget);
    // Disabled while running: a second tap starts nothing.
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();
    expect(calls, 1);

    gate.complete(const ChatException('timeout', 'x'));
    await tester.pump();
    await tester.pump();
    expect(diag.snapshot().reconnect, ReconnectState.failed);
    expect(find.textContaining(en.diagReconnectFailed('')), findsOneWidget);
    expect(find.text(en.diagReconnect), findsOneWidget);
    expect(find.text(en.diagPendingCount(2)), findsOneWidget);
  });

  testWidgets('without an identity only the explanation is shown', (
    tester,
  ) async {
    identity.setIdentity(null);
    await pumpPage(tester);
    expect(summary(tester), en.diagSummaryNoIdentity);
    expect(find.byKey(const ValueKey('diag-reconnect')), findsNothing);
  });
}
