import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/i18n/locale_controller.dart';
import 'package:ditmesh/i18n/strings_resolver.dart';

void main() {
  late LocaleController controller;

  // Created inside each test body (not setUp) so its futures live in the
  // test's fake-async zone; one made in setUp would never complete there.
  void makeController() {
    controller = LocaleController(InMemoryKeyValueStore());
    addTearDown(controller.dispose);
  }

  void changeOsLocales(WidgetTester tester, List<Locale> locales) {
    tester.platformDispatcher.localesTestValue = locales;
  }

  testWidgets('OS locale change notifies while following the system', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    makeController();
    final resolver = StringsResolver(controller);
    addTearDown(resolver.dispose);
    var calls = 0;
    resolver.addListener(() => calls++);

    changeOsLocales(tester, const [Locale('zh', 'CN')]);
    expect(calls, 1);
  });

  testWidgets('OS locale change is ignored while a language is forced', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    makeController();
    final resolver = StringsResolver(controller);
    addTearDown(resolver.dispose);
    await controller.setLocale(const Locale('en'));
    var calls = 0;
    resolver.addListener(() => calls++);

    changeOsLocales(tester, const [Locale('zh', 'CN')]);
    expect(calls, 0);

    await controller.setLocale(const Locale('zh'));
    expect(calls, 1, reason: 'setting changes always notify');
    expect(resolver.s.languageTitle, '语言');
  });

  testWidgets('does not take over PlatformDispatcher.onLocaleChanged', (
    tester,
  ) async {
    makeController();
    final before = tester.binding.platformDispatcher.onLocaleChanged;
    final resolver = StringsResolver(controller);
    expect(tester.binding.platformDispatcher.onLocaleChanged, before);
    resolver.dispose();
    expect(tester.binding.platformDispatcher.onLocaleChanged, before);
  });

  for (final disposeFirstCreated in [true, false]) {
    testWidgets(
      'two resolvers dispose independently (first created disposed first: '
      '$disposeFirstCreated)',
      (tester) async {
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        makeController();
    makeController();
        final a = StringsResolver(controller);
        final b = StringsResolver(controller);
        var aCalls = 0;
        var bCalls = 0;
        a.addListener(() => aCalls++);
        b.addListener(() => bCalls++);

        final (gone, kept) = disposeFirstCreated ? (a, b) : (b, a);
        gone.dispose();
        addTearDown(kept.dispose);

        changeOsLocales(tester, const [Locale('zh', 'CN')]);
        await controller.setLocale(const Locale('zh'));

        final goneCalls = disposeFirstCreated ? aCalls : bCalls;
        final keptCalls = disposeFirstCreated ? bCalls : aCalls;
        expect(goneCalls, 0);
        expect(keptCalls, 2, reason: 'one OS change + one setting change');
      },
    );
  }

  testWidgets('nothing is delivered after dispose', (tester) async {
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    makeController();
    final resolver = StringsResolver(controller);
    var calls = 0;
    resolver.addListener(() => calls++);
    resolver.dispose();

    changeOsLocales(tester, const [Locale('zh', 'CN')]);
    await controller.setLocale(const Locale('zh'));
    expect(calls, 0);
  });
}
