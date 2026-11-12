import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/nearby/nearby_controller.dart';
import 'package:ditmesh/ui/chat/conversation_location_actions.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/chat/location_message_bubble.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'nearby_controller_test.dart' show DeviceLocation;

void main() {
  late FakeIdentityService identity;
  late FakeChatService chat;
  late NearbyController controller;
  late DeviceLocation location;
  const peer =
      'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB';
  const target = ConversationTarget(
    id: 'c2c_$peer',
    title: 'Bob',
    kind: ConversationKind.c2c,
  );

  Future<void> pump(WidgetTester tester) async {
    identity = FakeIdentityService(connectDelay: Duration.zero);
    await identity.create(displayName: 'Alice');
    chat = FakeChatService(identity: identity)
      ..addFakeFriend(
        const Friend(publicKey: peer, displayName: 'Bob', online: true),
      );
    await identity.connect();
    location = DeviceLocation();
    controller = NearbyController(
      identity: identity,
      chat: chat,
      store: InMemoryKeyValueStore(),
      location: location,
    );
    addTearDown(() async {
      controller.dispose();
      await chat.dispose();
      await identity.dispose();
    });
    await controller.setLocationEnabled(true);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<IdentityService>.value(value: identity),
          Provider<ChatService>.value(value: chat),
          ChangeNotifierProvider<NearbyController>.value(value: controller),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  TextButton(
                    onPressed: () => ConversationLocationActions.share(
                      context,
                      service: chat,
                      target: target,
                    ),
                    child: const Text('share'),
                  ),
                  TextButton(
                    onPressed: () => ConversationLocationActions.view(
                      context,
                      service: chat,
                      target: target,
                    ),
                    child: const Text('view'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'cancel preview sends nothing; explicit confirmation sends one snapshot',
    (tester) async {
      await pump(tester);
      await tester.tap(find.text('share'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(await chat.loadHistory(target.id), isEmpty);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await chat.loadHistory(target.id), isEmpty);
      await tester.tap(find.text('share'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chat-location-share-confirm')));
      await tester.pumpAndSettle();
      final rows = await chat.loadHistory(target.id);
      expect(rows, hasLength(1));
      expect(rows.single.location!.latitude, 39.9);
      expect(rows.single.location!.longitude, 116.4);
    },
  );

  testWidgets('disabling location while confirming prevents disclosure', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('share'));
    await tester.pumpAndSettle();
    await controller.setLocationEnabled(false);
    await tester.tap(find.byKey(const Key('chat-location-share-confirm')));
    await tester.pumpAndSettle();
    expect(await chat.loadHistory(target.id), isEmpty);
    expect(find.text('Turn on Location in settings to use your current position.'), findsOneWidget);
  });

  testWidgets('changing identities while confirming prevents disclosure', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('share'));
    await tester.pumpAndSettle();
    await identity.deleteIdentity();
    await identity.create(displayName: 'Other');
    await identity.connect();
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-location-share-confirm')));
    await tester.pumpAndSettle();
    expect(await chat.loadHistory(target.id), isEmpty);
  });

  testWidgets(
    'view uses latest valid received snapshot without reading device location',
    (tester) async {
      await pump(tester);
      chat.receiveMessage(
        target.id,
        const ChatLocation(latitude: 1, longitude: 2).encode(),
      );
      chat.receiveMessage(
        target.id,
        '__location__:{"latitude":91,"longitude":2}',
      );
      await tester.tap(find.text('view'));
      await tester.pumpAndSettle();
      expect(find.byType(LocationMessageBubble), findsOneWidget);
      expect(find.text('1.00000, 2.00000'), findsOneWidget);
      expect(location.reads, 0);
    },
  );
}
