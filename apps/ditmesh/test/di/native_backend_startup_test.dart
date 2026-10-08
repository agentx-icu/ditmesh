import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/backend_factory.dart';
import 'package:ditmesh/di/fake_backend_factory.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/i18n/locale_controller.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/startup/native_backend_startup.dart';
import 'package:ditmesh/startup/startup_screens.dart';

void main() {
  testWidgets(
    'a retry waits on native preparation without a second retry button',
    (tester) async {
      final retry = Completer<BackendFactory>();
      var attempts = 0;
      await tester.pumpWidget(
        NativeBackendStartup(
          prepare: () {
            attempts++;
            if (attempts == 1) {
              return Future.error(StateError('native load failed'));
            }
            return retry.future;
          },
          store: InMemoryKeyValueStore(),
          ready: (_) => const SizedBox.shrink(),
        ),
      );
      await tester.pumpAndSettle();
      final s = lookupS(const Locale('en'));
      await tester.tap(find.text(s.actionRetry));
      await tester.pump();
      expect(find.byType(StartupSplash), findsOneWidget);
      expect(find.byType(StartupErrorPage), findsNothing);
      retry.complete(FakeBackendFactory());
      await tester.pumpAndSettle();
      expect(attempts, 2);
    },
  );

  testWidgets('native failure stays visible and retry loads the real app', (
    tester,
  ) async {
    var attempts = 0;
    final native = FakeBackendFactory();
    Future<BackendFactory> prepare() async {
      attempts++;
      if (attempts == 1) throw StateError('libtim2tox_ffi missing');
      return native;
    }

    await tester.pumpWidget(
      NativeBackendStartup(
        prepare: prepare,
        store: InMemoryKeyValueStore(),
        ready: (backend) =>
            MaterialApp(home: Scaffold(body: Text('ready ${backend.label}'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(StartupErrorPage), findsOneWidget);
    expect(find.textContaining('libtim2tox_ffi missing'), findsOneWidget);
    expect(find.textContaining('ready '), findsNothing);

    final s = lookupS(const Locale('en'));
    await tester.tap(find.text(s.actionRetry));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(StartupErrorPage), findsNothing);
    expect(find.text('ready ${native.label}'), findsOneWidget);
  });

  testWidgets('startup failure follows the persisted language', (tester) async {
    await tester.pumpWidget(
      NativeBackendStartup(
        prepare: () async => throw StateError('native initialization failed'),
        store: InMemoryKeyValueStore({LocaleController.storageKey: 'zh'}),
        ready: (_) => const SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(StartupErrorPage));
    expect(Localizations.localeOf(context).languageCode, 'zh');
  });
}
