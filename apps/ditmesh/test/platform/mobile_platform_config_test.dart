import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks on the iOS / Android project files: mistakes here never show
/// up in a widget test, only on a store listing or a real phone.
void main() {
  group('Android manifest', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final application = RegExp(
      r'<application\b[^>]*>',
      dotAll: true,
    ).firstMatch(manifest)!.group(0)!;

    test('platform backup and device transfer are disabled', () {
      // The files dir holds the Tox private key and chat history; only the
      // encrypted in-app export may move an identity.
      expect(application, contains('android:allowBackup="false"'));
      expect(application, contains('android:fullBackupContent="false"'));
      final rules = RegExp(
        r'android:dataExtractionRules="@xml/([a-z_]+)"',
      ).firstMatch(application);
      expect(rules, isNotNull);
      final xml = File(
        'android/app/src/main/res/xml/${rules!.group(1)}.xml',
      ).readAsStringSync();
      for (final section in ['cloud-backup', 'device-transfer']) {
        final body = RegExp(
          '<$section>(.*?)</$section>',
          dotAll: true,
        ).firstMatch(xml);
        expect(body, isNotNull, reason: section);
        for (final domain in [
          'root',
          'file',
          'database',
          'sharedpref',
          'external',
          // Device-protected storage (direct boot) too.
          'device_root',
          'device_file',
          'device_database',
          'device_sharedpref',
        ]) {
          expect(
            body!.group(1),
            contains('<exclude domain="$domain"/>'),
            reason: '$section/$domain',
          );
        }
      }
    });

    test('features implied by permissions are optional', () {
      // Each permission implies these features as REQUIRED unless declared
      // otherwise, which filters devices out of the Play listing.
      const implied = {
        'android.permission.CAMERA': [
          'android.hardware.camera',
          'android.hardware.camera.autofocus',
        ],
        'android.permission.RECORD_AUDIO': ['android.hardware.microphone'],
      };
      implied.forEach((permission, features) {
        if (!manifest.contains('"$permission"')) return;
        for (final feature in features) {
          expect(
            manifest,
            matches(
              RegExp(
                '<uses-feature android:name="${RegExp.escape(feature)}" '
                'android:required="false"/>',
              ),
            ),
            reason: '$permission implies $feature',
          );
        }
      });
    });
  });

  group('iOS Info.plist', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    test('no background mode is declared', () {
      // Nothing plays in the background (SidetoneSink stops its voice) and
      // there is no ToxAV, so `audio` / `voip` would be unused modes (App
      // Review 2.5.4); the flush runs under beginBackgroundTask instead.
      expect(plist, isNot(contains('<key>UIBackgroundModes</key>')));
    });
  });
}
