import 'dart:async';

import 'package:ditmesh/nearby/location_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _Platform extends GeolocatorPlatform with MockPlatformInterfaceMixin {
  Future<bool>? enabled;
  Future<LocationPermission>? permission;
  Future<Position>? position;
  final checkedPermissions = <LocationPermission>[];
  var permissionChecks = 0;
  var positionRequests = 0;
  var overwritePositionCallback = false;
  Completer<Position>? latestPosition;
  @override
  Future<bool> isLocationServiceEnabled() => enabled ?? Future.value(true);
  @override
  Future<LocationPermission> checkPermission() async {
    permissionChecks++;
    return checkedPermissions.isEmpty
        ? LocationPermission.denied
        : checkedPermissions.removeAt(0);
  }

  @override
  Future<LocationPermission> requestPermission() =>
      permission ?? Future.value(LocationPermission.whileInUse);
  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    positionRequests++;
    if (overwritePositionCallback) {
      latestPosition = Completer<Position>();
      return latestPosition!.future;
    }
    return position ?? Completer<Position>().future;
  }
}

Position examplePosition() => Position(
  latitude: 0,
  longitude: -140,
  timestamp: DateTime.now(),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  late _Platform platform;
  setUp(() {
    final previous = GeolocatorPlatform.instance;
    platform = _Platform();
    GeolocatorPlatform.instance = platform;
    addTearDown(() => GeolocatorPlatform.instance = previous);
  });

  for (final target in [TargetPlatform.macOS, TargetPlatform.iOS]) {
    test(
      'nearby and UI reads share the single Apple callback on $target',
      () async {
        debugDefaultTargetPlatformOverride = target;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        platform.overwritePositionCallback = true;
        final nearby = const GeolocatorLocationSource().currentFix(
          timeout: const Duration(milliseconds: 200),
        );
        final ui = const GeolocatorLocationSource(
          statusTimeout: Duration(seconds: 1),
        ).currentFix(timeout: const Duration(milliseconds: 200));
        platform.latestPosition!.complete(examplePosition());
        final results = await Future.wait([nearby, ui]);
        expect(results.every((fix) => fix?.isValid == true), isTrue);
        expect(platform.positionRequests, 1);
      },
    );
  }

  test(
    'an Apple caller timeout does not cancel another active reader',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      platform.overwritePositionCallback = true;
      final short = const GeolocatorLocationSource().currentFix(
        timeout: const Duration(milliseconds: 10),
      );
      final long = const GeolocatorLocationSource().currentFix(
        timeout: const Duration(milliseconds: 200),
      );
      expect(await short, isNull);
      platform.latestPosition!.complete(examplePosition());
      expect((await long)?.isValid, isTrue);
      expect(platform.positionRequests, 1);
    },
  );

  test('a fresh Apple read can recover after every caller timed out', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    platform.overwritePositionCallback = true;
    expect(
      await const GeolocatorLocationSource().currentFix(
        timeout: const Duration(milliseconds: 10),
      ),
      isNull,
    );
    final retry = const GeolocatorLocationSource().currentFix();
    platform.latestPosition!.complete(examplePosition());
    expect((await retry)?.isValid, isTrue);
    expect(platform.positionRequests, 2);
  });

  test(
    'a granted callback is confirmed by the OS before reporting granted',
    () async {
      platform.checkedPermissions.addAll([
        LocationPermission.denied,
        LocationPermission.denied,
        LocationPermission.whileInUse,
      ]);
      expect(
        await const GeolocatorLocationSource(
          statusTimeout: Duration(milliseconds: 200),
        ).requestPermission(),
        LocationPermissionState.granted,
      );
      expect(platform.permissionChecks, 3);
    },
  );

  test('a callback cannot override a persistent OS denial', () async {
    expect(
      await const GeolocatorLocationSource(
        statusTimeout: Duration(milliseconds: 20),
      ).requestPermission(),
      LocationPermissionState.denied,
    );
  });

  test(
    'a native permission callback that never arrives cannot leave settings busy forever',
    () async {
      final permission = Completer<LocationPermission>();
      platform.permission = permission.future;
      const source = GeolocatorLocationSource(
        permissionTimeout: Duration(milliseconds: 20),
      );
      expect(
        await source.requestPermission(),
        LocationPermissionState.unavailable,
      );
      permission.complete(LocationPermission.whileInUse);
      // A later callback cannot retroactively turn on an application switch.
    },
  );

  test(
    'service status that never arrives has a bounded unavailable result',
    () async {
      platform.enabled = Completer<bool>().future;
      const source = GeolocatorLocationSource(
        statusTimeout: Duration(milliseconds: 20),
      );
      expect(
        await source.permissionState(),
        LocationPermissionState.unavailable,
      );
    },
  );

  test(
    'a provider that ignores its timeLimit cannot hang a position read',
    () async {
      platform.position = Completer<Position>().future;
      expect(
        await const GeolocatorLocationSource().currentFix(
          timeout: const Duration(milliseconds: 20),
        ),
        isNull,
      );
    },
  );
}
