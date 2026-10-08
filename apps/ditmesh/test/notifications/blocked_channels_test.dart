import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/notifications/notification_settings_section.dart';
import 'package:ditmesh/notifications/notifications.dart';
import 'package:ditmesh/notifications/testing/fake_badge_api.dart';
import 'package:ditmesh/notifications/testing/fake_local_notifications_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:provider/provider.dart';

/// Mobile review P9: a message channel the user turned off in the Android
/// settings is reported as blocked and shown on the Me page, while the
/// permission itself still reads as granted.
void main() {
  final S en = lookupS(const Locale('en'));
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

  test('blocked channels are read at start and again on foreground', () async {
    api.blocked = <NotificationChannelKind>{NotificationChannelKind.messages};
    await center.start();
    await pumpEventQueue();
    expect(center.blockedChannels.value, <NotificationChannelKind>{
      NotificationChannelKind.messages,
    });
    expect(api.permissionGranted, isTrue, reason: 'permission is unrelated');

    // The user turns the channel back on in Settings while the app is in the
    // background; the status follows on the next return to the foreground.
    api.blocked = <NotificationChannelKind>{};
    foreground.value = false;
    await pumpEventQueue();
    expect(center.blockedChannels.value, isNotEmpty);
    foreground.value = true;
    await pumpEventQueue();
    expect(center.blockedChannels.value, isEmpty);
    expect(api.blockedChannelChecks, 2);
  });

  test('a plugin that failed to initialise is never asked', () async {
    api.initializeResult = false;
    api.blocked = <NotificationChannelKind>{NotificationChannelKind.messages};
    await center.start();
    await pumpEventQueue();
    expect(center.blockedChannels.value, isEmpty);
    expect(api.blockedChannelChecks, 0);
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

  testWidgets('the Me page says when the OS blocks the message channel', (
    tester,
  ) async {
    api.blocked = <NotificationChannelKind>{NotificationChannelKind.messages};
    await center.start();
    await pump(tester);
    await tester.pump();
    expect(find.text(en.accountNotificationsBlocked), findsOneWidget);
    expect(find.text(en.accountNotificationsBlockedSubtitle), findsOneWidget);
    // The in-app switch keeps reflecting the user's own preference.
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
      isTrue,
    );

    api.blocked = <NotificationChannelKind>{};
    foreground.value = false;
    foreground.value = true;
    // One pump lets the (fake) OS answer, the next rebuilds the section.
    await tester.pump();
    await tester.pump();
    expect(find.text(en.accountNotificationsBlocked), findsNothing);
  });

  testWidgets('a blocked friend-request channel alone shows no message line', (
    tester,
  ) async {
    api.blocked = <NotificationChannelKind>{
      NotificationChannelKind.friendRequests,
    };
    await center.start();
    await pump(tester);
    await tester.pump();
    expect(find.text(en.accountNotificationsBlocked), findsNothing);
  });
}
