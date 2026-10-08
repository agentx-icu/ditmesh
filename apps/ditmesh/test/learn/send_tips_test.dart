import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/learn/send/send_result_view.dart';
import 'package:ditmesh/ui/learn/send/send_tips.dart';

import 'helpers/l10n.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

SendIssue _issue(SendIssueKind kind, {SendSeverity severity = SendSeverity.moderate}) =>
    SendIssue(
      kind: kind,
      severity: severity,
      offending: 2,
      total: 5,
      meanRatio: 1.6,
    );

void main() {
  group('send tips', () {
    test('every issue kind has a distinct title, tip and detail', () {
      final Set<String> titles = <String>{};
      final Set<String> tips = <String>{};
      final Set<String> details = <String>{};
      for (final SendIssueKind kind in SendIssueKind.values) {
        final SendIssue issue = _issue(kind);
        titles.add(titleFor(en, kind));
        tips.add(tipFor(en, issue));
        details.add(detailFor(en, issue));
      }
      expect(titles, hasLength(SendIssueKind.values.length));
      expect(tips, hasLength(SendIssueKind.values.length));
      expect(details, hasLength(SendIssueKind.values.length));
      expect(titles.every((t) => t.trim().isNotEmpty), isTrue);
    });

    test('tips quote the measured ratio', () {
      expect(
        tipFor(en, _issue(SendIssueKind.ditTooLong)),
        contains(en.learnRatioTimes('1.6')),
      );
      expect(
        tipFor(en, _issue(SendIssueKind.speedUnsteady)),
        contains('160'),
        reason: 'unsteadiness is a percentage',
      );
      expect(
        detailFor(en, _issue(SendIssueKind.dahTooShort)),
        allOf(contains('2'), contains('5'), contains(en.learnRatioTimes('1.60'))),
      );
      expect(detailFor(en, _issue(SendIssueKind.speedUnsteady)), contains('1.60'));
    });

    test('severity labels are distinct in every shipped language', () {
      for (final Locale locale in S.supportedLocales) {
        final S s = lookupS(locale);
        final Set<String> labels = <String>{
          for (final SendSeverity sev in SendSeverity.values) severityLabel(s, sev),
        };
        expect(labels, hasLength(3), reason: locale.toString());
        for (final SendIssueKind kind in SendIssueKind.values) {
          expect(tipFor(s, _issue(kind)).trim(), isNotEmpty, reason: '$locale $kind');
        }
      }
    });

    test('formatWpm shows a placeholder until the speed is known', () {
      expect(formatWpm(en, 0), en.learnWpmUnknown);
      expect(formatWpm(en, -1), en.learnWpmUnknown);
      expect(formatWpm(en, 18.4), en.learnWpmValue('18'));
    });
  });

  group('SendResultView', () {
    testWidgets('lists each issue with its headline, tip and detail', (
      tester,
    ) async {
      // Three clean dits and one long one: a ditTooLong issue.
      const Duration dit = Duration(milliseconds: 60);
      const SendAttempt attempt = SendAttempt(
        target: 'E',
        decoded: 'E',
        marks: <Duration>[dit, dit, dit, Duration(milliseconds: 110)],
        gaps: <Duration>[dit, dit, dit],
        estimatedDit: dit,
      );
      final SendDiagnostics diagnostics = attempt.evaluate();
      final SendIssue issue = diagnostics.issues.firstWhere(
        (i) => i.kind == SendIssueKind.ditTooLong,
      );
      _phone(tester);
      await tester.pumpWidget(
        l10nApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SendResultView(diagnostics: diagnostics),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(en.learnSendClean), findsNothing);
      expect(
        find.text(
          en.learnIssueHeadline(
            titleFor(en, issue.kind),
            severityLabel(en, issue.severity),
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(tipFor(en, issue)), findsOneWidget);
      expect(find.text(detailFor(en, issue)), findsOneWidget);
      expect(find.byIcon(Icons.graphic_eq), findsNWidgets(diagnostics.issues.length));
      expect(find.text(en.learnWpmValue('20')), findsOneWidget);
    });

    testWidgets('a clean attempt says so', (tester) async {
      const Duration dit = Duration(milliseconds: 60);
      const SendAttempt attempt = SendAttempt(
        target: 'E',
        decoded: 'E',
        marks: <Duration>[dit],
        gaps: <Duration>[],
        estimatedDit: dit,
      );
      _phone(tester);
      await tester.pumpWidget(
        l10nApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SendResultView(diagnostics: attempt.evaluate()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(en.learnSendClean), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.graphic_eq), findsNothing);
    });
  });
}
