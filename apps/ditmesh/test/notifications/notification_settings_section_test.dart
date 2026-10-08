
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/notifications/notification_settings_section.dart';
import 'package:ditmesh/notifications/notifications.dart';
import 'package:ditmesh/notifications/testing/fake_badge_api.dart';
import 'package:ditmesh/notifications/testing/fake_local_notifications_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:provider/provider.dart';

final S en = lookupS(const Locale('en'));

void main() {
  late NotificationPrefs prefs;
  late FakeLocalNotificationsApi api;
  late FakeChatService chat;
  late ValueNotifier<bool> foreground;
  late NotificationCenter center;

  setUp(() {
    prefs = NotificationPrefs();
    api = FakeLocalNotificationsApi();
    chat = FakeChatService();
    foreground = ValueNotifier<bool>(true);
    center = NotificationCenter(
      chat: chat,
      notifications: api,
      badge: FakeBadgeApi(),
      prefs: prefs,
      isForeground: foreground,
      platform: NotificationPlatform.android,
      strings: () => en,
    );
  });

  tearDown(() async {
    await center.dispose();
    await chat.dispose();
    prefs.dispose();
    foreground.dispose();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<NotificationPrefs>.value(value: prefs),
          Provider<NotificationCenter?>.value(value: center),
        ],
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: NotificationSettingsSection(header: SizedBox()),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('message content hides both the text and the Morse pattern', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text(en.accountNotificationsContent));
    await tester.pump();
    expect(prefs.showText, isFalse);
    expect(prefs.showPattern, isFalse);
    await tester.tap(find.text(en.accountNotificationsContent));
    await tester.pump();
    expect(prefs.showText && prefs.showPattern, isTrue);
  });

  testWidgets('the master switch turns notifications off', (tester) async {
    await pump(tester);
    await tester.tap(find.text(en.accountNotificationsEnable));
    await tester.pump();
    expect(prefs.enabled, isFalse);
  });

  testWidgets('allow asks the OS and explains a denial', (tester) async {
    api.permissionGranted = false;
    await pump(tester);
    await tester.tap(find.text(en.accountNotificationsAllow));
    await tester.pumpAndSettle();
    expect(api.permissionRequests, 1);
    expect(find.text(en.accountNotificationsDenied), findsOneWidget);
  });
}
