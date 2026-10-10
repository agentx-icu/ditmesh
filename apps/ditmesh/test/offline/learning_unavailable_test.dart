import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_features.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:provider/provider.dart';

import '../learn/helpers/unavailable_training.dart';

final S s = lookupS(const Locale('en'));

/// A learning profile that fails to open: chat builds point at the missing
/// identity, the offline build reports a storage problem and retries.
void main() {
  late UnavailableIdentityService identity;
  Future<void> pump(WidgetTester tester, {required bool chat}) async {
    identity = UnavailableIdentityService(loading: false);
    await tester.pumpWidget(
      Provider<AppFeatures>.value(
        value: AppFeatures(chat: chat),
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          locale: const Locale('en'),
          home: unavailableTrainingSettings(identity),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offline: storage wording and a retry that loads again', (
    tester,
  ) async {
    await pump(tester, chat: false);
    expect(find.text(s.learnStorageUnavailable), findsOneWidget);
    expect(find.text(s.learnIdentityRequired), findsNothing);
    final before = identity.attempts;
    await tester.tap(find.byKey(const ValueKey('training-settings-retry')));
    await tester.pumpAndSettle();
    expect(identity.attempts, before + 1, reason: 'retry loads again');
    expect(find.text(s.learnStorageUnavailable), findsOneWidget);
  });

  testWidgets('chat build: asks for an identity, no retry', (tester) async {
    await pump(tester, chat: true);
    expect(find.text(s.learnIdentityRequired), findsOneWidget);
    expect(find.byKey(const ValueKey('training-settings-retry')), findsNothing);
  });
}
