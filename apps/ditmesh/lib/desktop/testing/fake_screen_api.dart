import 'dart:ui';

import '../screen_api.dart';

/// [ScreenApi] returning a fixed list of work areas (primary first).
class FakeScreenApi implements ScreenApi {
  FakeScreenApi([
    this.areas = const [Rect.fromLTWH(0, 0, 1920, 1080)],
    this.error,
  ]);

  List<Rect> areas;

  /// When set, [workAreas] throws it (headless / exotic WM).
  Object? error;

  int lookups = 0;

  @override
  Future<List<Rect>> workAreas() async {
    lookups++;
    final e = error;
    if (e != null) throw e;
    return areas;
  }
}
