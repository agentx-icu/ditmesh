import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/i18n/l10n_extension.dart';
import 'package:ditmesh/i18n/language_settings_tile.dart';
import 'package:ditmesh/i18n/locale_controller.dart';
import 'package:ditmesh/i18n/locale_resolution.dart';
import 'package:ditmesh/l10n/generated/s.dart' show lookupS;
import 'package:provider/provider.dart';

/// Pumps the tile inside a MaterialApp wired exactly the way main.dart is
/// expected to be: delegates + supportedLocales from `S`, `locale` from the
/// controller.
Future<LocaleController> pumpTile(
  WidgetTester tester, {
  InMemoryKeyValueStore? store,
}) async {
  final controller = LocaleController(store ?? InMemoryKeyValueStore());
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider<LocaleController>.value(
      value: controller,
      child: Builder(
        builder: (context) => MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          locale: context.watch<LocaleController>().locale,
          localeListResolutionCallback: LocaleController.resolve,
          home: const Scaffold(body: LanguageSettingsTile()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  const newLanguages = {
    'zh_Hant': '繁體中文',
    'ja': '日本語',
    'ko': '한국어',
    'de': 'Deutsch',
    'fr': 'Français',
    'es': 'Español',
    'pt': 'Português',
    'ru': 'Русский',
  };

  for (final entry in newLanguages.entries) {
    testWidgets('selects ${entry.key} from a scrolling phone dialog', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = InMemoryKeyValueStore();
      final controller = await pumpTile(tester, store: store);

      await tester.tap(find.byType(LanguageSettingsTile));
      await tester.pumpAndSettle();
      final option = find.text(entry.value);
      expect(option, findsOneWidget);
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      await tester.tap(option);
      await tester.pumpAndSettle();

      final locale = parseLocaleTag(entry.key)!;
      expect(controller.locale, locale);
      expect(store.getString(LocaleController.storageKey), entry.key);
      expect(find.text(lookupS(locale).languageTitle), findsOneWidget);
      expect(find.text(entry.value), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(LanguageSettingsTile));
      await tester.pumpAndSettle();
      final system = find.text(lookupS(locale).languageSystemDefault);
      await tester.ensureVisible(system);
      await tester.pumpAndSettle();
      await tester.tap(system);
      await tester.pumpAndSettle();
      expect(controller.locale, isNull);
      expect(find.text('Language'), findsOneWidget);
    });
  }

  testWidgets('shows the system-default choice in English by default', (
    tester,
  ) async {
    await pumpTile(tester);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
  });

  testWidgets('choosing 简体中文 switches the app locale and persists it', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    final controller = await pumpTile(tester, store: store);

    await tester.tap(find.byType(LanguageSettingsTile));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.ensureVisible(find.text('简体中文'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('简体中文'));
    await tester.pumpAndSettle();

    expect(controller.locale, const Locale('zh'));
    expect(store.getString(LocaleController.storageKey), 'zh');
    expect(find.byType(AlertDialog), findsNothing, reason: 'dialog closed');
    // The tile itself re-rendered in Chinese.
    expect(find.text('语言'), findsOneWidget);
    expect(find.text('简体中文'), findsOneWidget);
  });

  testWidgets('restores a persisted choice and can return to system', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore({LocaleController.storageKey: 'zh_CN'});
    final controller = await pumpTile(tester, store: store);
    expect(find.text('语言'), findsOneWidget);

    await tester.tap(find.byType(LanguageSettingsTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('跟随系统'));
    await tester.pumpAndSettle();

    expect(controller.locale, isNull);
    expect(store.getString(LocaleController.storageKey), isNull);
    // Test binding's system locale is en_US, so the tile reads English again.
    expect(find.text('Language'), findsOneWidget);
  });

  testWidgets('context.s resolves the same instance as S.of', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (context) {
            captured = context;
            return Text(context.s.appName);
          },
        ),
      ),
    );
    expect(find.text('DitMesh'), findsOneWidget);
    expect(identical(captured.s, S.of(captured)), isTrue);
  });
}
