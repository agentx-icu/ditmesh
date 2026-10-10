import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/restored_pending.dart';
import 'package:ditmesh/ui/theme.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'test_support.dart';

/// Restored unsent messages (F10): the banner over the conversation list
/// and the review page it opens. Nothing here may ever send.
void main() {
  late Directory dir;
  late FakeChatService chat;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('restored_pending_ui_');
    chat = FakeChatService(
      selfPublicKey: kSelfKey,
      clock: () => DateTime(2026, 10, 9, 12),
    );
  });
  tearDown(() async {
    await chat.dispose();
    dir.deleteSync(recursive: true);
  });

  File doc() => File(p.join(dir.path, restoredPendingDoc));

  void seed(List<RestoredPendingItem> items) {
    doc()
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode({
          'items': [for (final i in items) i.toJson()],
        }),
      );
  }

  RestoredPendingItem item(String id, String conversationId, String text) =>
      RestoredPendingItem(
        id: id,
        conversationId: conversationId,
        text: text,
        queuedAt: DateTime.utc(2026, 10, 4, 8, int.parse(id.substring(1))),
      );

  Future<void> pumpBanner(WidgetTester tester, {Identity? identity}) async {
    final ids = StubIdentityService(
      identity: identity,
      dataDirectoryPath: dir.path,
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ChatService?>.value(value: chat),
          Provider<IdentityService>.value(value: ids),
        ],
        child: MaterialApp(
          theme: DitmeshTheme.light(),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(body: RestoredPendingBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final banner = find.byKey(const ValueKey('restored-pending-banner'));

  testWidgets('no restored messages: no banner', (tester) async {
    await pumpBanner(tester);
    expect(banner, findsNothing);
  });

  testWidgets('an unreadable document is treated as empty', (tester) async {
    doc()
      ..createSync(recursive: true)
      ..writeAsStringSync('{not json');
    await pumpBanner(tester);
    expect(banner, findsNothing);
  });

  testWidgets('review, dismiss one, dismiss all; nothing is sent', (
    tester,
  ) async {
    chat.addFakeFriend(Friend(publicKey: kPeerKey, displayName: 'Ann'));
    chat.receiveMessage('c2c_$kPeerKey', 'CQ CQ DE ANN');
    final String stranger = '0123456789ABCDEF' * 4;
    seed([
      item('m2', 'c2c_$stranger', 'QRL?'),
      item('m1', 'c2c_$kPeerKey', 'GM OM'),
      item('m3', 'c2c_$kPeerKey', 'TNX FER QSO'),
    ]);
    await pumpBanner(tester);

    expect(banner, findsOneWidget);
    expect(find.text(s.pendingReviewBanner(3)), findsOneWidget);
    await tester.tap(banner);
    await tester.pumpAndSettle();

    expect(find.byType(RestoredPendingPage), findsOneWidget);
    expect(find.text(s.pendingReviewBody), findsOneWidget);
    // Oldest first; a known conversation by its title, any other by the
    // start of its key.
    final rows = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.key! as ValueKey<String>).value)
        .toList();
    expect(rows, [
      'restored-pending-m1',
      'restored-pending-m2',
      'restored-pending-m3',
    ]);
    expect(find.text('Ann'), findsNWidgets(2));
    expect(find.text('01234567…'), findsOneWidget);
    expect(find.text('GM OM'), findsOneWidget);
    expect(find.text('QRL?'), findsOneWidget);
    // There is deliberately no way to send from here.
    expect(find.byTooltip(s.chatSend), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('restored-pending-m2')),
        matching: find.byTooltip(s.pendingReviewDismiss),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('QRL?'), findsNothing);
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(doc().existsSync(), isTrue);

    await tester.tap(find.text(s.pendingReviewDismissAll));
    await tester.pumpAndSettle();
    expect(find.text(s.pendingReviewEmpty), findsOneWidget);
    expect(find.text(s.pendingReviewDismissAll), findsNothing);
    expect(doc().existsSync(), isFalse);

    // Back on the list the banner is gone.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(banner, findsNothing);
    // The transport never saw any of the restored texts.
    for (final c in chat.conversations) {
      final history = await chat.loadHistory(c.id);
      expect(history.where((m) => m.isMine), isEmpty, reason: c.id);
    }
  });

  testWidgets('a short conversation key is shown whole', (tester) async {
    seed([item('m1', 'c2c_ABC', 'HI')]);
    await pumpBanner(tester);
    await tester.tap(banner);
    await tester.pumpAndSettle();
    expect(find.text('ABC'), findsOneWidget);
  });
}
