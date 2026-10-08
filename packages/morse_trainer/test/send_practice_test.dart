import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  const dit = Duration(milliseconds: 60); // 20 wpm
  Duration units(double n) =>
      Duration(microseconds: (dit.inMicroseconds * n).round());

  SendAttempt attempt({
    required List<double> marks,
    required List<double> gaps,
    String target = 'K',
    String? decoded,
  }) => SendAttempt(
    target: target,
    decoded: decoded ?? target,
    marks: marks.map(units).toList(),
    gaps: gaps.map(units).toList(),
    estimatedDit: dit,
  );

  group('SendAttempt / SendDiagnostics', () {
    test('measured wpm = 1200 / ditMs', () {
      final a = attempt(marks: [1], gaps: []);
      expect(a.measuredWpm, closeTo(20, 1e-9));
      expect(a.evaluate().measuredWpm, closeTo(20, 1e-9));
      const zero = SendAttempt(
        target: '',
        decoded: '',
        marks: [],
        gaps: [],
        estimatedDit: Duration.zero,
      );
      expect(zero.measuredWpm, 0);
      expect(zero.evaluate().isClean, isTrue);
    });

    test('perfect keying is clean and classifies elements', () {
      // K = dah dit dah, then char gap, then M = dah dah, word gap, E = dit.
      final d = attempt(
        target: 'KM E',
        marks: [3, 1, 3, 3, 3, 1],
        gaps: [1, 1, 3, 1, 7],
      ).evaluate();
      expect(d.isClean, isTrue, reason: d.issues.toString());
      expect(d.ditCount, 2);
      expect(d.dahCount, 4);
      expect(d.intraGapCount, 3);
      expect(d.charGapCount, 1);
      expect(d.wordGapCount, 1);
      expect(d.unsteadiness, closeTo(0, 1e-9));
      expect(d.score.isPerfect, isTrue);
    });

    test('dits at 1.6x dit -> ditTooLong', () {
      final d = attempt(
        marks: [1.6, 1.6, 1.6, 3, 3],
        gaps: [1, 1, 1, 1],
      ).evaluate();
      final issue = d.issueOf(SendIssueKind.ditTooLong);
      expect(issue, isNotNull);
      expect(issue!.offending, 3);
      expect(issue.total, 3);
      expect(issue.meanRatio, closeTo(1.6, 1e-9));
      expect(issue.severity, SendSeverity.severe);
      expect(issue.describe(), contains('3 of 3 dits'));
    });

    test('short dahs -> dahTooShort with severity by fraction', () {
      final d = attempt(
        marks: [1, 1, 1, 1, 3, 3, 3, 3, 2.2],
        gaps: [1, 1, 1, 1, 1, 1, 1, 1],
      ).evaluate();
      final issue = d.issueOf(SendIssueKind.dahTooShort)!;
      expect(issue.offending, 1);
      expect(issue.total, 5);
      expect(issue.severity, SendSeverity.minor); // 1/5 < 25 %

      // Exactly 25 % offending is moderate; 50 % is severe.
      final moderate = attempt(
        marks: [3, 3, 3, 2.2],
        gaps: [1, 1, 1],
      ).evaluate();
      expect(
        moderate.issueOf(SendIssueKind.dahTooShort)!.severity,
        SendSeverity.moderate,
      );
      final severe = attempt(marks: [3, 2.2], gaps: [1]).evaluate();
      expect(
        severe.issueOf(SendIssueKind.dahTooShort)!.severity,
        SendSeverity.severe,
      );
    });

    test('gap problems', () {
      // intra gap 1.7 (too long), char gap 2.2 (too short), word gap 5.5 (too short).
      final d = attempt(marks: [1, 1, 1, 1], gaps: [1.7, 2.2, 5.5]).evaluate();
      expect(d.hasIssue(SendIssueKind.intraGapTooLong), isTrue);
      expect(d.hasIssue(SendIssueKind.charGapTooShort), isTrue);
      expect(d.hasIssue(SendIssueKind.wordGapTooShort), isTrue);
      expect(d.hasIssue(SendIssueKind.ditTooLong), isFalse);
    });

    test('unsteady speed', () {
      final d = attempt(
        marks: [0.7, 1.3, 0.6, 1.4, 3, 3.9, 2.4],
        gaps: [1, 1, 1, 1, 1, 1],
      ).evaluate();
      final issue = d.issueOf(SendIssueKind.speedUnsteady);
      expect(issue, isNotNull);
      expect(d.unsteadiness, greaterThan(0.2));
      expect(d.worst, isNotNull);
    });

    test('steady but consistently long dits is not unsteady', () {
      final d = attempt(
        marks: [1.5, 1.5, 1.5, 1.5],
        gaps: [1, 1, 1],
      ).evaluate();
      expect(d.hasIssue(SendIssueKind.speedUnsteady), isFalse);
      expect(d.hasIssue(SendIssueKind.ditTooLong), isTrue);
    });

    test('custom thresholds are honoured', () {
      final a = attempt(marks: [1.2, 1.2, 1.2], gaps: [1, 1]);
      expect(a.evaluate().isClean, isTrue);
      final strict = a.evaluate(
        thresholds: const SendThresholds(ditTooLongRatio: 1.1),
      );
      expect(strict.hasIssue(SendIssueKind.ditTooLong), isTrue);
    });

    test('copy score reflects decoded vs target', () {
      final d = attempt(
        marks: [1],
        gaps: [],
        target: 'KM',
        decoded: 'KR',
      ).evaluate();
      expect(d.score.accuracy, closeTo(0.5, 1e-9));
    });
  });
}
