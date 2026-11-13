import 'dart:async';

import 'package:ditmesh/di/backend_factory.dart';
import 'package:ditmesh/di/fake_backend_factory.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/main.dart';
import 'package:ditmesh/startup/android_privacy_startup.dart';
import 'package:ditmesh/startup/native_backend_startup.dart';
import 'package:ditmesh/startup/startup_screens.dart';
import 'package:ditmesh/ui/account/account_routes.dart';
import 'package:ditmesh/ui/account/welcome_page.dart';
import 'package:ditmesh/ui/learn/settings/training_settings_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _strings = lookupS(const Locale('en'));

class _ControlledStore implements KeyValueStore {
  final backing = InMemoryKeyValueStore();
  final firstWrite = Completer<void>();
  int writes = 0;

  @override
  String? getString(String key) => backing.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    if (++writes == 1) await firstWrite.future;
    await backing.setString(key, value);
  }

  @override
  Future<void> remove(String key) => backing.remove(key);
}

void main() {
  test('privacy consent is required only for release Android', () {
    expect(
      requiresPrivacyConsent(
        releaseMode: true,
        platform: TargetPlatform.android,
      ),
      isTrue,
    );
    expect(
      requiresPrivacyConsent(
        releaseMode: false,
        platform: TargetPlatform.android,
      ),
      isFalse,
    );
    expect(
      requiresPrivacyConsent(releaseMode: true, platform: TargetPlatform.iOS),
      isFalse,
    );
    expect(
      requiresPrivacyConsent(releaseMode: true, platform: TargetPlatform.macOS),
      isFalse,
    );
  });

  testWidgets(
    'initial named routes and stale privacy consent cannot start the backend',
    (tester) async {
      final dispatcher = tester.binding.platformDispatcher;
      dispatcher.defaultRouteNameTestValue = kTrainingSettingsRoute;
      addTearDown(dispatcher.clearDefaultRouteNameTestValue);
      final store = InMemoryKeyValueStore({'privacy.consent': '1'});
      var starts = 0;
      Widget startup() => AndroidPrivacyStartup(
        openStore: () async => store,
        ready: (_) {
          starts++;
          return const SizedBox.shrink();
        },
      );
      await tester.pumpWidget(startup());
      await tester.pumpAndSettle();
      expect(find.text(_strings.privacyConsentTitle), findsOneWidget);
      expect(starts, 0);

      await tester.tap(find.text(_strings.privacyConsentAccept));
      await tester.pumpAndSettle();
      expect(find.text(_strings.privacyConsentTitle), findsNothing);
      expect(store.getString('privacy.consent'), '2');
      expect(starts, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(startup());
      await tester.pumpAndSettle();
      expect(find.text(_strings.privacyConsentTitle), findsNothing);
      expect(starts, 2);
    },
  );

  testWidgets('the cold-start route stays at the root after consent', (
    tester,
  ) async {
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.defaultRouteNameTestValue = kTrainingSettingsRoute;
    addTearDown(dispatcher.clearDefaultRouteNameTestValue);
    final store = InMemoryKeyValueStore();
    final backend = Completer<BackendFactory>();
    var prepareCalls = 0;
    await tester.pumpWidget(
      AndroidPrivacyStartup(
        openStore: () async => store,
        ready: (store) => NativeBackendStartup(
          prepare: () {
            prepareCalls++;
            return backend.future;
          },
          store: store,
          ready: (backend) => DitmeshApp(backend: backend, localeStore: store),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(prepareCalls, 0);
    await tester.tap(find.text(_strings.privacyConsentAccept));
    await tester.pump();
    await tester.pump();
    expect(find.byType(StartupSplash), findsOneWidget);
    expect(prepareCalls, 1);

    backend.complete(FakeBackendFactory());
    await tester.pumpAndSettle();
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.byType(TrainingSettingsEntry), findsNothing);
  });

  testWidgets('backend waits for the write and a failed save can be retried', (
    tester,
  ) async {
    final store = _ControlledStore();
    var starts = 0;
    await tester.pumpWidget(
      AndroidPrivacyStartup(
        openStore: () async => store,
        ready: (_) {
          starts++;
          return const SizedBox.shrink();
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(_strings.privacyConsentAccept));
    await tester.pump();
    final saving = find.widgetWithText(
      FilledButton,
      _strings.privacyConsentSaving,
    );
    expect(tester.widget<FilledButton>(saving).onPressed, isNull);
    expect(store.writes, 1);
    expect(starts, 0);

    store.firstWrite.completeError(StateError('private failure'));
    await tester.pumpAndSettle();
    expect(find.text(_strings.privacyConsentSaveFailed), findsOneWidget);
    expect(find.textContaining('private failure'), findsNothing);
    expect(store.getString('privacy.consent'), isNull);
    expect(starts, 0);

    await tester.tap(find.text(_strings.privacyConsentAccept));
    await tester.pumpAndSettle();
    expect(store.writes, 2);
    expect(store.getString('privacy.consent'), '2');
    expect(starts, 1);
  });

  testWidgets('a store open failure can retry without entering the app', (
    tester,
  ) async {
    final store = InMemoryKeyValueStore();
    var attempts = 0;
    await tester.pumpWidget(
      AndroidPrivacyStartup(
        openStore: () async {
          if (++attempts == 1) throw StateError('private path');
          return store;
        },
        ready: (_) => throw StateError('backend started before consent'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(_strings.privacyConsentSaveFailed), findsOneWidget);
    expect(find.textContaining('private path'), findsNothing);
    await tester.tap(find.text(_strings.actionRetry));
    await tester.pumpAndSettle();
    expect(find.text(_strings.privacyConsentAccept), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('declining requests activity exit and does not record consent', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final store = InMemoryKeyValueStore();
    await tester.pumpWidget(
      AndroidPrivacyStartup(
        openStore: () async => store,
        ready: (_) => throw StateError('backend started after decline'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(_strings.privacyConsentDecline));
    await tester.pumpAndSettle();
    expect(calls.map((call) => call.method), contains('SystemNavigator.pop'));
    expect(store.getString('privacy.consent'), isNull);
  });
}
