import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_settings.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/appearance/appearance_page.dart';
import 'package:ditmesh/ui/appearance/style_preview.dart';
import 'package:ditmesh/ui/appearance/ui_style.dart';
import 'package:ditmesh/ui/theme.dart';
import 'package:provider/provider.dart';

import 'app_settings_test.dart' show FailingStore;

Future<void> pumpAppearance(
  WidgetTester tester,
  AppSettings settings, {
  Size size = const Size(430, 932),
  bool startOnHome = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: settings,
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) => MaterialApp(
          theme: DitmeshTheme.light(style: settings.style),
          darkTheme: DitmeshTheme.dark(style: settings.style),
          themeMode: settings.themeMode,
          themeAnimationDuration: Duration.zero,
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: startOnHome ? const _DraftHome() : const AppearancePage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _chooseStyle(WidgetTester tester, UiStyle style) async {
  final choice = find.byKey(ValueKey('style-${style.name}'));
  await tester.ensureVisible(choice);
  await tester.pumpAndSettle();
  await tester.tap(choice);
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(900, 800),
  ]) {
    for (final scale in [1.0, 1.8]) {
      testWidgets(
        'complete preview is visible before choices at $size/$scale',
        (tester) async {
          final settings = AppSettings(backendLabel: 'test');
          addTearDown(settings.dispose);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await pumpAppearance(tester, settings, size: size);
          final preview = tester.getRect(
            find.byKey(const ValueKey('appearance-preview')),
          );
          final firstChoice = tester.getRect(
            find.byKey(const ValueKey('style-classic')),
          );
          final apply = tester.getRect(
            find.byKey(const ValueKey('appearance-apply')),
          );
          expect(preview.top, greaterThanOrEqualTo(56));
          expect(preview.bottom, lessThan(firstChoice.top));
          expect(preview.bottom, lessThanOrEqualTo(apply.top));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('preview and brightness are staged until Apply', (tester) async {
    final store = InMemoryKeyValueStore();
    final settings = AppSettings(backendLabel: 'test', store: store);
    addTearDown(settings.dispose);
    await pumpAppearance(tester, settings);
    await _chooseStyle(tester, UiStyle.radio);
    await tester.ensureVisible(find.byKey(const ValueKey('mode-dark')));
    await tester.tap(find.byKey(const ValueKey('mode-dark')));
    await tester.pumpAndSettle();
    final preview = tester.widget<StylePreview>(
      find.byKey(const ValueKey('appearance-preview')),
    );
    expect(preview.style, UiStyle.radio);
    expect(preview.brightness, Brightness.dark);
    expect(settings.style, UiStyle.modern);
    expect(settings.themeMode, ThemeMode.system);
    expect(store.getString(AppSettings.storageKey), isNull);
    await tester.tap(find.byKey(const ValueKey('appearance-apply')));
    await tester.pumpAndSettle();
    expect(settings.style, UiStyle.radio);
    expect(settings.themeMode, ThemeMode.dark);
    expect(find.byType(AppearancePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Restore defaults is staged and write failure is visible', (
    tester,
  ) async {
    final settings = AppSettings(backendLabel: 'test', store: FailingStore());
    addTearDown(settings.dispose);
    await pumpAppearance(tester, settings);
    await _chooseStyle(tester, UiStyle.cartoon);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore defaults'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<StylePreview>(
            find.byKey(const ValueKey('appearance-preview')),
          )
          .style,
      UiStyle.modern,
    );
    await _chooseStyle(tester, UiStyle.radio);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('appearance-apply')));
    await tester.pumpAndSettle();
    expect(settings.style, UiStyle.modern);
    expect(find.text('Could not save appearance. Try again.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restore stages Modern Calm then persists it on Apply', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    final settings = AppSettings(backendLabel: 'test', store: store);
    addTearDown(settings.dispose);
    await settings.applyAppearance(
      style: UiStyle.classic,
      themeMode: ThemeMode.dark,
    );
    await pumpAppearance(tester, settings);
    await tester.tap(find.text('Restore defaults'));
    await tester.pumpAndSettle();
    final preview = tester.widget<StylePreview>(
      find.byKey(const ValueKey('appearance-preview')),
    );
    expect(preview.style, UiStyle.modern);
    expect(settings.style, UiStyle.classic);
    expect(settings.themeMode, ThemeMode.dark);
    await tester.tap(find.byKey(const ValueKey('appearance-apply')));
    await tester.pumpAndSettle();
    final reopened = AppSettings(backendLabel: 'test', store: store);
    addTearDown(reopened.dispose);
    expect(reopened.style, UiStyle.modern);
    expect(reopened.themeMode, ThemeMode.system);
  });

  testWidgets(
    'discarding preview and applying later preserve underlying draft',
    (tester) async {
      final settings = AppSettings(backendLabel: 'test');
      addTearDown(settings.dispose);
      await pumpAppearance(tester, settings, startOnHome: true);
      await tester.enterText(find.byType(TextField), 'CQ CQ unfinished draft');
      await tester.tap(find.text('Open appearance'));
      await tester.pumpAndSettle();
      await _chooseStyle(tester, UiStyle.cartoon);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(settings.style, UiStyle.modern);
      expect(find.text('CQ CQ unfinished draft'), findsOneWidget);
      await tester.tap(find.text('Open appearance'));
      await tester.pumpAndSettle();
      await _chooseStyle(tester, UiStyle.paper);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('appearance-apply')));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(settings.style, UiStyle.paper);
      expect(find.text('CQ CQ unfinished draft'), findsOneWidget);
    },
  );

  for (final size in [const Size(320, 740), const Size(1280, 800)]) {
    testWidgets('chooser remains usable at $size with large text', (
      tester,
    ) async {
      final settings = AppSettings(backendLabel: 'test');
      addTearDown(settings.dispose);
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpAppearance(tester, settings, size: size);
      for (final style in UiStyle.values) {
        final card = find.byKey(ValueKey('style-${style.name}'));
        await tester.ensureVisible(card);
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(
        tester.getRect(find.byKey(const ValueKey('appearance-apply'))).bottom,
        lessThanOrEqualTo(size.height),
      );
    });
  }
}

class _DraftHome extends StatelessWidget {
  const _DraftHome();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        const TextField(),
        TextButton(
          onPressed: () => AppearancePage.open(context),
          child: const Text('Open appearance'),
        ),
      ],
    ),
  );
}
