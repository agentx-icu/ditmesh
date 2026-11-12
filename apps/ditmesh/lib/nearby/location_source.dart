import 'package:geolocator/geolocator.dart';

import 'package:flutter/foundation.dart';

/// One position fix.
class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    required this.at,
  });
  final double latitude;
  final double longitude;
  final double accuracyM;
  final DateTime at;

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      accuracyM.isFinite &&
      accuracyM >= 0;
}

enum LocationPermissionState {
  granted,
  denied,
  deniedForever,

  /// The OS location service itself is off.
  serviceDisabled,

  /// The platform cannot tell (no provider, plugin error).
  unavailable,
}

/// The device-location seam. Everything above it (settings switch, location
/// tools, nearby) talks to this interface, so tests inject a fake and no
/// test ever touches the OS.
abstract class LocationSource {
  Future<LocationPermissionState> permissionState();

  /// Asks the OS (shows the system prompt where applicable). Prompts on every
  /// platform DitMesh ships, desktop included: macOS has CoreLocation, Linux
  /// GeoClue, Windows the Location API.
  Future<LocationPermissionState> requestPermission();

  Future<LocationFix?> currentFix({
    Duration timeout = const Duration(seconds: 15),
  });

  /// Opens the OS page where the user can grant the permission.
  Future<bool> openSettings();
}

class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource({
    this.statusTimeout = const Duration(seconds: 5),
    this.permissionTimeout = const Duration(seconds: 45),
  });

  final Duration statusTimeout;
  final Duration permissionTimeout;

  @override
  Future<LocationPermissionState> permissionState() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled().timeout(statusTimeout)) {
        return LocationPermissionState.serviceDisabled;
      }
      return _map(await Geolocator.checkPermission().timeout(statusTimeout));
    } catch (_) {
      return LocationPermissionState.unavailable;
    }
  }

  @override
  Future<LocationPermissionState> requestPermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled().timeout(statusTimeout)) {
        return LocationPermissionState.serviceDisabled;
      }
      final current = await Geolocator.checkPermission().timeout(statusTimeout);
      if (current == LocationPermission.deniedForever) {
        return LocationPermissionState.deniedForever;
      }
      if (current == LocationPermission.always ||
          current == LocationPermission.whileInUse) {
        return LocationPermissionState.granted;
      }
      final requested = _map(
        await Geolocator.requestPermission().timeout(permissionTimeout),
      );
      if (requested != LocationPermissionState.granted) return requested;
      // A newly created CoreLocation manager can initially report
      // notDetermined (mapped to denied) before its registration completes.
      // Confirm the current OS status instead of trusting the grant callback
      // or caching it across revocation. Persistent denial stays denied.
      final watch = Stopwatch()..start();
      var confirmed = LocationPermissionState.denied;
      while (watch.elapsed < statusTimeout) {
        confirmed = _map(
          await Geolocator.checkPermission().timeout(
            statusTimeout - watch.elapsed,
          ),
        );
        if (confirmed != LocationPermissionState.denied) return confirmed;
        final remaining = statusTimeout - watch.elapsed;
        if (remaining <= Duration.zero) break;
        const pause = Duration(milliseconds: 50);
        await Future<void>.delayed(remaining < pause ? remaining : pause);
      }
      return confirmed;
    } catch (_) {
      return LocationPermissionState.unavailable;
    }
  }

  @override
  Future<LocationFix?> currentFix({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final settings = defaultTargetPlatform == TargetPlatform.android
          // No Play Services: the framework LocationManager works on every
          // Android build DitMesh targets, GMS or not.
          ? AndroidSettings(
              accuracy: LocationAccuracy.medium,
              forceLocationManager: true,
              timeLimit: timeout,
            )
          : LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: timeout,
            );
      final p = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      ).timeout(timeout);
      return LocationFix(
        latitude: p.latitude,
        longitude: p.longitude,
        accuracyM: p.accuracy,
        at: p.timestamp,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> openSettings() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled().timeout(statusTimeout)) {
        return await Geolocator.openLocationSettings().timeout(statusTimeout);
      }
      return await Geolocator.openAppSettings().timeout(statusTimeout);
    } catch (_) {
      return false;
    }
  }

  static LocationPermissionState _map(LocationPermission p) {
    switch (p) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionState.granted;
      case LocationPermission.denied:
        return LocationPermissionState.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionState.deniedForever;
      case LocationPermission.unableToDetermine:
        return LocationPermissionState.unavailable;
    }
  }
}
