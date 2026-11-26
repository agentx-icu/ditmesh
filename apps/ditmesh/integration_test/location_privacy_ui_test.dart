import 'dart:io';

import 'package:ditmesh/di/app_settings.dart';
import 'package:ditmesh/di/fake_backend_factory.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/i18n/locale_controller.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/main.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/location_message_bubble.dart';
import 'package:ditmesh/ui/legal/legal_pages.dart';
import 'package:ditmesh/ui/nearby/location_settings_page.dart';
import 'package:ditmesh/ui/nearby/nearby_page.dart';
import 'package:ditmesh/ui/shell/app_shell.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:integration_test/integration_test.dart';

import 'support/scene_walk.dart';
import 'support/seed_data.dart';
import 'support/shot_harness.dart';

const _locationSwitch = Key('settings_location_switch');
const _visibilitySwitch = Key('settings_nearby_visible_switch');
const _latitude = 39.9042;
const _longitude = 116.4074;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('open legal disclosures and opt in and out of People nearby', (
    tester,
  ) async {
    final location = _installLocationFixture();
    await _openApp(tester);
    final s = S.of(tester.element(find.byType(AppShell)));

    await selectTab(tester, ShellTab.me);
    await scrollToAndTap(
      tester,
      find.byKey(const Key('me-privacy-open')),
      'privacy and permissions',
    );
    await scrollToAndTap(
      tester,
      find.byKey(const Key('about-privacy')),
      'privacy',
    );
    expectScreen(PrivacyPolicyPage);
    expect(
      find.textContaining('DitMesh is a peer-to-peer Morse chat'),
      findsOneWidget,
    );
    await _back(tester);
    await scrollToAndTap(
      tester,
      find.byKey(const Key('account-permissions')),
      'permissions',
    );
    expect(find.text(s.permissionListText), findsOneWidget);
    await _back(tester);
    await _back(tester);

    await selectTab(tester, ShellTab.chat);
    await openContacts(tester);
    await _tapKey(tester, const Key('contacts-nearby'));
    expectScreen(NearbyPage);
    expect(find.text(s.nearbyOff), findsOneWidget);
    await _tapKey(tester, const Key('nearby-open-settings'));
    expectScreen(LocationSettingsPage);
    expect(_switch(tester, _locationSwitch).value, isFalse);
    expect(_switch(tester, _visibilitySwitch).onChanged, isNull);
    expect(location.permissionChecks, 0);

    await _tapKey(tester, _locationSwitch);
    expect(_switch(tester, _locationSwitch).value, isFalse);
    expect(find.text(s.locationPermissionDenied), findsOneWidget);
    expect(location.permissionRequests, 1);
    expect(location.positionRequests, 0);

    location.grantRequests = true;
    await _tapKey(tester, _locationSwitch);
    expect(_switch(tester, _locationSwitch).value, isTrue);
    expect(_switch(tester, _visibilitySwitch).value, isFalse);
    expect(location.permissionRequests, 2);
    expect(location.positionRequests, 0);

    await _tapKey(tester, _visibilitySwitch);
    expect(find.text(s.nearbyPrivacyBody), findsOneWidget);
    await tapText(tester, s.actionCancel);
    expect(_switch(tester, _visibilitySwitch).value, isFalse);
    await _tapKey(tester, _visibilitySwitch);
    await tapText(tester, s.nearbyPrivacyAccept);
    expect(_switch(tester, _visibilitySwitch).value, isTrue);

    await tapText(tester, s.locationUseCurrent);
    expect(find.text('39.904200, 116.407400'), findsOneWidget);
    expect(location.positionRequests, 1);
    await _tapKey(tester, _locationSwitch);
    expect(_switch(tester, _visibilitySwitch).value, isFalse);
    expect(_switch(tester, _visibilitySwitch).onChanged, isNull);
    expect(find.text('39.904200, 116.407400'), findsNothing);
    await _back(tester);
    expect(find.text(s.nearbyOff), findsOneWidget);
  });

  testWidgets('cancel or send a location and read a peer snapshot from chat', (
    tester,
  ) async {
    final location = _installLocationFixture()..grantRequests = true;
    final seed = await _openApp(tester);
    final s = S.of(tester.element(find.byType(AppShell)));
    await tapHittable(
      tester,
      find.byKey(ValueKey(seed.qsoConversationId)),
      'direct conversation',
    );
    expectScreen(ConversationScreen);

    const share = Key('chat-send-location');
    await _chatMenu(tester, share);
    expectScreen(LocationSettingsPage);
    expect(location.positionRequests, 0);
    await _tapKey(tester, _locationSwitch);
    expect(_switch(tester, _locationSwitch).value, isTrue);
    await _back(tester);

    await _chatMenu(tester, share);
    expect(find.text(s.chatLocationShareTitle), findsOneWidget);
    expect(find.text('39.90420, 116.40740'), findsOneWidget);
    await tapText(tester, s.actionCancel);
    expect(find.byType(LocationMessageBubble), findsNothing);

    await _chatMenu(tester, share);
    await _tapKey(tester, const Key('chat-location-share-confirm'));
    final ownBubble = find.byType(LocationMessageBubble);
    expect(ownBubble, findsOneWidget);
    final sent = tester.widget<LocationMessageBubble>(ownBubble).message;
    expect(sent.isMine, isTrue);
    expect(sent.location?.latitude, _latitude);
    expect(sent.location?.longitude, _longitude);
    expect(location.positionRequests, 2);

    const snapshot = ChatLocation(latitude: 22.3193, longitude: 114.1694);
    seed.chat.receiveMessage(seed.qsoConversationId, snapshot.encode());
    await settle(tester);
    await _chatMenu(tester, const Key('chat-view-location'));
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('22.31930, 114.16940')),
      findsOneWidget,
    );
    expect(location.positionRequests, 2);
  });
}

Future<SeededBackend> _openApp(WidgetTester tester) async {
  final scratch = await Directory.systemTemp.createTemp('ditmesh_location_ui_');
  addTearDown(() => scratch.delete(recursive: true));
  final seed = await buildSeed(seedCopyFor('en'), dataDir: scratch.path);
  await tester.pumpWidget(
    DitmeshApp(
      backend: FakeBackendFactory(
        identityService: seed.identity,
        chatService: (_) => seed.chat,
      ),
      localeStore: InMemoryKeyValueStore({
        LocaleController.storageKey: 'en',
        AppSettings.termsKey: '$kTermsVersion',
      }),
    ),
  );
  await settle(tester);
  expectScreen(AppShell);
  return seed;
}

Future<void> _tapKey(WidgetTester tester, Key key) =>
    tapHittable(tester, find.byKey(key), key.toString());

Future<void> _back(WidgetTester tester) =>
    tapHittable(tester, find.byType(BackButton).hitTestable(), 'back button');

SwitchListTile _switch(WidgetTester tester, Key key) =>
    tester.widget<SwitchListTile>(find.byKey(key));

Future<void> _chatMenu(WidgetTester tester, Key action) async {
  await tapHittable(
    tester,
    find.descendant(
      of: find.byType(ConversationScreen),
      matching: find.byType(PopupMenuButton<String>),
    ),
    'conversation menu',
  );
  await _tapKey(tester, action);
}

_LocationFixture _installLocationFixture() {
  final previous = GeolocatorPlatform.instance;
  final fixture = _LocationFixture();
  GeolocatorPlatform.instance = fixture;
  addTearDown(() => GeolocatorPlatform.instance = previous);
  return fixture;
}

// Stub the OS provider while exercising the app's real permission adapter,
// onboarding state, routes, dialogs, and controls on a running Flutter device.
class _LocationFixture extends GeolocatorPlatform {
  bool grantRequests = false;
  int permissionChecks = 0;
  int permissionRequests = 0;
  int positionRequests = 0;
  LocationPermission _permission = LocationPermission.denied;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async {
    permissionChecks++;
    return _permission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequests++;
    if (grantRequests) _permission = LocationPermission.whileInUse;
    return _permission;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    positionRequests++;
    return Position(
      latitude: _latitude,
      longitude: _longitude,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}
