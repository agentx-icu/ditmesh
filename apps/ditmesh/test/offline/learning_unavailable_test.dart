import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_features.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/learn/learn_scope.dart';
import 'package:provider/provider.dart';

final S s = lookupS(const Locale('en'));

/// A learning profile that fails to open: chat builds point at the missing
/// identity, the offline build reports a storage problem and retries.
void main() {
  var attempts = 0;
  Future<void> pump(WidgetTester tester, {required bool chat}) async {
    attempts = 0;
    await tester.pumpWidget(
      Provider<AppFeatures>.value(
        value: AppFeatures(chat: chat),
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          locale: const Locale('en'),
          home: LearnScope(
            controllerFactory: (_) async {
              attempts++;
              throw StateError('disk unavailable');
            },
            builder: (context, controller, playback) => const SizedBox(),
          ),
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
    final before = attempts;
    await tester.tap(find.byKey(const ValueKey('learn-retry')));
    await tester.pumpAndSettle();
    expect(attempts, before + 1, reason: 'retry loads again');
    expect(find.text(s.learnStorageUnavailable), findsOneWidget);
  });

  testWidgets('chat build: asks for an identity, no retry', (tester) async {
    await pump(tester, chat: true);
    expect(find.text(s.learnIdentityRequired), findsOneWidget);
    expect(find.byKey(const ValueKey('learn-retry')), findsNothing);
  });
}
