import 'package:ditmesh/i18n/system_date_time.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final language in ['de', 'zh']) {
    testWidgets(
      'Android 12-hour setting overrides $language convention',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: MediaQuery(
              data: const MediaQueryData(alwaysUse24HourFormat: false),
              child: Builder(
                builder: (context) => Text(
                  formatSystemDateTime(context, DateTime(2026, 10, 22, 15, 4)),
                ),
              ),
            ),
          ),
        );
        final text = tester.widget<Text>(find.byType(Text)).data!;
        expect(text, contains('3:04'));
        expect(text, isNot(contains('15:04')));
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }
  for (final use24 in [false, true]) {
    testWidgets('date-time follows English system 24-hour=$use24', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(alwaysUse24HourFormat: use24),
            child: Builder(
              builder: (context) => Text(
                formatSystemDateTime(context, DateTime(2026, 10, 22, 15, 4)),
              ),
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(find.byType(Text)).data!;
      expect(text, contains('10/22/2026'));
      expect(text, contains(use24 ? '15:04' : '3:04'));
      expect(text.contains('PM'), !use24);
    });
  }
}
