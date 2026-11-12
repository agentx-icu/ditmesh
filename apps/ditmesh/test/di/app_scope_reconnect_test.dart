import 'dart:async';

import 'package:ditmesh/di/fake_backend_factory.dart';
import 'package:ditmesh/diagnostics/connection_diagnostics.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/main.dart';
import 'package:ditmesh/ui/account/connection_chip.dart';
import 'package:ditmesh/ui/diagnostics/connection_diagnostics_page.dart';
import 'package:ditmesh/ui/shell/app_shell.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../account/test_app.dart';

class _Network extends FakeNetworkBootstrapService {
  int calls = 0;
  Object? error;
  @override
  Future<void> rebootstrap({
    bool onlyIfDisconnected = false,
    bool Function()? isCurrent,
  }) async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
  }
}

void main() {
  for (final entry in ['chip', 'diagnostics', 'banner']) {
    testWidgets('$entry reconnect reapplies the bootstrap configuration', (
      tester,
    ) async {
      final identity = seededIdentityService();
      final network = _Network();
      await tester.pumpWidget(
        DitmeshApp(
          backend: FakeBackendFactory(
            identityService: identity,
            networkBootstrapService: network,
          ),
          localeStore: acceptedTermsStore(),
        ),
      );
      await settle(tester);
      expect(
        network.calls,
        0,
        reason: 'initial connect owns its own bootstrap',
      );
      await identity.disconnect();
      await settle(tester);
      if (entry == 'chip') {
        await tester.tap(find.byType(ConnectionChip));
      } else {
        if (entry == 'banner') {
          await tester.pump(const Duration(minutes: 2));
          await tester.pump();
          await tester.tap(
            find.byKey(const ValueKey('offline-banner-details')),
          );
        } else {
          unawaited(
            ConnectionDiagnosticsPage.open(
              tester.element(find.byType(AppShell)),
            ),
          );
        }
        await settle(tester);
        final reconnect = find.byKey(const ValueKey('diag-reconnect'));
        await tester.ensureVisible(reconnect);
        await tester.tap(reconnect);
      }
      await settle(tester);
      expect(network.calls, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester);
    });
  }
  testWidgets('diagnostics displays bootstrap failure and allows retry', (
    tester,
  ) async {
    final identity = seededIdentityService();
    final network = _Network();
    await tester.pumpWidget(
      DitmeshApp(
        backend: FakeBackendFactory(
          identityService: identity,
          networkBootstrapService: network,
        ),
        localeStore: acceptedTermsStore(),
      ),
    );
    await settle(tester);
    final context = tester.element(find.byType(AppShell));
    final diagnostics = context.read<ConnectionDiagnostics>();
    unawaited(ConnectionDiagnosticsPage.open(context));
    await settle(tester);
    final reconnect = find.byKey(const ValueKey('diag-reconnect'));
    await tester.ensureVisible(reconnect);
    network.error = const ChatException(
      'bootstrap_apply_failed',
      'PRIVATE_NODE_DETAIL',
    );
    await tester.tap(reconnect);
    await settle(tester);
    expect(network.calls, 1);
    expect(diagnostics.snapshot().reconnect, ReconnectState.failed);
    expect(diagnostics.snapshot().errorCode, 'bootstrap_apply_failed');
    final en = lookupS(const Locale('en'));
    expect(find.textContaining(en.diagReconnectFailed('')), findsOneWidget);
    expect(find.textContaining('PRIVATE_NODE_DETAIL'), findsNothing);
    network.error = null;
    await tester.tap(reconnect);
    await settle(tester);
    expect(network.calls, 2);
    expect(diagnostics.snapshot().reconnect, ReconnectState.idle);
    expect(diagnostics.snapshot().errorCode, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester);
  });
}
