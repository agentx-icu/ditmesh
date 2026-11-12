import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/appearance/style_preview.dart';
import 'package:ditmesh/ui/appearance/ui_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in [const Locale('en'), const Locale('zh')]) {
    for (final style in UiStyle.values) {
      for (final brightness in Brightness.values) {
        for (final miniature in [false, true]) {
          testWidgets(
            'chat preview $locale/$style/$brightness/miniature=$miniature',
            (tester) async {
              await tester.pumpWidget(
                MaterialApp(
                  locale: locale,
                  localizationsDelegates: S.localizationsDelegates,
                  supportedLocales: S.supportedLocales,
                  home: Scaffold(
                    body: SizedBox(
                      width: miniature ? 180 : 296,
                      child: StylePreview(
                        style: style,
                        brightness: brightness,
                        miniature: miniature,
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final strings = lookupS(locale);
              expect(find.text(strings.navChat), findsOneWidget);
              expect(find.text(strings.chatSend), findsOneWidget);
              expect(find.text('CQ CQ'), findsOneWidget);
              expect(find.text('DE DITMESH'), findsOneWidget);
              expect(find.text(strings.learnLessonOf(4, 42)), findsNothing);
              expect(find.text(strings.learnContinueLesson), findsNothing);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
  for (final locale in S.supportedLocales) {
    testWidgets('narrow preview supports large text in $locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: const Scaffold(
            body: SizedBox(
              width: 118,
              child: StylePreview(
                style: UiStyle.cartoon,
                brightness: Brightness.dark,
                miniature: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(lookupS(locale).navChat), findsOneWidget);
      expect(find.text(lookupS(locale).chatSend), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
