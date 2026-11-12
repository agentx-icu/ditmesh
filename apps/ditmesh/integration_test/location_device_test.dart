// Opt-in real OS probe. No account, preferences, mock permission, or injected
// position is used. Coordinates never enter logs or the report.
//
// flutter test integration_test/location_device_test.dart -d macos --no-pub \
//   --dart-define=DITMESH_LOCATION_DEVICE_TEST=true
// Add DITMESH_LOCATION_MANUAL_START=true for a foreground UI click first.
// DITMESH_LOCATION_STREAM_PROBE=true tests the real foreground position stream
// before the single-position API; it does not call requestPermission first.
// Capture LOCATION_DEVICE_EVIDENCE into an ignored build directory.
import 'dart:async';
import 'dart:convert';

import 'package:ditmesh/nearby/location_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const manualStart = bool.fromEnvironment('DITMESH_LOCATION_MANUAL_START');
  const streamProbe = bool.fromEnvironment('DITMESH_LOCATION_STREAM_PROBE');
  const enabled =
      manualStart ||
      streamProbe ||
      bool.fromEnvironment('DITMESH_LOCATION_DEVICE_TEST');
  testWidgets(
    'real OS location permission and current-position probe',
    (tester) async {
      binding.shouldPropagateDevicePointerEvents = manualStart;
      addTearDown(() {
        binding.shouldPropagateDevicePointerEvents = false;
      });
      final started = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  if (!started.isCompleted) started.complete();
                },
                child: const Text('Begin system location verification'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      debugPrint('LOCATION_DEVICE_READY manualStart=$manualStart');
      if (manualStart) {
        final didStart = await tester.runAsync(() async {
          try {
            await started.future.timeout(const Duration(seconds: 45));
            return true;
          } on TimeoutException {
            return false;
          }
        });
        expect(
          didStart,
          isTrue,
          reason: 'No foreground click; do not run or record an OS probe.',
        );
      }
      final stages = <Map<String, Object?>>[];
      final report = <String, Object?>{
        'startedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'platform': defaultTargetPlatform.name,
        'source': 'GeolocatorLocationSource',
        'positionProvider': 'real operating-system provider',
        'syntheticPosition': false,
        'manualForegroundStart': manualStart,
        'streamProbe': streamProbe,
        'coordinatesRecorded': false,
        'hasFix': false,
        'stages': stages,
      };
      Future<T> stage<T>(
        String name,
        Future<T> Function() action,
        Duration timeout,
      ) async {
        report['stage'] = name;
        debugPrint('LOCATION_DEVICE_STAGE $name');
        final startedAt = DateTime.now().toUtc().toIso8601String();
        final elapsed = Stopwatch()..start();
        try {
          return await action().timeout(timeout);
        } finally {
          elapsed.stop();
          stages.add({
            'name': name,
            'startedAtUtc': startedAt,
            'finishedAtUtc': DateTime.now().toUtc().toIso8601String(),
            'elapsedMs': elapsed.elapsedMilliseconds,
          });
        }
      }

      Future<void> singlePositionControl() async {
        try {
          final raw = await stage(
            'singlePositionControl',
            () => Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
                timeLimit: Duration(seconds: 5),
              ),
            ),
            const Duration(seconds: 6),
          );
          report['singlePositionHasFix'] = true;
          report['singlePositionAccuracyM'] = raw.accuracy;
        } on Object catch (error) {
          report['singlePositionHasFix'] = false;
          report['singlePositionErrorType'] = error.runtimeType.toString();
        }
      }

      Future<void> streamFirstPosition() async {
        final first = Completer<Position>();
        StreamSubscription<Position>? subscription;
        report['streamAllowBackgroundUpdates'] = false;
        try {
          subscription =
              Geolocator.getPositionStream(
                    locationSettings: AppleSettings(
                      accuracy: LocationAccuracy.medium,
                      allowBackgroundLocationUpdates: false,
                    ),
                  )
                  .timeout(const Duration(seconds: 15))
                  .listen(
                    (position) {
                      if (!first.isCompleted) first.complete(position);
                    },
                    onError: (Object error, StackTrace stack) {
                      if (!first.isCompleted) first.completeError(error, stack);
                    },
                    onDone: () {
                      if (!first.isCompleted) {
                        first.completeError(
                          StateError('Position stream closed without a point'),
                        );
                      }
                    },
                  );
          final position = await stage(
            'streamFirstPosition',
            () => first.future,
            const Duration(seconds: 16),
          );
          final age = DateTime.now()
              .difference(position.timestamp)
              .inMilliseconds;
          report['streamHasFix'] = true;
          report['streamCoordinatesValid'] =
              position.latitude.isFinite &&
              position.longitude.isFinite &&
              position.latitude.abs() <= 90 &&
              position.longitude.abs() <= 180 &&
              position.accuracy.isFinite &&
              position.accuracy >= 0;
          report['streamFixFresh'] = age >= -60000 && age <= 180000;
          report['streamPositionAgeMs'] = age;
          report['streamAccuracyM'] = position.accuracy;
        } on Object catch (error) {
          report['streamHasFix'] = false;
          report['streamErrorType'] = error.runtimeType.toString();
        } finally {
          if (subscription != null) {
            try {
              await subscription.cancel().timeout(const Duration(seconds: 5));
              report['streamSubscriptionCancelled'] = true;
            } on Object catch (error) {
              report['streamSubscriptionCancelled'] = false;
              report['streamCancellationErrorType'] = error.runtimeType
                  .toString();
            }
          }
        }
      }

      final total = Stopwatch()..start();
      LocationFix? fix;
      var permission = LocationPermissionState.unavailable;
      await tester.runAsync(() async {
        const source = GeolocatorLocationSource();
        try {
          report['permissionBefore'] = (await stage(
            'source.permissionState',
            source.permissionState,
            const Duration(seconds: 10),
          )).name;
          report['systemServiceEnabled'] = await stage(
            'systemServiceEnabled',
            Geolocator.isLocationServiceEnabled,
            const Duration(seconds: 10),
          );
          report['rawPermissionBefore'] = (await stage(
            'rawPermissionBefore',
            Geolocator.checkPermission,
            const Duration(seconds: 10),
          )).name;
          if (streamProbe) {
            // CoreLocation itself enforces authorization for a real foreground
            // stream. The SDK's explicit permission callback is the comparison
            // under investigation, so do not wait for that callback here.
            report['explicitPermissionRequestSkipped'] = true;
            await streamFirstPosition();
            report['rawPermissionAfterStream'] = (await stage(
              'rawPermissionAfterStream',
              Geolocator.checkPermission,
              const Duration(seconds: 10),
            )).name;
            await singlePositionControl();
            report['outcome'] = report['streamHasFix'] == true
                ? 'positionStreamObtained'
                : 'positionStreamUnavailable';
          } else {
            permission = await stage(
              'source.requestPermission',
              source.requestPermission,
              const Duration(seconds: 60),
            );
            report['permissionAfter'] = permission.name;
            report['rawPermissionAfter'] = (await stage(
              'rawPermissionAfter',
              Geolocator.checkPermission,
              const Duration(seconds: 10),
            )).name;
            if (permission == LocationPermissionState.granted) {
              fix = await stage(
                'source.currentFix',
                () => source.currentFix(timeout: const Duration(seconds: 20)),
                const Duration(seconds: 25),
              );
              report['hasFix'] = fix != null;
              report['fixValid'] = fix?.isValid;
              report['accuracyM'] = fix?.accuracyM;
              report['fixAtUtc'] = fix?.at.toUtc().toIso8601String();
              if (fix == null) {
                await Future<void>.delayed(const Duration(seconds: 2));
                report['rawPermissionAfterDelay'] = (await stage(
                  'rawPermissionAfterDelay',
                  Geolocator.checkPermission,
                  const Duration(seconds: 10),
                )).name;
                await singlePositionControl();
              }
            }
            report['outcome'] = permission != LocationPermissionState.granted
                ? 'permissionOrServiceBlocked'
                : fix == null
                ? 'positionUnavailable'
                : 'positionObtained';
          }
        } on Object catch (error) {
          report['errorType'] = error.runtimeType.toString();
          report['outcome'] = 'providerError';
        } finally {
          total.stop();
          report['elapsedMs'] = total.elapsedMilliseconds;
          report['finishedAtUtc'] = DateTime.now().toUtc().toIso8601String();
          binding.reportData = <String, dynamic>{'locationDevice': report};
          debugPrint('LOCATION_DEVICE_EVIDENCE ${jsonEncode(report)}');
        }
      });
      if (streamProbe) {
        expect(
          report['streamHasFix'],
          isTrue,
          reason: 'The real OS stream returned no position.',
        );
        expect(report['streamCoordinatesValid'], isTrue);
        expect(report['streamFixFresh'], isTrue);
        expect(report['streamSubscriptionCancelled'], isTrue);
      } else {
        expect(
          permission,
          LocationPermissionState.granted,
          reason:
              'Real OS permission/service must allow location; see redacted evidence.',
        );
        expect(
          fix,
          isNotNull,
          reason: 'The real OS provider returned no position.',
        );
        expect(fix!.isValid, isTrue);
      }
    },
    skip: !enabled,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
