// Guards the generated icon assets (tool/gen_app_icons.dart,
// tool/gen_tray_icons.dart) and every place that references them: a missing
// density, an alpha channel in the App Store icon, an opaque notification
// small icon or a tray path outside the declared assets only shows up on a
// device or in store review otherwise.
//
// Runs with the package root (apps/ditmesh) as the working directory.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ditmesh/desktop/desktop_platform.dart';
import 'package:ditmesh/notifications/flutter_local_notifications_api.dart';

img.Image _png(String path) {
  final img.Image? image = img.decodePng(File(path).readAsBytesSync());
  expect(image, isNotNull, reason: '$path is not a PNG');
  return image!;
}

List<int> _icoSizes(String path) {
  final Uint8List bytes = File(path).readAsBytesSync();
  final img.IcoDecoder decoder = img.IcoDecoder();
  final img.DecodeInfo? info = decoder.startDecode(bytes);
  expect(info, isNotNull, reason: '$path is not an .ico');
  return [
    for (int i = 0; i < info!.numFrames; i++) decoder.decodeFrame(i)!.width,
  ];
}

/// Asset entries under `flutter: assets:` in pubspec.yaml.
List<String> _declaredAssets() {
  final List<String> lines = File('pubspec.yaml').readAsLinesSync();
  final int start = lines.indexWhere((l) => l.trim() == 'assets:');
  expect(start, isNot(-1), reason: 'pubspec.yaml declares no assets');
  final List<String> assets = <String>[];
  for (final String line in lines.skip(start + 1)) {
    final String t = line.trim();
    if (!t.startsWith('- ')) break;
    assets.add(t.substring(2).trim());
  }
  return assets;
}

/// Pixels the status bar / menu bar would draw (alpha > 0) that are not the
/// [r]/[g]/[b] glyph colour: a single-colour glyph keeps its colour on the
/// anti-aliased edge too, only the alpha fades.
int _offColourVisiblePixels(img.Image image, int r, int g, int b) {
  int bad = 0;
  for (final img.Pixel p in image) {
    if (p.a > 0 && (p.r != r || p.g != g || p.b != b)) bad++;
  }
  return bad;
}

/// Asserts [image] is a drawn, anti-aliased glyph on transparency: some fully
/// opaque pixels, some soft edge pixels, and a transparent corner.
void _expectGlyphOnTransparent(img.Image image, String reason) {
  int opaque = 0;
  int soft = 0;
  for (final img.Pixel p in image) {
    if (p.a == 255) opaque++;
    if (p.a > 0 && p.a < 255) soft++;
  }
  expect(opaque, greaterThan(0), reason: '$reason: no glyph drawn');
  expect(soft, greaterThan(0), reason: '$reason: edges not anti-aliased');
  expect(_transparentAt(image, 0, 0), isTrue, reason: reason);
}

bool _transparentAt(img.Image image, int x, int y) =>
    image.getPixel(x, y).a == 0;

void main() {
  group('tray icons', () {
    final Map<TargetPlatform, String?> byPlatform = {
      for (final TargetPlatform p in TargetPlatform.values)
        p: TrayIconAssets.forPlatform(p),
    };

    test('every desktop has one, mobile has none', () {
      expect(byPlatform[TargetPlatform.macOS], isNotNull);
      expect(byPlatform[TargetPlatform.linux], isNotNull);
      expect(byPlatform[TargetPlatform.windows], isNotNull);
      expect(byPlatform[TargetPlatform.android], isNull);
      expect(byPlatform[TargetPlatform.iOS], isNull);
    });

    test('exist on disk and are bundled (declared in pubspec.yaml)', () {
      // tray_manager resolves Linux / Windows icons as files under
      // data/flutter_assets/ and macOS ones through rootBundle, so an
      // undeclared path is missing from every release bundle.
      final List<String> declared = _declaredAssets();
      for (final String path in byPlatform.values.whereType<String>()) {
        expect(File(path).existsSync(), isTrue, reason: path);
        expect(
          declared.any(
            (a) => a == path || (a.endsWith('/') && path.startsWith(a)),
          ),
          isTrue,
          reason: '$path is not under any pubspec asset entry',
        );
      }
    });

    test('macOS template is black glyph on transparent', () {
      final img.Image image = _png(TrayIconAssets.macTemplate);
      expect(image.numChannels, 4);
      _expectGlyphOnTransparent(image, TrayIconAssets.macTemplate);
      expect(_offColourVisiblePixels(image, 0, 0, 0), 0);
    });

    test('Windows tray .ico carries the small-icon DPI sizes', () {
      expect(
        _icoSizes(TrayIconAssets.windowsIco),
        containsAll(<int>[16, 20, 24, 32, 40, 48]),
      );
    });
  });

  group('Android', () {
    const String res = 'android/app/src/main/res';
    const Map<String, int> statusPx = {
      'mdpi': 24,
      'hdpi': 36,
      'xhdpi': 48,
      'xxhdpi': 72,
      'xxxhdpi': 96,
    };

    test('notification small icon is a white-on-transparent drawable', () {
      const String ref = FlutterLocalNotificationsApi.defaultAndroidIcon;
      expect(ref, startsWith('@drawable/'));
      final String name = ref.substring('@drawable/'.length);
      for (final MapEntry<String, int> d in statusPx.entries) {
        final String path = '$res/drawable-${d.key}/$name.png';
        final img.Image image = _png(path);
        expect(image.width, d.value, reason: path);
        expect(image.height, d.value, reason: path);
        // Android tints small icons from alpha alone: an opaque bitmap (the
        // launcher icon) renders as a solid square.
        _expectGlyphOnTransparent(image, path);
        expect(_offColourVisiblePixels(image, 255, 255, 255), 0, reason: path);
      }
      // Named only from Dart, so release resource shrinking must keep it.
      final String keepXml = File(
        '$res/raw/keep.xml',
      ).readAsStringSync().replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
      final String? keep = RegExp(
        r'tools:keep="([^"]*)"',
      ).firstMatch(keepXml)?.group(1);
      expect(keep, isNotNull, reason: 'keep.xml has no tools:keep');
      expect(keep!.split(',').map((e) => e.trim()), contains(ref));
    });

    test('launcher icon and adaptive layers exist in every density', () {
      final String manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
      const Map<String, int> launcherPx = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };
      for (final MapEntry<String, int> d in launcherPx.entries) {
        expect(_png('$res/mipmap-${d.key}/ic_launcher.png').width, d.value);
        final int fg = d.value * 108 ~/ 48;
        expect(
          _png('$res/mipmap-${d.key}/ic_launcher_foreground.png').width,
          fg,
        );
      }
      final String adaptive = File(
        '$res/mipmap-anydpi-v26/ic_launcher.xml',
      ).readAsStringSync();
      expect(adaptive, contains('@mipmap/ic_launcher_foreground'));
      expect(adaptive, contains('<monochrome'));
    });
  });

  group('Apple app icon sets', () {
    List<(String, int)> entries(String dir) {
      final Map<String, dynamic> json =
          jsonDecode(File('$dir/Contents.json').readAsStringSync())
              as Map<String, dynamic>;
      return [
        for (final dynamic e in json['images'] as List<dynamic>)
          (
            '$dir/${(e as Map<String, dynamic>)['filename'] as String}',
            (double.parse((e['size'] as String).split('x').first) *
                    int.parse((e['scale'] as String).replaceAll('x', '')))
                .round(),
          ),
      ];
    }

    test('iOS: every entry present, sized, and opaque (no alpha)', () {
      final List<(String, int)> icons = entries(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset',
      );
      expect(icons.map((e) => e.$2), contains(1024));
      for (final (String path, int px) in icons) {
        final img.Image image = _png(path);
        expect(image.width, px, reason: path);
        // App Store Connect rejects an alpha channel in the marketing icon.
        expect(image.hasAlpha, isFalse, reason: path);
      }
    });

    test('macOS: every entry present, sized, on the inset icon grid', () {
      final List<(String, int)> icons = entries(
        'macos/Runner/Assets.xcassets/AppIcon.appiconset',
      );
      for (final (String path, int px) in icons) {
        final img.Image image = _png(path);
        expect(image.width, px, reason: path);
        if (px < 64) continue;
        // Apple's grid keeps ~100/1024 transparent margin around the tile; a
        // full-bleed tile looks oversized next to every other Dock icon.
        final int margin = (px * 0.06).floor();
        expect(_transparentAt(image, margin, px ~/ 2), isTrue, reason: path);
        expect(_transparentAt(image, px ~/ 2, margin), isTrue, reason: path);
        expect(_transparentAt(image, px ~/ 2, px ~/ 2), isFalse, reason: path);
      }
    });
  });

  test('Windows app icon carries 16–256 px frames', () {
    expect(
      _icoSizes('windows/runner/resources/app_icon.ico'),
      containsAll(<int>[16, 20, 24, 32, 40, 48, 64, 128, 256]),
    );
    expect(
      File('windows/runner/Runner.rc').readAsStringSync(),
      contains(r'"resources\\app_icon.ico"'),
    );
  });

  test('Linux desktop entry Icon= resolves to the shipped hicolor theme', () {
    final String desktop = File(
      'linux/icu.agentx.ditmesh.desktop',
    ).readAsStringSync();
    final String icon = RegExp(
      r'^Icon=(.+)$',
      multiLine: true,
    ).firstMatch(desktop)!.group(1)!.trim();
    for (final int px in const [16, 24, 32, 48, 64, 128, 256, 512]) {
      final String path = 'linux/icons/hicolor/${px}x$px/apps/$icon.png';
      expect(_png(path).width, px, reason: path);
    }
    // The bare bundle's window-icon fallback (runner/my_application.cc).
    expect(
      File('linux/CMakeLists.txt').readAsStringSync(),
      contains('icons/hicolor/256x256/apps/$icon.png'),
    );
  });
}
