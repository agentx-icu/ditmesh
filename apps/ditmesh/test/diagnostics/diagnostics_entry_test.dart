import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/diagnostics/connection_diagnostics_page.dart';
import 'package:ditmesh/ui/pages/me_page.dart';

import '../account/test_app.dart';

final S en = lookupS(const Locale('en'));

void main() {
  testWidgets('Me opens connection diagnostics for the open identity', (tester) async {
    final identity = seededIdentityService();
    await pumpApp(tester, identity: identity);
    await tester.tap(
      find.descendant(of: find.byType(NavigationBar), matching: find.text(MePage.title(en))),
    );
    await settle(tester);
    await tapVisible(tester, find.byKey(const ValueKey('me-connection-diagnostics')));
    expect(find.byType(ConnectionDiagnosticsPage), findsOneWidget);
    expect(find.text(en.diagTitle), findsWidgets);
    expect(find.byKey(const ValueKey('diag-reconnect')), findsOneWidget);
  });
}
