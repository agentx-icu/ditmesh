import 'dart:async';

import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/nearby/location_source.dart';
import 'package:ditmesh/nearby/nearby_controller.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'nearby_service_test.dart' show FakeTransport;

class DeviceLocation implements LocationSource {
  int reads = 0;
  int prompts = 0;
  LocationPermissionState permission = LocationPermissionState.granted;
  Completer<LocationFix?>? pending;
  Completer<LocationPermissionState>? pendingPermission;
  @override
  Future<LocationPermissionState> permissionState() async => permission;
  @override
  Future<LocationPermissionState> requestPermission() async {
    prompts++;
    return pendingPermission == null ? permission : pendingPermission!.future;
  }

  @override
  Future<bool> openSettings() async => true;
  @override
  Future<LocationFix?> currentFix({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    reads++;
    return pending == null
        ? LocationFix(
            latitude: 39.9,
            longitude: 116.4,
            accuracyM: 20,
            at: DateTime.now(),
          )
        : pending!.future;
  }
}

class ConsentStore implements KeyValueStore {
  final delegate = InMemoryKeyValueStore();
  bool failWrite = false;
  bool failRemove = false;
  @override
  String? getString(String key) => delegate.getString(key);
  @override
  Future<void> setString(String key, String value) async {
    if (failWrite) throw StateError('disk full');
    await delegate.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    if (failRemove) throw StateError('disk locked');
    await delegate.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeIdentityService identity;
  late FakeChatService chat;
  late DeviceLocation location;
  late FakeTransport wire;
  late NearbyController controller;
  late InMemoryKeyValueStore store;

  setUp(() async {
    identity = FakeIdentityService(connectDelay: Duration.zero);
    await identity.create(displayName: 'Ann');
    chat = FakeChatService(identity: identity);
    await identity.connect();
    location = DeviceLocation();
    wire = FakeTransport();
    store = InMemoryKeyValueStore();
    controller = NearbyController(
      identity: identity,
      chat: chat,
      store: store,
      location: location,
      transport: () => wire,
    );
  });
  tearDown(() async {
    controller.dispose();
    await chat.dispose();
    await identity.dispose();
  });

  test('defaults off and no location reads, even opening nearby', () async {
    controller.pageOpened();
    await controller.startIfEnabled();
    expect(location.reads, 0);
    expect(controller.locationEnabled, isFalse);
    expect(controller.nearbyVisible, isFalse);
    expect(await controller.locate(), isNull);
    expect(location.prompts, 0);
  });

  test(
    'location enables only after permission and visibility needs consent',
    () async {
      expect(await controller.setLocationEnabled(true), isTrue);
      expect(location.prompts, 1);
      expect(controller.locationEnabled, isTrue);
      expect(controller.nearbyVisible, isFalse);
      expect(await controller.locate(), isNotNull);
      expect(wire.joins, isEmpty);
      expect(await controller.setNearbyVisible(true, consent: false), isFalse);
      controller.pageOpened();
      await controller.setNearbyVisible(true, consent: true);
      expect(wire.joins, isNotEmpty);
      await controller.setLocationEnabled(false);
      expect(controller.nearbyVisible, isFalse);
      expect(controller.nearby?.running ?? false, isFalse);
      expect(controller.fix, isNull);
    },
  );

  test('permission denial leaves switches off', () async {
    location.permission = LocationPermissionState.deniedForever;
    expect(await controller.setLocationEnabled(true), isFalse);
    expect(controller.locationEnabled, isFalse);
    expect(controller.issue, LocationIssue.permissionDenied);
    expect(location.reads, 0);
  });

  test('position arriving after disabling is discarded', () async {
    await controller.setLocationEnabled(true);
    location.pending = Completer<LocationFix?>();
    final locating = controller.locate();
    await Future<void>.delayed(Duration.zero);
    await controller.setLocationEnabled(false);
    location.pending!.complete(
      LocationFix(latitude: 1, longitude: 2, accuracyM: 1, at: DateTime.now()),
    );
    expect(await locating, isNull);
    expect(controller.fix, isNull);
  });

  test('background stops discovery and ignores an in-flight fix', () async {
    await controller.setLocationEnabled(true);
    controller.pageOpened();
    await controller.setNearbyVisible(true, consent: true);
    expect(controller.nearby!.running, isTrue);
    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(controller.nearby!.running, isFalse);
    expect(await controller.locate(), isNull);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await controller.startIfEnabled();
    expect(controller.nearby!.running, isTrue);
  });

  test('settings persist per identity but positions do not', () async {
    await controller.setLocationEnabled(true);
    await controller.locate();
    controller.dispose();
    controller = NearbyController(
      identity: identity,
      chat: chat,
      store: store,
      location: location,
      transport: () => wire,
    );
    expect(controller.locationEnabled, isTrue);
    expect(controller.fix, isNull);
    await identity.deleteIdentity();
    await identity.create(displayName: 'Other');
    await Future<void>.delayed(Duration.zero);
    expect(controller.locationEnabled, isFalse);
    expect(controller.nearbyVisible, isFalse);
  });
  test('queued consent cannot move to a replacement identity', () async {
    location.pendingPermission = Completer<LocationPermissionState>();
    final first = controller.setLocationEnabled(true);
    final queued = controller.setLocationEnabled(true);
    await Future<void>.delayed(Duration.zero);
    await identity.deleteIdentity();
    await identity.create(displayName: 'Other');
    await Future<void>.delayed(Duration.zero);
    location.pendingPermission!.complete(LocationPermissionState.granted);
    expect(await first, isFalse);
    expect(await queued, isFalse);
    expect(controller.locationEnabled, isFalse);
    expect(controller.nearbyVisible, isFalse);
  });

  test('deleting then restoring the same identity resets consent', () async {
    final backup = await identity.exportBackup();
    await controller.setLocationEnabled(true);
    await controller.setNearbyVisible(true, consent: true);
    await identity.deleteIdentity();
    await Future<void>.delayed(Duration.zero);
    await controller.flush();
    await identity.importBackup(backup);
    await Future<void>.delayed(Duration.zero);
    expect(controller.locationEnabled, isFalse);
    expect(controller.nearbyVisible, isFalse);
  });

  test('failed consent writes never enable location or visibility', () async {
    controller.dispose();
    final storage = ConsentStore()..failWrite = true;
    controller = NearbyController(
      identity: identity,
      chat: chat,
      store: storage,
      location: location,
      transport: () => wire,
    );
    expect(await controller.setLocationEnabled(true), isFalse);
    expect(controller.locationEnabled, isFalse);
    expect(controller.issue, LocationIssue.saveFailed);
    storage.failWrite = false;
    expect(await controller.setLocationEnabled(true), isTrue);
    storage.failWrite = true;
    expect(await controller.setNearbyVisible(true, consent: true), isFalse);
    expect(controller.nearbyVisible, isFalse);
    expect(wire.joins, isEmpty);
  });

  test(
    'failed identity consent removal is retried by the durability barrier',
    () async {
      controller.dispose();
      final storage = ConsentStore();
      controller = NearbyController(
        identity: identity,
        chat: chat,
        store: storage,
        location: location,
        transport: () => wire,
      );
      await controller.setLocationEnabled(true);
      storage.failRemove = true;
      await expectLater(controller.prepareForReplacement(), throwsStateError);
      expect(controller.locationEnabled, isFalse);
      expect(controller.nearbyVisible, isFalse);
      storage.failRemove = false;
      await controller.flush();
      expect(
        storage.getString(
          'location.device.${identity.current!.publicKey.toUpperCase()}',
        ),
        isNull,
      );
    },
  );
}
