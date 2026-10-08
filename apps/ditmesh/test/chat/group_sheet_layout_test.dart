import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/groups/create_group_sheet.dart';
import 'package:ditmesh/ui/groups/join_group_sheet.dart';
import 'package:ditmesh/ui/theme.dart';

import 'test_support.dart';

Future<ChatHarness> _openSheet(
  WidgetTester tester, {
  required Size size,
  required Locale locale,
  required double scale,
  required bool create,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  final ChatHarness harness = ChatHarness();
  addTearDown(harness.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: DitmeshTheme.light(),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              if (create) {
                unawaited(
                  showCreateGroupSheet(context, service: harness.service),
                );
              } else {
                unawaited(
                  showJoinGroupSheet(context, service: harness.service),
                );
              }
            },
            child: const Text('Open sheet'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open sheet'));
  await tester.pumpAndSettle();
  return harness;
}

void main() {
  for (final Locale locale in <Locale>[
    const Locale('en'),
    const Locale('zh'),
  ]) {
    final S strings = lookupS(locale);
    for (final Size size in <Size>[
      const Size(320, 640),
      const Size(390, 844),
      const Size(900, 800),
    ]) {
      for (final double scale in <double>[1, 1.8]) {
        final String dimensions =
            '${size.width.toInt()} ${locale.languageCode} $scale';
        testWidgets(
          'create advanced form scrolls above keyboard: $dimensions',
          (tester) async {
            final ChatHarness harness = await _openSheet(
              tester,
              size: size,
              locale: locale,
              scale: scale,
              create: true,
            );
            await tester.enterText(find.byType(TextFormField), 'Net 40m');
            await tester.tap(find.text(strings.chatAdvanced));
            await tester.pumpAndSettle();
            final double keyboard = size.width == 320 ? 280 : 320;
            tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            final Finder submit = find.widgetWithText(
              FilledButton,
              strings.chatCreate,
            );
            await tester.ensureVisible(submit);
            await tester.pumpAndSettle();
            expect(submit.hitTestable(), findsOneWidget);
            expect(
              tester.getRect(submit).bottom,
              lessThanOrEqualTo(size.height - keyboard),
            );
            await tester.tap(submit);
            await tester.pumpAndSettle();
            expect(harness.service.groups.single.name, 'Net 40m');
            expect(find.byType(CreateGroupForm), findsNothing);
          },
        );

        testWidgets(
          'join validation form scrolls above keyboard: $dimensions',
          (tester) async {
            final ChatHarness harness = await _openSheet(
              tester,
              size: size,
              locale: locale,
              scale: scale,
              create: false,
            );
            final double keyboard = size.width == 320 ? 280 : 320;
            tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
            await tester.enterText(find.byType(TextFormField).first, 'ABC');
            await tester.pumpAndSettle();
            expect(find.text(strings.chatChatIdInvalid), findsOneWidget);
            expect(tester.takeException(), isNull);
            final Finder submit = find.widgetWithText(
              FilledButton,
              strings.chatJoin,
            );
            await tester.ensureVisible(submit);
            await tester.pumpAndSettle();
            expect(submit.hitTestable(), findsOneWidget);
            expect(
              tester.getRect(submit).bottom,
              lessThanOrEqualTo(size.height - keyboard),
            );

            await tester.enterText(find.byType(TextFormField).first, 'C' * 64);
            await tester.ensureVisible(submit);
            await tester.pumpAndSettle();
            await tester.tap(submit);
            await tester.pumpAndSettle();
            expect(harness.service.groups.single.chatId, 'C' * 64);
            expect(find.byType(JoinGroupForm), findsNothing);
          },
        );
      }
    }
  }
}
