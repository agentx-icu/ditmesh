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

    test('predictive back is enabled explicitly', () {
      // Android 16 enables OnBackInvokedCallback for targetSdk 36; the
      // attribute makes Android 13-15 behave the same. Flutter handles the
      // gesture through PopScope (there is no WillPopScope in the app).
      expect(
        application,
        contains('android:enableOnBackInvokedCallback="true"'),
      );
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

  group('Android Gradle', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    test('SDK levels are pinned, not inherited from the Flutter plugin', () {
      // A Flutter upgrade must not move the store-facing levels silently;
      // raise them together with doc/release/APP_STORE.md. Play requires
      // targetSdk 36 for new apps and updates since 2026-08-31.
      expect(gradle, matches(RegExp(r'^\s*compileSdk = 36$', multiLine: true)));
      expect(gradle, matches(RegExp(r'^\s*minSdk = 24$', multiLine: true)));
      expect(gradle, matches(RegExp(r'^\s*targetSdk = 36$', multiLine: true)));
      for (final inherited in [
        'flutter.compileSdkVersion',
        'flutter.minSdkVersion',
        'flutter.targetSdkVersion',
      ]) {
        expect(gradle, isNot(contains(inherited)), reason: inherited);
      }
    });
  });

  group('Android native build', () {
    test('libtim2tox_ffi.so is linked and checked for 16 KB pages', () {
      // Google Play requires 16 KB page alignment of every 64-bit library in
      // apps targeting Android 15+. The flags are explicit so the result does
      // not depend on the NDK (r27 needs the opt-in, r26 never aligns), and
      // both packaged libraries are verified with readelf after the build
      // and again when a CI artifact is re-staged (--stage-only).
      final script = File('../../tool/ci/build_tim2tox.sh').readAsStringSync();
      expect(script, contains('ANDROID_PAGE_SIZE=16384'));
      expect(script, contains(r'-Wl,-z,max-page-size=$ANDROID_PAGE_SIZE'));
      expect(script, contains(r'-Wl,-z,common-page-size=$ANDROID_PAGE_SIZE'));
      expect(script, contains('-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON'));
      expect(
        script,
        contains(r'-DCMAKE_SHARED_LINKER_FLAGS="$ANDROID_PAGE_SIZE_LDFLAGS"'),
      );
      final checks = RegExp(
        r'^\s*(?:while .*; do )?assert_android_page_alignment ',
        multiLine: true,
      ).allMatches(script);
      expect(checks.length, greaterThanOrEqualTo(3));
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

    test('iPhone rotates to three orientations, iPad to all four', () {
      // No upside-down on iPhone; all four on iPad with no
      // UIRequiresFullScreen, so Split View, Slide Over and Stage Manager
      // apply down to 320 pt, the narrowest layout the app can get.
      List<String> orientations(String key) {
        final m = RegExp(
          '<key>$key</key>\\s*<array>(.*?)</array>',
          dotAll: true,
        ).firstMatch(plist);
        expect(m, isNotNull, reason: key);
        return RegExp(
          r'<string>([^<]+)</string>',
        ).allMatches(m!.group(1)!).map((s) => s.group(1)!).toList();
      }

      expect(orientations('UISupportedInterfaceOrientations'), [
        'UIInterfaceOrientationPortrait',
        'UIInterfaceOrientationLandscapeLeft',
        'UIInterfaceOrientationLandscapeRight',
      ]);
      expect(orientations('UISupportedInterfaceOrientations~ipad'), [
        'UIInterfaceOrientationPortrait',
        'UIInterfaceOrientationPortraitUpsideDown',
        'UIInterfaceOrientationLandscapeLeft',
        'UIInterfaceOrientationLandscapeRight',
      ]);
      expect(plist, isNot(contains('UIRequiresFullScreen')));
    });

    test('export compliance is declared, never silenced', () {
      // Every build ships libsodium (Tox), so the answer is true. The App
      // Store Connect questions are closed with the owner's compliance code
      // (doc/release/APP_STORE.md, "iOS export compliance"), never by
      // flipping this flag; a code, once added, must not be empty.
      expect(
        plist,
        matches(RegExp(r'<key>ITSAppUsesNonExemptEncryption</key>\s*<true/>')),
      );
      final code = RegExp(
        r'<key>ITSEncryptionExportComplianceCode</key>\s*<string>([^<]*)</string>',
      ).firstMatch(plist);
      if (code != null) expect(code.group(1)!.trim(), isNotEmpty);
    });

    test('data protection stays at the platform default or stronger', () {
      // Without the entitlement iOS applies
      // NSFileProtectionCompleteUntilFirstUserAuthentication to the identity
      // files (encrypted until the first unlock after boot, readable in the
      // background afterwards, which the durability flush needs).
      // NSFileProtectionNone would leave them readable before unlock.
      final entitlements = File(
        'ios/Runner/Runner.entitlements',
      ).readAsStringSync();
      expect(entitlements, isNot(contains('NSFileProtectionNone')));
    });
  });
}
