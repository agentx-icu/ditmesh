import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/chat/location_message_bubble.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ChatMessage locationMessage([String? text]) => ChatMessage(
  id: 'location',
  conversationId: 'c2c_peer',
  senderId: 'peer',
  senderName: 'Station',
  text:
      text ??
      const ChatLocation(
        latitude: 39.9042,
        longitude: 116.4074,
        description: 'Station',
      ).encode(),
  timestamp: DateTime(2026, 11, 12, 12, 30),
  status: MessageStatus.received,
  isMine: false,
);

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('en'),
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'received position is a snapshot card with coordinates and locator',
    (tester) async {
      await pump(tester, LocationMessageBubble(message: locationMessage()));
      expect(find.text('39.90420, 116.40740'), findsOneWidget);
      expect(
        find.byKey(const Key('location_bubble_open_maps')),
        findsOneWidget,
      );
      expect(find.textContaining('__location__'), findsNothing);
      expect(find.textContaining('OM89'), findsOneWidget);
      expect(find.textContaining('single position'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    },
  );

  testWidgets(
    'only explicit map action launches and handles provider failure',
    (tester) async {
      final launched = <Uri>[];
      await pump(
        tester,
        LocationMessageBubble(
          message: locationMessage(),
          launcher: (uri) async {
            launched.add(uri);
            return false;
          },
        ),
      );
      expect(launched, isEmpty);
      await tester.tap(find.byKey(const Key('location_bubble_open_maps')));
      await tester.pumpAndSettle();
      expect(launched, isNotEmpty);
      expect(launched.last.host, 'www.openstreetmap.org');
      expect(
        find.text('Could not open a map for this location.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('malformed position has no map/copy actions or raw payload', (
    tester,
  ) async {
    await pump(
      tester,
      LocationMessageBubble(
        message: locationMessage('__location__:{"latitude":91,"longitude":0}'),
      ),
    );
    expect(find.text('This location message is invalid.'), findsOneWidget);
    expect(find.byKey(const Key('location_bubble_open_maps')), findsNothing);
    expect(find.textContaining('latitude'), findsNothing);
  });
  for (final locale in S.supportedLocales) {
    testWidgets(
      'location card fits a narrow phone with large text in $locale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await pump(
          tester,
          LocationMessageBubble(message: locationMessage()),
          locale: locale,
          scale: 2,
        );
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('location_bubble_open_maps')),
          findsOneWidget,
        );
      },
    );
  }
}
