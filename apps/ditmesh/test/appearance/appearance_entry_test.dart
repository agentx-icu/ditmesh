import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/pages/me_page.dart';

import '../account/test_app.dart';

void main() {
  testWidgets('Me opens an appearance chooser with five styles', (
    tester,
  ) async {
    await pumpApp(tester, identity: seededIdentityService());
    final s = lookupS(const Locale('en'));
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(MePage.title(s)),
      ),
    );
    await settle(tester);
    expect(find.text('Appearance'), findsOneWidget);
    await tapVisible(tester, find.text('Appearance'));
    for (final name in [
      'Classic Brass',
      'Modern Calm',
      'Night Radio',
      'Paper Handbook',
      'Fresh Cartoon',
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('Apply style'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
