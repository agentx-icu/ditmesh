import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/account/unlock_page.dart';
import 'package:ditmesh/ui/account/welcome_page.dart';
import 'package:ditmesh/ui/shell/app_shell.dart';

import 'support/memory_guest_store.dart';
import 'test_app.dart';

void main() {
  testWidgets(
    'fresh install offers chat identity setup without guest learning',
    (tester) async {
      final guest = MemoryGuestStore();
      await pumpApp(
        tester,
        identity: freshIdentityService(),
        guestStore: guest,
      );
      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.byKey(const ValueKey('try-learning-first')), findsNothing);
      expect(find.byType(AppShell), findsNothing);
      expect(guest.controllersOpened, 0);
    },
  );

  testWidgets('encrypted identity has no guest bypass', (tester) async {
    await pumpApp(tester, identity: seededIdentityService(password: 'pw'));
    expect(find.byType(UnlockPage), findsOneWidget);
    expect(find.byKey(const ValueKey('try-learning-first')), findsNothing);
  });
}
