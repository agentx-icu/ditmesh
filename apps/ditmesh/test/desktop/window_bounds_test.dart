import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/desktop/window_bounds.dart';

void main() {
  const primary = Rect.fromLTWH(0, 0, 1920, 1040); // 1080 minus a taskbar
  const secondary = Rect.fromLTWH(1920, 0, 1280, 720);
  const minSize = Size(360, 640);

  group('WindowBounds encode/decode', () {
    test('round-trips bounds and the maximised flag', () {
      const bounds = WindowBounds(
        rect: Rect.fromLTWH(100, 50, 1100, 760),
        maximized: true,
      );
      expect(WindowBounds.decode(bounds.encode()), bounds);
    });

    test('rejects garbage, non-objects and non-positive sizes', () {
      expect(WindowBounds.decode(null), isNull);
      expect(WindowBounds.decode(''), isNull);
      expect(WindowBounds.decode('not json'), isNull);
      expect(WindowBounds.decode('[1,2,3]'), isNull);
      expect(WindowBounds.decode('{"left":0,"top":0}'), isNull);
      expect(
        WindowBounds.decode(
          '{"left":0,"top":0,"width":0,"height":600,"maximized":false}',
        ),
        isNull,
      );
      expect(
        WindowBounds.decode('{"left":"a","top":0,"width":800,"height":600}'),
        isNull,
      );
    });
  });

  group('WindowBounds.fitTo', () {
    test('keeps an on-screen window untouched', () {
      const saved = WindowBounds(rect: Rect.fromLTWH(200, 100, 1100, 760));
      expect(saved.fitTo([primary], minSize), saved);
    });

    test('pulls an off-screen window back onto the primary display', () {
      const saved = WindowBounds(rect: Rect.fromLTWH(-5000, -300, 1100, 760));
      final fitted = saved.fitTo([primary], minSize);
      expect(fitted.rect, const Rect.fromLTWH(0, 0, 1100, 760));
    });

    test('shrinks a window larger than the display and re-anchors it', () {
      const saved = WindowBounds(rect: Rect.fromLTWH(300, 300, 4000, 3000));
      final fitted = saved.fitTo([primary], minSize);
      expect(fitted.rect, const Rect.fromLTWH(0, 0, 1920, 1040));
    });

    test('grows a window below the minimum size', () {
      const saved = WindowBounds(rect: Rect.fromLTWH(10, 10, 100, 100));
      final fitted = saved.fitTo([primary], minSize);
      expect(fitted.rect.size, minSize);
      expect(fitted.rect.topLeft, const Offset(10, 10));
    });

    test('keeps a window whose centre is on a secondary display there', () {
      const saved = WindowBounds(rect: Rect.fromLTWH(2100, 40, 900, 650));
      final fitted = saved.fitTo([primary, secondary], minSize);
      expect(fitted.rect, saved.rect);
    });

    test('clamps within the secondary display, not the primary', () {
      // Bottom edge overshoots the 720-px-tall secondary display.
      const saved = WindowBounds(rect: Rect.fromLTWH(2100, 200, 900, 650));
      final fitted = saved.fitTo([primary, secondary], minSize);
      expect(fitted.rect, const Rect.fromLTWH(2100, 70, 900, 650));
    });

    test('falls back to the primary when no display contains the centre', () {
      // Centre at x=4500: the unplugged third monitor.
      const saved = WindowBounds(rect: Rect.fromLTWH(4000, 0, 1000, 700));
      final fitted = saved.fitTo([primary, secondary], minSize);
      expect(primary.contains(fitted.rect.center), isTrue);
      expect(fitted.rect.size, const Size(1000, 700));
    });

    test('a minimum larger than the display yields the display size', () {
      // Windows 200 % on a 1366×768 panel: 683×384 logical.
      const tiny = Rect.fromLTWH(0, 0, 683, 384);
      const saved = WindowBounds(rect: Rect.fromLTWH(0, 0, 1100, 760));
      final fitted = saved.fitTo([tiny], minSize);
      expect(fitted.rect, tiny);
    });

    test('preserves the maximised flag and is a no-op without displays', () {
      const saved = WindowBounds(
        rect: Rect.fromLTWH(-9999, -9999, 10, 10),
        maximized: true,
      );
      expect(saved.fitTo(const [], minSize), saved);
      expect(saved.fitTo([primary], minSize).maximized, isTrue);
    });
  });

  group('WindowBounds.centered', () {
    test('centres the default size in the work area', () {
      final b = WindowBounds.centered(const Size(1100, 760), primary);
      expect(b.rect, const Rect.fromLTWH(410, 140, 1100, 760));
      expect(b.maximized, isFalse);
    });

    test('shrinks to the work area first', () {
      const small = Rect.fromLTWH(0, 0, 800, 600);
      final b = WindowBounds.centered(const Size(1100, 760), small);
      expect(b.rect, small);
    });

    test('keeps the preferred size when no display is known', () {
      final b = WindowBounds.centered(const Size(1100, 760), null);
      expect(b.rect.size, const Size(1100, 760));
    });
  });

  test('fitSizeToArea shrinks each axis independently', () {
    expect(
      fitSizeToArea(const Size(1100, 760), const Rect.fromLTWH(0, 0, 900, 900)),
      const Size(900, 760),
    );
    expect(fitSizeToArea(const Size(1100, 760), null), const Size(1100, 760));
  });
}
