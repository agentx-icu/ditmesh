// Flutter-layer screenshot harness for the integration tests.
//
// `package:integration_test` only has native `takeScreenshot` support on
// Android and iOS (Flutter 3.41.9). Rendering the app inside a
// [RepaintBoundary] and calling `toImage` works on all five platforms, needs
// no OS permission, and never sees another window. The PNG bytes travel to
// the host inside `binding.reportData` (base64, so the VM-service JSON stays
// small); `test_driver/integration_test.dart` writes them to disk.
//
// Knobs (all `--dart-define`):
//   DITMESH_SHOT_PLATFORM     folder name in the report (default: the host OS)
//   DITMESH_SHOT_LOCALES      comma list, default `en,zh`
//   DITMESH_SHOT_PIXEL_RATIO  capture scale; default 1.0 on desktop, the native dpr on iOS
//                             (App Store sizes), min(dpr, 2) on Android
//   DITMESH_SHOT_WINDOW       desktop window size `WxH`, default 1280x800
//   DITMESH_SHOT_THEME        light (default) | dark | system
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:ditmesh/di/app_settings.dart';
import 'package:ditmesh/ui/appearance/ui_style.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

const String _platformDefine = String.fromEnvironment('DITMESH_SHOT_PLATFORM');
const String _localesDefine = String.fromEnvironment(
  'DITMESH_SHOT_LOCALES',
  defaultValue: 'en,zh',
);
const String _pixelRatioDefine = String.fromEnvironment(
  'DITMESH_SHOT_PIXEL_RATIO',
);
const String _windowDefine = String.fromEnvironment(
  'DITMESH_SHOT_WINDOW',
  defaultValue: '1280x800',
);
const String _themeDefine = String.fromEnvironment(
  'DITMESH_SHOT_THEME',
  defaultValue: 'light',
);

/// Key under `binding.reportData` holding the captured frames.
const String kShotReportKey = 'ditmeshScreenshots';

bool get isDesktopHost =>
    !kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows);

/// Folder name for this run's frames.
String shotPlatform() {
  if (_platformDefine.isNotEmpty) return _platformDefine;
  if (Platform.isMacOS) return 'macos';
  if (Platform.isLinux) return 'linux';
  if (Platform.isWindows) return 'windows';
  if (Platform.isIOS) return 'ios';
  if (Platform.isAndroid) return 'android';
  return 'unknown';
}

List<String> shotLocales() => _localesDefine
    .split(',')
    .map((l) => l.trim())
    .where((l) => l.isNotEmpty)
    .toList(growable: false);

/// Largest window edge [desktopWindowSize] accepts, in logical pixels.
const double kMaxWindowEdge = 8192;

/// [DITMESH_SHOT_PIXEL_RATIO] must fall inside this range.
const double kMinPixelRatio = 0.25;
const double kMaxPixelRatio = 4;

const Set<String> kShotThemes = <String>{'light', 'dark', 'system'};

/// The `DITMESH_SHOT_WINDOW` define as a size. A malformed or out-of-range
/// value throws instead of silently falling back, so a typo in a capture
/// command cannot produce frames of the wrong size.
Size desktopWindowSize() => parseWindowSize(_windowDefine);

Size parseWindowSize(String define) {
  final parts = define.toLowerCase().split('x');
  final w = parts.length == 2 ? double.tryParse(parts[0]) : null;
  final h = parts.length == 2 ? double.tryParse(parts[1]) : null;
  bool ok(double? v) => v != null && v.isFinite && v > 0 && v <= kMaxWindowEdge;
  if (!ok(w) || !ok(h)) {
    throw ArgumentError.value(
      define,
      'DITMESH_SHOT_WINDOW',
      'expected WxH with both edges in (0, ${kMaxWindowEdge.toInt()}]',
    );
  }
  return Size(w!, h!);
}

/// The `DITMESH_SHOT_PIXEL_RATIO` define, or null when it is not set.
double? parsePixelRatio(String define) {
  if (define.isEmpty) return null;
  final v = double.tryParse(define);
  if (v == null || !v.isFinite || v < kMinPixelRatio || v > kMaxPixelRatio) {
    throw ArgumentError.value(
      define,
      'DITMESH_SHOT_PIXEL_RATIO',
      'expected a number in [$kMinPixelRatio, $kMaxPixelRatio]',
    );
  }
  return v;
}

ThemeMode parseShotTheme(String define) {
  if (!kShotThemes.contains(define)) {
    throw ArgumentError.value(
      define,
      'DITMESH_SHOT_THEME',
      'expected one of ${kShotThemes.join(', ')}',
    );
  }
  return switch (define) {
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => ThemeMode.light,
  };
}

/// Lets real asynchronous work (file I/O, plugin channels) and animations
/// finish. `pumpAndSettle` alone throws on an endless animation (a blinking
/// caret, a spinner), so its timeout -- and only its timeout -- is caught
/// and treated as "settled enough"; every other error propagates. Callers
/// assert the scene's content afterwards, so a timeout never hides a page
/// that failed to appear. The fixed pumps in front give plain futures a
/// chance to run.
Future<void> settle(
  WidgetTester tester, {
  Duration extra = Duration.zero,
}) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
  } on FlutterError catch (e) {
    // Something animates forever; the frame is still fine to capture.
    if (!e.message.startsWith('pumpAndSettle timed out')) rethrow;
  }
  if (extra > Duration.zero) {
    await Future<void>.delayed(extra);
    await tester.pump();
  }
}

/// Owns the capture boundary and the report list for one run.
class ShotHarness {
  ShotHarness(this.binding);

  final IntegrationTestWidgetsFlutterBinding binding;
  final GlobalKey boundaryKey = GlobalKey(debugLabel: 'shot-boundary');
  final String platform = shotPlatform();

  /// Report names captured so far (`<platform>/<locale>/<scene>`).
  final List<String> captured = <String>[];

  Widget wrap(Widget child) => RepaintBoundary(key: boundaryKey, child: child);

  /// Desktop: size and centre the real window so every capture has the same
  /// logical size (the Flutter view, i.e. the client area) regardless of
  /// what a previous run persisted. `window_manager` sizes the outer frame,
  /// so after a first attempt the title bar and borders are measured and
  /// added back. macOS clamps a window to the visible frame (menu bar,
  /// Dock), so there a smaller achieved size is accepted and logged;
  /// anything else that misses the requested size fails the run.
  Future<void> prepareWindow(WidgetTester tester) async {
    if (!isDesktopHost) return;
    final size = desktopWindowSize();
    await windowManager.ensureInitialized();
    await windowManager.setSize(size);
    await windowManager.center();
    await windowManager.show();
    if (await _viewReaches(tester, size)) return;
    final outer = await windowManager.getSize();
    final client = _viewSize(tester);
    await windowManager.setSize(
      Size(
        size.width + outer.width - client.width,
        size.height + outer.height - client.height,
      ),
    );
    await windowManager.center();
    if (await _viewReaches(tester, size)) return;
    final got = _viewSize(tester);
    final clamped =
        Platform.isMacOS &&
        got.width <= size.width + 2 &&
        got.height <= size.height + 2;
    if (!clamped) {
      throw StateError(
        'window is ${got.width}x${got.height}, wanted '
        '${size.width}x${size.height}',
      );
    }
    debugPrint(
      '[shot] window clamped to ${got.width}x${got.height}, '
      'wanted ${size.width}x${size.height}',
    );
  }

  static Size _viewSize(WidgetTester tester) =>
      tester.view.physicalSize / tester.view.devicePixelRatio;

  /// Pumps for up to 2 s until the Flutter view is [size] (within 2 px).
  static Future<bool> _viewReaches(WidgetTester tester, Size size) async {
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      final got = _viewSize(tester);
      if ((got.width - size.width).abs() < 2 &&
          (got.height - size.height).abs() < 2) {
        return true;
      }
    }
    return false;
  }

  /// Pins Modern Calm and brightness for consistent product screenshots.
  Future<void> applyTheme(WidgetTester tester) async {
    final mode = parseShotTheme(_themeDefine);
    final settings = tester
        .element(find.byType(MaterialApp))
        .read<AppSettings>();
    await settings.applyAppearance(style: UiStyle.modern, themeMode: mode);
    await settle(tester);
  }

  double _pixelRatio(WidgetTester tester) {
    final forced = parsePixelRatio(_pixelRatioDefine);
    if (forced != null) return forced;
    if (isDesktopHost) return 1.0;
    // iOS frames go to App Store Connect, which only takes the device's
    // native pixel size (6.9" iPhone @3x = 1320x2868, 13" iPad @2x).
    if (Platform.isIOS) return tester.view.devicePixelRatio;
    return math.min(tester.view.devicePixelRatio, 2.0);
  }

  /// Captures the current frame as `<platform>/<locale>/<scene>`.
  ///
  /// [until], when given, must hold on the frame that is captured: frames
  /// are pumped (for up to 10 s) until it does, so a scene with live
  /// playback can wait for a still moment instead of catching, say, a
  /// screen flash.
  Future<void> capture(
    WidgetTester tester,
    String locale,
    String scene, {
    bool Function()? until,
  }) async {
    await settle(tester);
    if (until != null) {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (true) {
        await tester.pump(const Duration(milliseconds: 16));
        if (until()) break;
        if (DateTime.now().isAfter(deadline)) {
          throw StateError('$scene: capture condition never held');
        }
      }
    }
    final RenderObject? ro = boundaryKey.currentContext?.findRenderObject();
    if (ro is! RenderRepaintBoundary) {
      throw StateError('screenshot boundary is not mounted');
    }
    final ui.Image image = await ro.toImage(pixelRatio: _pixelRatio(tester));
    final int width = image.width;
    final int height = image.height;
    final Uint8List bytes;
    if (Platform.isIOS) {
      // App Store Connect refuses screenshots with an alpha channel: encode
      // RGB (the app paints opaque frames, so dropping alpha loses nothing).
      final ByteData? raw = await image.toByteData();
      image.dispose();
      if (raw == null) throw StateError('pixel read failed for $scene');
      bytes = img.encodePng(
        img.Image.fromBytes(
          width: width,
          height: height,
          bytes: raw.buffer,
          bytesOffset: raw.offsetInBytes,
          numChannels: 4,
        ).convert(numChannels: 3),
      );
    } else {
      final ByteData? data = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      image.dispose();
      if (data == null) throw StateError('PNG encoding failed for $scene');
      bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }
    final name = '$platform/$locale/$scene';
    final Map<String, dynamic> report = binding.reportData ??=
        <String, dynamic>{};
    final list = (report[kShotReportKey] ??= <Object?>[]) as List<Object?>;
    list.add(<String, Object?>{
      'name': name,
      'width': width,
      'height': height,
      'png': base64Encode(bytes),
    });
    captured.add(name);
    debugPrint('[shot] $name ${width}x$height (${bytes.length} bytes)');
  }
}
