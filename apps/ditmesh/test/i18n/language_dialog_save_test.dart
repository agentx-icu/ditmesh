import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/i18n/language_settings_tile.dart';
import 'package:ditmesh/i18n/locale_controller.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:provider/provider.dart';

/// A store whose writes can fail or be held open by the test.
final class _ScriptedStore implements KeyValueStore {
  _ScriptedStore([Map<String, String>? initial])
    : delegate = InMemoryKeyValueStore(initial);

  final InMemoryKeyValueStore delegate;
  int failuresRemaining = 0;
  int writes = 0;
  Completer<void>? gate;

  Future<void> _write(Future<void> Function() apply) async {
    writes++;
    final pending = gate;
    if (pending != null) await pending.future;
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw const FileSystemException('preferences disk unavailable');
    }
    await apply();
  }

  @override
  String? getString(String key) => delegate.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _write(() => delegate.setString(key, value));

  @override
  Future<void> remove(String key) => _write(() => delegate.remove(key));
}

const _saveFailed = "Couldn't save the language setting. Try again.";
const _saveFailedZh = '无法保存语言设置，请重试。';

Future<LocaleController> _pump(WidgetTester tester, KeyValueStore store) async {
  final controller = LocaleController(store);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider<LocaleController>.value(
      value: controller,
      child: Builder(
        builder: (context) => MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          locale: context.watch<LocaleController>().locale,
          home: const Scaffold(body: LanguageSettingsTile()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

/// Scrolls [label]'s row into view first: with every shipped language the
/// option list is taller than the test surface.
Future<void> _tapOption(WidgetTester tester, String label) async {
  final option = find.text(label);
  await tester.ensureVisible(option);
  await tester.tap(option);
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.byType(LanguageSettingsTile));
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
}

void main() {
  testWidgets('a failed save keeps the dialog open with an inline error, '
      'keeps the old choice, and a retry succeeds', (tester) async {
    final store = _ScriptedStore()..failuresRemaining = 1;
    final controller = await _pump(tester, store);
    await _openDialog(tester);

    await _tapOption(tester, '简体中文');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'no unhandled error');
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(_saveFailed), findsOneWidget);
    expect(controller.locale, isNull, reason: 'rolled back');
    expect(store.getString(LocaleController.storageKey), isNull);

    await _tapOption(tester, '简体中文');
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(controller.locale, const Locale('zh'));
    expect(store.getString(LocaleController.storageKey), 'zh');
    expect(find.text('语言'), findsOneWidget, reason: 'page still there');
  });

  testWidgets('a failed return to the system default shows the error', (
    tester,
  ) async {
    final store = _ScriptedStore({LocaleController.storageKey: 'zh'})
      ..failuresRemaining = 1;
    final controller = await _pump(tester, store);
    await _openDialog(tester);

    await _tapOption(tester, '跟随系统');
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(_saveFailedZh), findsOneWidget);
    expect(controller.locale, const Locale('zh'));
    expect(store.getString(LocaleController.storageKey), 'zh');

    await _tapOption(tester, '跟随系统');
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(controller.locale, isNull);
    expect(store.getString(LocaleController.storageKey), isNull);
  });

  testWidgets('selections while a save is pending are ignored', (tester) async {
    final store = _ScriptedStore()..gate = Completer<void>();
    final controller = await _pump(tester, store);
    await _openDialog(tester);

    await _tapOption(tester, '简体中文');
    await tester.pump();
    await _tapOption(tester, 'English');
    await _tapOption(tester, '跟随系统');
    await tester.pump();
    expect(store.writes, 1);

    store.gate!.complete();
    await tester.pumpAndSettle();
    expect(store.writes, 1);
    expect(controller.locale, const Locale('zh'));
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('closing the dialog during a pending save does not pop the '
      'page below', (tester) async {
    final store = _ScriptedStore()..gate = Completer<void>();
    final controller = await _pump(tester, store);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await _openDialog(tester);

    await _tapOption(tester, '简体中文');
    await tester.pump();
    // Same as Close / Back / a barrier tap: the dialog route is popped.
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    store.gate!.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(controller.locale, const Locale('zh'));
    expect(find.byType(LanguageSettingsTile), findsOneWidget);
    expect(navigator.canPop(), isFalse, reason: 'home route untouched');
  });

  testWidgets('a save failing after the dialog closed stays silent', (
    tester,
  ) async {
    final store = _ScriptedStore()
      ..gate = Completer<void>()
      ..failuresRemaining = 1;
    final controller = await _pump(tester, store);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await _openDialog(tester);

    await _tapOption(tester, '简体中文');
    await tester.pump();
    navigator.pop();
    await tester.pumpAndSettle();

    store.gate!.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(controller.locale, isNull, reason: 'rolled back');
    expect(find.byType(LanguageSettingsTile), findsOneWidget);
  });
}
