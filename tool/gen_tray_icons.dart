// Generates the system-tray icons under apps/ditmesh/assets/tray/.
//
//   dart run tool/gen_tray_icons.dart            (from the repository root)
//
// Output (all rendered from the selected solid signal-tower/Morse glyph):
//   tray_template_{16,22,32}.png  macOS template: black glyph on transparent,
//                                 AppKit tints it for light/dark menu bars.
//   tray_icon_{16,22,32}.png      Linux (AppIndicator): white glyph on a
//                                 rounded dark-teal tile so it reads on any
//                                 panel colour.
//   tray_icon.ico                 Windows: tile renders at the small-icon
//                                 sizes of 100–300 % DPI (16/20/24/32/40/48,
//                                 SM_CXSMICON) packed into one multi-resolution
//                                 .ico (PNG-compressed entries, supported since
//                                 Vista). The tray loads it with
//                                 LoadImage(IMAGE_ICON), which rejects a bare
//                                 PNG and otherwise rescales the nearest size.
//
// `package:image` is a dev dependency of apps/ditmesh (this repo is a pub
// workspace, so the root resolution already contains it).
// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:image/image.dart' as img;

import 'icon_glyph.dart';

const List<int> _sizes = [16, 22, 32];
// What LoadImage(..., SM_CXSMICON) asks for at 100/125/150/200/250/300 %.
const List<int> _icoSizes = [16, 20, 24, 32, 40, 48];
const String _outDir = 'apps/ditmesh/assets/tray';

final img.Color _black = img.ColorRgb8(0, 0, 0);
final img.Color _white = img.ColorRgb8(255, 255, 255);
final img.Color _tile = img.ColorRgb8(0x1D, 0x60, 0x63);

void main(List<String> args) {
  if (!File('pubspec.yaml').existsSync() || !Directory('apps').existsSync()) {
    stderr.writeln('[gen_tray_icons] run from the repository root');
    exit(1);
  }
  final dir = Directory(_outDir)..createSync(recursive: true);

  for (final size in _sizes) {
    final template = _glyph(size, template: true);
    _write('${dir.path}/tray_template_$size.png', img.encodePng(template));

    final tile = _glyph(size, template: false);
    _write('${dir.path}/tray_icon_$size.png', img.encodePng(tile));
  }

  // Each size is an independent .ico entry (addFrame would nest the other
  // sizes as an animated PNG inside the 16 px entry).
  final tiles = [for (final size in _icoSizes) _glyph(size, template: false)];
  _write('${dir.path}/tray_icon.ico', img.IcoEncoder().encodeImages(tiles));
  stdout.writeln(
    '[gen_tray_icons] wrote ${_sizes.length * 2 + 1} files to '
    '${dir.path}',
  );
}

/// The tower mask is black/transparent on macOS, white/teal elsewhere.
img.Image _glyph(int size, {required bool template}) {
  final image = img.Image(width: size, height: size, numChannels: 4);
  if (template) {
    final mask = towerMask(size, scale: 1.2);
    for (final pixel in mask) {
      image.setPixelRgba(pixel.x, pixel.y, 0, 0, 0, pixel.r);
    }
    return image;
  }
  final opaque = img.Image(width: size, height: size);
  img.fill(opaque, color: _tile);
  drawTowerOnTile(opaque, _white);
  final shape = img.Image(width: size, height: size);
  img.fill(shape, color: _black);
  img.fillRect(
    shape,
    x1: 0,
    y1: 0,
    x2: size - 1,
    y2: size - 1,
    color: _white,
    radius: (size * 0.22).round(),
  );
  for (final pixel in opaque) {
    final coverage = shape.getPixel(pixel.x, pixel.y).r;
    image.setPixelRgba(pixel.x, pixel.y, pixel.r, pixel.g, pixel.b, coverage);
  }
  return image;
}

void _write(String path, List<int> bytes) {
  File(path).writeAsBytesSync(bytes, flush: true);
  stdout.writeln('  $path (${bytes.length} bytes)');
}
