// The selected signal-tower/Morse vector is the single geometry source for
// launcher, adaptive, notification and tray icons. The checked-in coverage
// mask is rendered from apps/ditmesh/icon/signal_tower_mask.svg.
// ignore_for_file: depend_on_referenced_packages
import 'dart:io';

import 'package:image/image.dart' as img;

final img.Image _source = img.decodePng(
  File('apps/ditmesh/icon/signal_tower_mask_1024.png').readAsBytesSync(),
)!;

final img.Image _glyphSource = _cropGlyph();

img.Image _cropGlyph() {
  var left = _source.width;
  var top = _source.height;
  var right = 0;
  var bottom = 0;
  for (final pixel in _source) {
    if (pixel.r == 0) continue;
    if (pixel.x < left) left = pixel.x;
    if (pixel.y < top) top = pixel.y;
    if (pixel.x > right) right = pixel.x;
    if (pixel.y > bottom) bottom = pixel.y;
  }
  return img.copyCrop(
    _source,
    x: left,
    y: top,
    width: right - left + 1,
    height: bottom - top + 1,
  );
}

/// Fit the coverage bounds in the notification's centered 20dp live area.
img.Image fittedTowerMask(int size) {
  final edge = (size * 20 / 24).round();
  final ratio = _glyphSource.width / _glyphSource.height;
  final width = ratio > 1 ? edge : (edge * ratio).round();
  final height = ratio > 1 ? (edge / ratio).round() : edge;
  final scaled = img.copyResize(
    _glyphSource,
    width: width,
    height: height,
    interpolation: img.Interpolation.average,
  );
  final output = img.Image(width: size, height: size);
  img.fill(output, color: img.ColorRgb8(0, 0, 0));
  final offsetX = (size - width) ~/ 2;
  final offsetY = (size - height) ~/ 2;
  for (final pixel in scaled) {
    output.setPixelRgb(
      pixel.x + offsetX,
      pixel.y + offsetY,
      pixel.r,
      pixel.g,
      pixel.b,
    );
  }
  return output;
}

/// White geometry on black; RGB coverage becomes alpha for template icons.
img.Image towerMask(int size, {double scale = 1}) {
  final edge = (size * scale).round().clamp(1, 8192);
  final scaled = img.copyResize(
    _source,
    width: edge,
    height: edge,
    interpolation: img.Interpolation.average,
  );
  final output = img.Image(width: size, height: size);
  img.fill(output, color: img.ColorRgb8(0, 0, 0));
  final offset = (size - edge) ~/ 2;
  for (final pixel in scaled) {
    final x = pixel.x + offset;
    final y = pixel.y + offset;
    if (x >= 0 && y >= 0 && x < size && y < size) {
      output.setPixelRgb(x, y, pixel.r, pixel.g, pixel.b);
    }
  }
  return output;
}

void drawTowerOnTile(img.Image image, img.Color color) {
  final mask = towerMask(image.width);
  for (final pixel in mask) {
    final old = image.getPixel(pixel.x, pixel.y);
    final coverage = pixel.r / 255;
    image.setPixelRgb(
      pixel.x,
      pixel.y,
      old.r + (color.r - old.r) * coverage,
      old.g + (color.g - old.g) * coverage,
      old.b + (color.b - old.b) * coverage,
    );
  }
}
