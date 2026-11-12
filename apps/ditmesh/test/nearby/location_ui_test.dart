import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/nearby/nearby_controller.dart';
import 'package:ditmesh/ui/nearby/location_settings_page.dart';
import 'package:ditmesh/ui/nearby/nearby_page.dart';
import 'package:ditmesh/ui/tools/grid_locator_tool.dart';
import 'package:ditmesh/ui/tools/locator_field.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'nearby_controller_test.dart' show DeviceLocation;
import 'nearby_service_test.dart' show FakeTransport;

void main() {
  late FakeIdentityService identity;
  late FakeChatService chat;
  late DeviceLocation location;
  late NearbyController controller;

  setUp(() async {
    identity = FakeIdentityService(connectDelay: Duration.zero);
    await identity.create(displayName: 'Ann');
    chat = FakeChatService(identity: identity);
    await identity.connect();
    location = DeviceLocation();
  });
  tearDown(() async {
    controller.dispose();
    await chat.dispose();
    await identity.dispose();
  });

  Future<void> pump(WidgetTester tester, Widget page) async {
    final wire = FakeTransport();
    controller = NearbyController(
      identity: identity,
      chat: chat,
      location: location,
      store: InMemoryKeyValueStore(),
      transport: () => wire,
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<NearbyController>.value(value: controller),
          Provider<ChatService>.value(value: chat),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: page,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('settings are off and showing the page does not read location', (
    tester,
  ) async {
    await pump(tester, const LocationSettingsPage());
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('settings_location_switch')),
          )
          .value,
      isFalse,
    );
    expect(location.reads, 0);
    expect(location.prompts, 0);
    await tester.tap(find.byKey(const Key('settings_location_switch')));
    await tester.pumpAndSettle();
    expect(controller.locationEnabled, isTrue);
    expect(location.prompts, 1);
    await tester.tap(find.byKey(const Key('settings_nearby_visible_switch')));
    await tester.pumpAndSettle();
    expect(controller.nearbyVisible, isFalse);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(controller.nearbyVisible, isFalse);
  });

  testWidgets('grid fills coordinates and own locator on explicit tap', (
    tester,
  ) async {
    await pump(tester, const GridLocatorTool());
    await controller.setLocationEnabled(true);
    await tester.pumpAndSettle();
    expect(location.reads, 0);
    await tester.tap(find.byKey(const Key('grid-use-current-location')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(GridLocatorTool.latitudeKey))
          .controller!
          .text,
      '39.900000',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(GridLocatorTool.longitudeKey))
          .controller!
          .text,
      '116.400000',
    );
    expect(
      tester
          .widget<LocatorField>(find.byKey(GridLocatorTool.mineKey))
          .controller
          .text,
      isNotEmpty,
    );
    expect(location.reads, 1);
  });

  testWidgets('nearby off state links to location settings without a prompt', (
    tester,
  ) async {
    await pump(tester, const NearbyPage());
    expect(find.byKey(const Key('nearby-open-settings')), findsOneWidget);
    expect(location.reads, 0);
    await tester.tap(find.byKey(const Key('nearby-open-settings')));
    await tester.pumpAndSettle();
    expect(find.byType(LocationSettingsPage), findsOneWidget);
    expect(location.prompts, 0);
  });
}
