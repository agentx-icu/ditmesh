import 'dart:ui';

import 'package:screen_retriever/screen_retriever.dart';

import '../screen_api.dart';

/// [ScreenApi] on `screen_retriever`: primary display first, then the rest,
/// each as its visible work area (falling back to the full size when the
/// platform reports none).
class ScreenRetrieverApi implements ScreenApi {
  @override
  Future<List<Rect>> workAreas() async {
    final primary = await screenRetriever.getPrimaryDisplay();
    final areas = <Rect>[_workArea(primary)];
    // Not every backend implements getAllDisplays; the primary alone is a
    // valid (if single-monitor) answer.
    try {
      for (final display in await screenRetriever.getAllDisplays()) {
        if (display.id == primary.id) continue;
        areas.add(_workArea(display));
      }
    } catch (_) {
      // Keep the primary-only list.
    }
    return areas;
  }

  static Rect _workArea(Display display) {
    final origin = display.visiblePosition ?? Offset.zero;
    final size = display.visibleSize ?? display.size;
    return Rect.fromLTWH(origin.dx, origin.dy, size.width, size.height);
  }
}
