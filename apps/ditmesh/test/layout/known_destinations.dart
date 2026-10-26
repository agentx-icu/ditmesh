import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/contacts/add_friend_sheet.dart';
import 'package:ditmesh/ui/contacts/contacts_page.dart';
import 'package:ditmesh/ui/contacts/qr_scan_page.dart';
import 'package:ditmesh/ui/keying/key_setup_page.dart';
import 'package:ditmesh/ui/keying/key_test_area.dart';
import 'package:ditmesh/ui/listen/listen_screen.dart';
import 'package:ditmesh/ui/listen/workbench/workbench_screen.dart';
import 'package:ditmesh/ui/shell/app_shell.dart';

/// Explicit successful destinations for the three previously unverified paths.
/// Every transition uses the existing shell affordance, not a replacement route.
final class KnownLayoutDestinations {
  KnownLayoutDestinations(this.tester, {required this.settle});
  final WidgetTester tester;
  final Future<void> Function() settle;

  Future<void> tap(Finder finder) async {
    expect(finder, findsOneWidget);
    await tester.ensureVisible(finder);
    expect(finder.hitTestable(), findsOneWidget);
    await tester.tap(finder);
    await settle();
  }

  Future<void> root() async {
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.popUntil((route) => route.isFirst);
    await settle();
    expect(find.byType(AppShell), findsOneWidget);
  }

  Future<void> tab(int index) async {
    await root();
    final destination = kShellDestinations[index];
    final nav = find.byWidgetPredicate(
      (widget) => widget is NavigationBar || widget is NavigationRail,
    );
    final icon = find.descendant(
      of: nav,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            (widget.icon == destination.icon ||
                widget.icon == destination.selectedIcon),
      ),
    );
    await tap(icon.first);
  }

  void currentPage(Type type) {
    final page = find.byType(type);
    expect(page, findsOneWidget);
    expect(ModalRoute.of(tester.element(page))?.isCurrent, isTrue);
    expect(find.byType(ErrorWidget), findsNothing);
  }

  Future<void> scanner() async {
    await tab(0);
    await tap(find.byKey(const ValueKey('chat-contacts-open')));
    currentPage(ContactsPage);
    await tap(find.byIcon(Icons.person_add_alt_1));
    expect(find.byType(AddFriendForm), findsOneWidget);
    await tap(
      find.descendant(
        of: find.byType(AddFriendForm),
        matching: find.byIcon(Icons.qr_code_scanner),
      ),
    );
    currentPage(QrScanPage);
    expect(find.byKey(const ValueKey('layout-camera-view')), findsOneWidget);
  }

  Future<void> recording({bool cancel = false}) async {
    await tab(2);
    await tap(find.byIcon(Icons.mic_none));
    currentPage(ListenScreen);
    await tap(find.byKey(const ValueKey('listen-open-workbench')));
    currentPage(WorkbenchScreen);
    await tap(find.byKey(const ValueKey('workbench-import-empty')));
    // Import copies and validates WAV through real asynchronous file I/O.
    for (
      var i = 0;
      i < 40 &&
          find.byKey(const ValueKey('workbench-info')).evaluate().isEmpty &&
          !cancel;
      i++
    ) {
      await settle();
    }
    currentPage(WorkbenchScreen);
    if (cancel) {
      expect(
        find.byKey(const ValueKey('workbench-import-empty')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('workbench-waveform')), findsNothing);
    } else {
      expect(find.byKey(const ValueKey('workbench-info')), findsOneWidget);
      expect(find.byKey(const ValueKey('workbench-waveform')), findsOneWidget);
    }
  }

  Future<void> keyEditor() async {
    await tab(3);
    await tap(find.byKey(const ValueKey('me-keys')));
    currentPage(KeySetupPage);
    await tap(find.byKey(const Key('keys-new')));
    currentPage(KeyProfileEditorPage);
    expect(find.byType(KeyTestArea), findsOneWidget);
    expect(find.byKey(KeyTestArea.decodedKey), findsOneWidget);
  }
}
