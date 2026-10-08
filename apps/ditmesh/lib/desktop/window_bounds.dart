import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

/// Persisted window geometry plus the maximised flag, with the pure
/// clamping rules that keep a restored window visible on today's displays.
///
/// Everything here is plain Dart so the rules are unit-testable without a
/// window or a screen.
class WindowBounds {
  const WindowBounds({required this.rect, this.maximized = false});

  /// Logical-pixel bounds (what `window_manager` reads and writes).
  final Rect rect;

  final bool maximized;

  /// Parses [WindowBounds.encode] output. Returns null for anything that is
  /// not a finite, positively-sized rectangle, so a corrupt or hand-edited
  /// preference degrades to "first launch" instead of an invisible window.
  static WindowBounds? decode(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) return null;
      final left = _finite(decoded['left']);
      final top = _finite(decoded['top']);
      final width = _finite(decoded['width']);
      final height = _finite(decoded['height']);
      if (left == null || top == null || width == null || height == null) {
        return null;
      }
      if (width <= 0 || height <= 0) return null;
      return WindowBounds(
        rect: Rect.fromLTWH(left, top, width, height),
        maximized: decoded['maximized'] == true,
      );
    } on FormatException {
      return null;
    }
  }

  static double? _finite(Object? value) {
    if (value is! num) return null;
    final d = value.toDouble();
    return d.isFinite ? d : null;
  }

  String encode() => jsonEncode(<String, Object>{
    'left': rect.left,
    'top': rect.top,
    'width': rect.width,
    'height': rect.height,
    'maximized': maximized,
  });

  /// A window of [preferred] size (shrunk to fit) centred in [area]. With no
  /// display information the window keeps [preferred] at the origin and the
  /// OS places it.
  static WindowBounds centered(Size preferred, Rect? area) {
    final size = fitSizeToArea(preferred, area);
    if (area == null) {
      return WindowBounds(rect: Rect.fromLTWH(0, 0, size.width, size.height));
    }
    final left = area.left + (area.width - size.width) / 2;
    final top = area.top + (area.height - size.height) / 2;
    return WindowBounds(
      rect: Rect.fromLTWH(
        left.roundToDouble(),
        top.roundToDouble(),
        size.width,
        size.height,
      ),
    );
  }

  /// Clamps this window onto one of [areas] (work areas in logical pixels,
  /// primary first) so that it is fully visible and at least [minSize].
  ///
  /// The target display is the one containing the window's centre — a user
  /// who keeps the app on a second monitor gets it back there. If no display
  /// contains the centre (monitor unplugged, DPI change) the primary is used.
  /// A [minSize] larger than the display (Windows 200 % on a small panel)
  /// yields the display size, matching what the OS would show anyway.
  WindowBounds fitTo(List<Rect> areas, Size minSize) {
    if (areas.isEmpty) return this;
    final target = _displayContaining(areas, rect.center) ?? areas.first;
    final min = fitSizeToArea(minSize, target);
    final width = rect.width.clamp(min.width, target.width);
    final height = rect.height.clamp(min.height, target.height);
    final left = rect.left.clamp(target.left, target.right - width);
    final top = rect.top.clamp(target.top, target.bottom - height);
    return WindowBounds(
      rect: Rect.fromLTWH(left, top, width, height),
      maximized: maximized,
    );
  }

  static Rect? _displayContaining(List<Rect> areas, Offset point) {
    for (final area in areas) {
      if (area.contains(point)) return area;
    }
    return null;
  }

  WindowBounds copyWith({Rect? rect, bool? maximized}) => WindowBounds(
    rect: rect ?? this.rect,
    maximized: maximized ?? this.maximized,
  );

  @override
  bool operator ==(Object other) =>
      other is WindowBounds &&
      other.rect == rect &&
      other.maximized == maximized;

  @override
  int get hashCode => Object.hash(rect, maximized);

  @override
  String toString() => 'WindowBounds($rect, maximized: $maximized)';
}

/// [preferred] shrunk so it fits inside [area] (unchanged without an area).
Size fitSizeToArea(Size preferred, Rect? area) {
  if (area == null) return preferred;
  return Size(
    math.min(preferred.width, area.width),
    math.min(preferred.height, area.height),
  );
}
