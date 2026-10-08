// Opt-in visual inspection of real Flutter widgets. Example (from apps/ditmesh):
// flutter test test/appearance/style_render_test.dart --no-pub \
//   --dart-define=DITMESH_RENDER_STYLES=true \
//   --dart-define=DITMESH_STYLE_RENDER_DIR=/absolute/path/to/previews \
//   --dart-define=DITMESH_PREVIEW_FONT=/absolute/path/to/PingFang.ttc
// Widget tests use Ahem by default; opt-in captures load a real local font.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_settings.dart';
import 'package:ditmesh/di/fake_backend_factory.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/i18n/locale_controller.dart';
import 'package:ditmesh/main.dart';
import 'package:ditmesh/ui/appearance/appearance_page.dart';
import 'package:ditmesh/ui/appearance/ui_style.dart';

import '../../integration_test/support/seed_data.dart';
import '../account/test_app.dart' show settle;

const _render = bool.fromEnvironment('DITMESH_RENDER_STYLES');
const _output = String.fromEnvironment('DITMESH_STYLE_RENDER_DIR');
const _font = String.fromEnvironment('DITMESH_PREVIEW_FONT');

void main() {
  testWidgets('export real desktop and phone style previews', (tester) async {
    expect(_output, isNotEmpty);
    expect(_font, isNotEmpty);
    final bytes = await tester.runAsync(() => File(_font).readAsBytes());
    for (final family in ['Roboto', 'Ahem']) {
      await (FontLoader(
        family,
      )..addFont(Future.value(ByteData.sublistView(bytes!)))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final mono = File('/System/Library/Fonts/SFNSMono.ttf');
    if (mono.existsSync()) {
      final data = await tester.runAsync(mono.readAsBytes);
      await (FontLoader(
        'monospace',
      )..addFont(Future.value(ByteData.sublistView(data!)))).load();
    }
    final serif = File('/System/Library/Fonts/Supplemental/Songti.ttc');
    if (serif.existsSync()) {
      final data = await tester.runAsync(serif.readAsBytes);
      await (FontLoader(
        'serif',
      )..addFont(Future.value(ByteData.sublistView(data!)))).load();
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    Future<void> capture(GlobalKey boundary, String name) async {
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 1);
        try {
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('$_output/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png!.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      });
    }

    final originalShadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      for (final style in UiStyle.values) {
        for (final phone in [false, true]) {
          final device = phone ? 'phone' : 'desktop';
          final boundary = GlobalKey();
          tester.view.physicalSize = phone
              ? const Size(430, 932)
              : const Size(1280, 800);
          final dir = await tester.runAsync(
            () => Directory.systemTemp.createTemp('ditmesh_style_render_'),
          );
          final seed = await tester.runAsync(
            () => buildSeed(seedCopyFor('zh'), dataDir: dir!.path),
          );
          final mode = style == UiStyle.radio
              ? ThemeMode.dark
              : ThemeMode.light;
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: DitmeshApp(
                key: ValueKey('${style.name}-$device'),
                backend: FakeBackendFactory(
                  identityService: seed!.identity,
                  chatService: (_) => seed.chat,
                ),
                localeStore: InMemoryKeyValueStore({
                  AppSettings.termsKey: '$kTermsVersion',
                  LocaleController.storageKey: 'zh',
                  AppSettings.storageKey: jsonEncode({
                    'style': style.name,
                    'mode': mode.name,
                  }),
                }),
              ),
            ),
          );
          await settle(tester);
          await capture(boundary, '${style.name}-$device');
          if (style == UiStyle.modern) {
            AppearancePage.open(
              tester.element(
                find.byType(NavigationBar).evaluate().isEmpty
                    ? find.byType(NavigationRail)
                    : find.byType(NavigationBar),
              ),
            );
            await settle(tester);
            await capture(boundary, 'appearance-$device');
          }
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 30));
            await dir!.delete(recursive: true);
          });
        }
      }
    } finally {
      debugDisableShadows = originalShadows;
    }
  }, skip: !_render);
}
