// `flutter drive` host side for integration_test/*.dart.
//
// Writes every frame the app captured (see
// integration_test/support/shot_harness.dart) to
// `$DITMESH_SHOT_OUT/<platform>/<locale>/<scene>.png` (default:
// build/screenshots). Everything else is the stock integration driver.

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';
import 'package:path/path.dart' as p;

const String _reportKey = 'ditmeshScreenshots';

Future<void> main() => integrationDriver(
  responseDataCallback: _writeScreenshots,
  writeResponseOnFailure: true,
);

Future<void> _writeScreenshots(Map<String, dynamic>? data) async {
  final frames = data?[_reportKey];
  if (frames is! List || frames.isEmpty) {
    print('[shot] no screenshots in the report');
    return;
  }
  final root = Platform.environment['DITMESH_SHOT_OUT'] ?? 'build/screenshots';
  var written = 0;
  for (final frame in frames) {
    if (frame is! Map) continue;
    final name = frame['name'] as String?;
    final png = frame['png'] as String?;
    if (name == null || png == null) continue;
    final file = File(p.join(root, '$name.png'));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(base64Decode(png), flush: true);
    written++;
    print('[shot] wrote ${file.path} (${frame['width']}x${frame['height']})');
  }
  print('[shot] $written frame(s) under $root');
}
