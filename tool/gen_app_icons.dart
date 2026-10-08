// Generates the launcher / app icons for every platform from one drawing.
//
//   dart run tool/gen_app_icons.dart            (from the repository root)
//
// The selected solid signal tower with Morse `−··` cutouts uses one
// checked-in SVG/coverage source, shared with tool/gen_tray_icons.dart.
//
// Output:
//   apps/ditmesh/icon/app_icon_1024.png                 master (square, opaque;
//                                                       store listings start here)
//   apps/ditmesh/ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png
//                                                       every entry of Contents.json,
//                                                       square + opaque (iOS masks)
//   apps/ditmesh/macos/Runner/Assets.xcassets/AppIcon.appiconset/*.png
//                                                       every entry of Contents.json,
//                                                       rounded tile on transparent,
//                                                       inset to Apple's 824/1024 grid
//   apps/ditmesh/android/app/src/main/res/mipmap-*/ic_launcher.png
//                                                       legacy launcher icon (API < 26), rounded
//   apps/ditmesh/android/app/src/main/res/mipmap-*/ic_launcher_foreground.png
//   apps/ditmesh/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
//   apps/ditmesh/android/app/src/main/res/values/ic_launcher_background.xml
//                                                       adaptive icon (API 26+): the glyph
//                                                       on a transparent 108 dp foreground
//                                                       inside the 66 dp safe zone, over the
//                                                       tile colour as background
//   apps/ditmesh/android/app/src/main/res/drawable-*/ic_stat_ditmesh.png
//                                                       notification small icon (24 dp):
//                                                       white glyph on transparent — the
//                                                       status bar uses only the alpha
//   apps/ditmesh/windows/runner/resources/app_icon.ico  16…256 (incl. the 20/24/40 px
//                                                       small-icon sizes of 125–250 % DPI),
//                                                       rounded
//   apps/ditmesh/linux/icons/hicolor/<n>x<n>/apps/ditmesh.png
//                                                       16…512, rounded; installed by the
//                                                       .deb / .rpm next to
//                                                       apps/ditmesh/linux/icu.agentx.ditmesh.desktop
//
// `package:image` is a dev dependency of apps/ditmesh (this repo is a pub
// workspace, so the root resolution already contains it).
// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

import 'icon_glyph.dart';

const String _app = 'apps/ditmesh';
const String _iosSet = '$_app/ios/Runner/Assets.xcassets/AppIcon.appiconset';
const String _macSet = '$_app/macos/Runner/Assets.xcassets/AppIcon.appiconset';
const Map<String, int> _androidDensities = {
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};
// Notification small icon: 24 dp per density.
const Map<String, int> _statusDensities = {
  'mdpi': 24,
  'hdpi': 36,
  'xhdpi': 48,
  'xxhdpi': 72,
  'xxxhdpi': 96,
};
const List<int> _icoSizes = [16, 20, 24, 32, 40, 48, 64, 128, 256];
const List<int> _hicolorSizes = [16, 24, 32, 48, 64, 128, 256, 512];

final img.Color _transparent = img.ColorRgba8(0, 0, 0, 0);
final img.Color _white = img.ColorRgba8(255, 255, 255, 255);
final img.Color _tile = img.ColorRgba8(0x1D, 0x60, 0x63, 255);

void main(List<String> args) {
  if (!File('pubspec.yaml').existsSync() || !Directory('apps').existsSync()) {
    stderr.writeln('[gen_app_icons] run from the repository root');
    exit(1);
  }
  var files = 0;

  // Master: 1024, opaque square (what the stores ask for).
  final master = _icon(1024, rounded: false);
  Directory('$_app/icon').createSync(recursive: true);
  _write('$_app/icon/app_icon_1024.png', img.encodePng(master));
  files++;

  // iOS: opaque squares in every size Contents.json lists (iOS applies the
  // mask itself and rejects alpha in the marketing icon).
  for (final entry in _appIconSet(_iosSet)) {
    final image = _icon(entry.pixels, rounded: false);
    _write('$_iosSet/${entry.filename}', img.encodePng(image));
    files++;
  }

  // macOS: rounded tile on transparent, Big Sur style. Apple's grid draws the
  // tile at 824/1024 with an even margin; a full-bleed tile sits visibly
  // larger than every other icon in the Dock and Launchpad.
  for (final entry in _appIconSet(_macSet)) {
    final image = _macIcon(entry.pixels);
    _write('$_macSet/${entry.filename}', img.encodePng(image));
    files++;
  }

  // Android: legacy launcher icon per density, plus the adaptive layers.
  const res = '$_app/android/app/src/main/res';
  for (final density in _androidDensities.entries) {
    final dir = Directory('$res/mipmap-${density.key}')
      ..createSync(recursive: true);
    final image = _icon(density.value, rounded: true);
    _write('${dir.path}/ic_launcher.png', img.encodePng(image));
    // Foreground: 108 dp canvas (48 dp icon × 2.25), glyph within 66 dp.
    final fgSize = (density.value * 108 / 48).round();
    _write(
      '${dir.path}/ic_launcher_foreground.png',
      img.encodePng(_adaptiveForeground(fgSize)),
    );
    files += 2;
  }
  Directory('$res/mipmap-anydpi-v26').createSync(recursive: true);
  _writeText(
    '$res/mipmap-anydpi-v26/ic_launcher.xml',
    '''
<?xml version="1.0" encoding="utf-8"?>
<!-- Generated by tool/gen_app_icons.dart -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
'''
        .trimLeft(),
  );
  Directory('$res/values').createSync(recursive: true);
  _writeText(
    '$res/values/ic_launcher_background.xml',
    '''
<?xml version="1.0" encoding="utf-8"?>
<!-- Generated by tool/gen_app_icons.dart; the tray / launcher tile colour -->
<resources>
    <color name="ic_launcher_background">#1D6063</color>
</resources>
'''
        .trimLeft(),
  );
  files += 2;

  // Notification small icon: Android draws it from the alpha channel only, so
  // an opaque launcher bitmap becomes a solid white square in the status bar.
  // The Dart side names it by string (FlutterLocalNotificationsApi), which
  // release resource shrinking cannot see — res/raw/keep.xml pins it.
  for (final density in _statusDensities.entries) {
    final dir = Directory('$res/drawable-${density.key}')
      ..createSync(recursive: true);
    _write(
      '${dir.path}/ic_stat_ditmesh.png',
      img.encodePng(_statusIcon(density.value)),
    );
    files++;
  }
  Directory('$res/raw').createSync(recursive: true);
  _writeText(
    '$res/raw/keep.xml',
    '''
<?xml version="1.0" encoding="utf-8"?>
<!-- Generated by tool/gen_app_icons.dart. Resources referenced only by name
     from Dart (the notification small icon) survive resource shrinking. -->
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@drawable/ic_stat_ditmesh" />
'''
        .trimLeft(),
  );
  files++;

  // Windows: one multi-resolution .ico, each size an independent entry
  // (addFrame would make an animated PNG inside the first entry).
  final frames = [for (final size in _icoSizes) _icon(size, rounded: true)];
  _write(
    '$_app/windows/runner/resources/app_icon.ico',
    img.IcoEncoder().encodeImages(frames),
  );
  files++;

  // Linux: one PNG per freedesktop hicolor size, so panels and launchers pick
  // a render drawn for their size (the packages install the whole tree).
  for (final size in _hicolorSizes) {
    final dir = Directory('$_app/linux/icons/hicolor/${size}x$size/apps')
      ..createSync(recursive: true);
    _write(
      '${dir.path}/ditmesh.png',
      img.encodePng(_icon(size, rounded: true)),
    );
    files++;
  }

  stdout.writeln('[gen_app_icons] wrote $files files');
}

/// One `Contents.json` entry resolved to its pixel edge (`size × scale`).
class _IconEntry {
  const _IconEntry(this.filename, this.pixels);
  final String filename;
  final int pixels;
}

/// Reads an `.appiconset/Contents.json` and returns each distinct filename
/// with its pixel size (the same file may be listed for several idioms).
List<_IconEntry> _appIconSet(String dir) {
  final json =
      jsonDecode(File('$dir/Contents.json').readAsStringSync())
          as Map<String, dynamic>;
  final images = (json['images'] as List<dynamic>).cast<Map<String, dynamic>>();
  final seen = <String>{};
  final entries = <_IconEntry>[];
  for (final image in images) {
    final filename = image['filename'] as String?;
    if (filename == null || !seen.add(filename)) continue;
    final size = double.parse((image['size'] as String).split('x').first);
    final scale = int.parse((image['scale'] as String).replaceAll('x', ''));
    entries.add(_IconEntry(filename, (size * scale).round()));
  }
  return entries;
}

/// The icon at [size]: the tile (rounded on transparent, or full-bleed
/// square) with the signal tower centred on it.
img.Image _icon(int size, {required bool rounded}) {
  // Drawn opaque (RGB) first. Square icons stay RGB: App Store Connect
  // rejects an alpha channel in the 1024 marketing icon.
  final opaque = img.Image(width: size, height: size);
  img.fill(opaque, color: _tile);
  drawTowerOnTile(opaque, _white);
  if (!rounded) return opaque;

  // Rounded: the tile shape as an anti-aliased coverage mask moved into the
  // alpha channel. Drawing the tile straight onto transparent pixels blends
  // the corner edges towards black at full opacity — a dark, jagged rim.
  final shape = img.Image(width: size, height: size);
  img.fill(shape, color: img.ColorRgb8(0, 0, 0));
  img.fillRect(
    shape,
    x1: 0,
    y1: 0,
    x2: size - 1,
    y2: size - 1,
    color: img.ColorRgb8(255, 255, 255),
    radius: (size * 0.22).round(),
  );
  final image = img.Image(width: size, height: size, numChannels: 4);
  for (final pixel in opaque) {
    final coverage = shape.getPixel(pixel.x, pixel.y).r;
    image.setPixelRgba(pixel.x, pixel.y, pixel.r, pixel.g, pixel.b, coverage);
  }
  return image;
}

/// Adaptive-icon foreground (also the themed-icon monochrome layer): the
/// glyph on a transparent canvas, scaled so it sits inside the 66/108 safe
/// zone (launchers mask the outer 21 dp on every side) at the same proportions
/// that zone the tiles use.
img.Image _adaptiveForeground(int size) => _whiteGlyph(size, 66 / 108);

/// macOS app icon: the rounded tile drawn on Apple's icon grid — an 824 px
/// tile centred on the 1024 px canvas (100 px transparent margin), scaled
/// down proportionally for the smaller sizes.
img.Image _macIcon(int size) {
  final image = img.Image(width: size, height: size, numChannels: 4);
  img.fill(image, color: _transparent);
  final body = (size * 824 / 1024).round();
  final offset = (size - body) ~/ 2;
  // Copied, not composited: blending the tile's soft edge over transparent
  // black would darken it again.
  for (final pixel in _icon(body, rounded: true)) {
    image.setPixelRgba(
      pixel.x + offset,
      pixel.y + offset,
      pixel.r,
      pixel.g,
      pixel.b,
      pixel.a,
    );
  }
  return image;
}

/// Android notification small icon: the tower in white on a transparent
/// 24 dp canvas, filling the 20 dp live area (2 dp padding per side).
img.Image _statusIcon(int size) => _whiteCoverage(fittedTowerMask(size));

/// The tower as white with anti-aliased alpha on a transparent canvas.
/// Drawn as a white-on-black coverage mask first and the mask moved into the
/// alpha channel: drawing straight onto transparent pixels blends the edges
/// towards black at full opacity, which leaves grey specks on the launcher
/// tile and hard edges in the status bar.
img.Image _whiteGlyph(int size, double scale) =>
    _whiteCoverage(towerMask(size, scale: scale));

img.Image _whiteCoverage(img.Image mask) {
  final image = img.Image(
    width: mask.width,
    height: mask.height,
    numChannels: 4,
  );
  for (final pixel in mask) {
    image.setPixelRgba(pixel.x, pixel.y, 255, 255, 255, pixel.r);
  }
  return image;
}

void _writeText(String path, String text) {
  File(path).writeAsStringSync(text, flush: true);
  stdout.writeln('  $path (${text.length} chars)');
}

void _write(String path, List<int> bytes) {
  File(path).writeAsBytesSync(bytes, flush: true);
  stdout.writeln('  $path (${bytes.length} bytes)');
}
