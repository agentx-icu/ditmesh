// Generates the system-tray icons under apps/ditmesh/assets/tray/.
//
//   dart run tool/gen_tray_icons.dart            (from the repository root)
//
// Output (all rendered from the same "· −" glyph):
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

/// The "· −" glyph (a dot then a dash, Morse for "A" without the letter
/// spacing) centred on a [size]×[size] canvas: black on transparent for the
/// macOS [template], otherwise white on a rounded dark-teal tile.
///
/// Shapes are drawn opaque and their anti-aliased coverage moved into the
/// alpha channel: drawing straight onto transparent pixels blends the edges
/// towards black at full opacity (a dark, jagged rim on the tile).
img.Image _glyph(int size, {required bool template}) {
  final image = img.Image(width: size, height: size, numChannels: 4);
  if (template) {
    final mask = img.Image(width: size, height: size);
    img.fill(mask, color: _black);
    _drawGlyph(mask, size, _white);
    for (final pixel in mask) {
      image.setPixelRgba(pixel.x, pixel.y, 0, 0, 0, pixel.r);
    }
    return image;
  }
  final opaque = img.Image(width: size, height: size);
  img.fill(opaque, color: _tile);
  _drawGlyph(opaque, size, _white);
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

/// Draws the dot and the dash in [color] onto [image].
void _drawGlyph(img.Image image, int size, img.Color color) {
  final centerY = size ~/ 2;
  // Stroke weight: 2 px at 16, 3 px at 22, 4 px at 32.
  final stroke = (size / 8).round().clamp(2, 6);
  final half = stroke ~/ 2;
  final inset = (size * 0.16).round();

  // Dot: a filled circle at the left.
  final dotRadius = (stroke * 0.75).round().clamp(1, size);
  final dotX = inset + dotRadius;
  img.fillCircle(image, x: dotX, y: centerY, radius: dotRadius, color: color);

  // Dash: a rounded bar filling the rest of the width.
  final dashX1 = dotX + dotRadius + (size * 0.12).round();
  final dashX2 = size - 1 - inset;
  if (dashX2 > dashX1) {
    img.fillRect(
      image,
      x1: dashX1,
      y1: centerY - half,
      x2: dashX2,
      y2: centerY - half + stroke - 1,
      color: color,
      radius: half,
    );
  }
}

void _write(String path, List<int> bytes) {
  File(path).writeAsBytesSync(bytes, flush: true);
  stdout.writeln('  $path (${bytes.length} bytes)');
}
