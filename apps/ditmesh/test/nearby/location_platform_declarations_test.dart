import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'location is optional, foreground only on Android and Apple platforms',
    () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifest, contains('android.permission.ACCESS_COARSE_LOCATION'));
      expect(manifest, contains('android.permission.ACCESS_FINE_LOCATION'));
      expect(manifest, isNot(contains('ACCESS_BACKGROUND_LOCATION')));
      expect(
        manifest,
        contains(
          'android.permission.FOREGROUND_SERVICE_LOCATION" tools:node="remove"',
        ),
      );
      for (final platform in ['ios', 'macos']) {
        expect(
          File('$platform/Runner/Info.plist').readAsStringSync(),
          contains('NSLocationWhenInUseUsageDescription'),
        );
        final localized = Directory('$platform/Runner')
            .listSync()
            .whereType<Directory>()
            .where(
              (d) =>
                  d.path.endsWith('.lproj') && !d.path.endsWith('Base.lproj'),
            );
        for (final directory in localized) {
          final strings = File('${directory.path}/InfoPlist.strings');
          expect(
            strings.readAsStringSync(),
            contains('NSLocationWhenInUseUsageDescription'),
            reason: strings.path,
          );
        }
      }
      for (final file in [
        'DebugProfile.entitlements',
        'Release.entitlements',
      ]) {
        expect(
          File('macos/Runner/$file').readAsStringSync(),
          contains('com.apple.security.personal-information.location'),
        );
      }
      expect(
        File('ios/Podfile').readAsStringSync(),
        contains('BYPASS_PERMISSION_LOCATION_ALWAYS=1'),
      );
    },
  );
}
