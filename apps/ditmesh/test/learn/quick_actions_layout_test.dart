import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/learn/learn_home_widgets.dart';

void main() {
  for (final language in ['de', 'ru']) {
    for (final due in [0, 21]) {
      testWidgets(
        '$language review status wraps at 320px with large text ($due)',
        (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 1.8;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          var reviewed = false;
          final locale = Locale(language);
          final s = lookupS(locale);
          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              supportedLocales: S.supportedLocales,
              localizationsDelegates: S.localizationsDelegates,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: QuickActions(
                      dueCount: due,
                      onContinueLesson: () {},
                      onReceivePractice: () {},
                      onSendPractice: () {},
                      onReview: () => reviewed = true,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final status = find.text(s.learnReviewDueCount(due));
          expect(status, findsOneWidget);
          await tester.ensureVisible(status);
          await tester.pumpAndSettle();
          final bounds = tester.getRect(status);
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(320));
          await tester.tap(status);
          expect(reviewed, isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
