import 'dart:async';

import 'package:ditmesh/diagnostics/connection_diagnostics.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/diagnostics/connection_diagnostics_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../notifications/support/stub_identity_service.dart';

/// Checklist N10: the diagnostics page on a 320 px phone (2x device pixel
/// ratio) at 2x text, in the locales with the longest strings, with every
/// section populated: queued messages, a failed reconnect and the details.
void main() {
  final peer = 'A' * 64;
  final c2c = 'c2c_$peer';

  late StubIdentityService identity;
  late FakeChatService chat;
  late ConnectionDiagnostics diag;
  late Completer<Object?> gate;

  setUp(() {
    identity = StubIdentityService();
    chat = FakeChatService(selfPublicKey: 'F' * 64);
    chat.addFakeFriend(Friend(publicKey: peer, displayName: 'K1ABC'));
    gate = Completer<Object?>();
    diag = ConnectionDiagnostics(
      identity: identity,
      chat: chat,
      reconnect: () => gate.future,
    )..start();
  });

  tearDown(() async {
    diag.dispose();
    await chat.dispose();
    await identity.dispose();
  });

  Future<void> pumpPhone(WidgetTester tester, Locale locale) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(640, 2000); // 320 x 1000 logical
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider<ConnectionDiagnostics>.value(
        value: diag,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: ConnectionDiagnosticsPage(conversationId: c2c),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final locale in const [
    Locale('en'),
    Locale('de'),
    Locale('ru'),
    Locale('ja'),
  ]) {
    testWidgets('fits 320 px at 2x text with every section shown ($locale)', (
      tester,
    ) async {
      // Created inside the test's zone so completing it runs under pump().
      gate = Completer<Object?>();
      identity.setStatus(ConnectionStatus.online);
      await chat.sendText(c2c, 'CQ CQ CQ DE K1ABC');
      await chat.sendText(c2c, 'K1ABC DE W1AW');
      await pumpPhone(tester, locale);
      final s = S.of(tester.element(find.byType(ConnectionDiagnosticsPage)));
      // The page's ListView; the selectable details carry Scrollables too.
      final list = find.byType(Scrollable).first;
      expect(find.text(s.diagSummaryOnlinePeerOffline), findsOneWidget);
      // The list is lazy: at this size the queue fact is below the fold.
      final pending = find.text(s.diagPendingCount(2));
      await tester.scrollUntilVisible(pending, 200, scrollable: list);
      expect(pending, findsOneWidget);

      // The one action stays reachable and usable at this size.
      final button = find.byKey(const ValueKey('diag-reconnect'));
      await tester.scrollUntilVisible(button, 200, scrollable: list);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      expect(find.text(s.diagReconnecting), findsOneWidget);
      gate.complete(const ChatException('timeout', 'x'));
      await tester.pump();
      await tester.pump();
      expect(diag.snapshot().reconnect, ReconnectState.failed);
      expect(find.textContaining(s.diagReconnectFailed('')), findsOneWidget);

      // Details: the identity key prefix, the ISO timestamp, the error code.
      final details = find.byType(ExpansionTile);
      await tester.scrollUntilVisible(details, 200, scrollable: list);
      await tester.ensureVisible(details);
      await tester.pumpAndSettle();
      await tester.tap(details);
      await tester.pumpAndSettle();
      final code = find.text('timeout');
      await tester.scrollUntilVisible(code, 200, scrollable: list);
      expect(code, findsOneWidget);
      expect(find.text('F' * 16), findsOneWidget);

      // Local offline: the stale-peer explanation and the last-online hint.
      identity.setStatus(ConnectionStatus.offline);
      await tester.pump();
      await tester.pump();
      final offline = find.text(s.diagSummaryOffline);
      await tester.scrollUntilVisible(offline, -300, scrollable: list);
      expect(offline, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
