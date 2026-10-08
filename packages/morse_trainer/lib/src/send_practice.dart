import 'dart:math';

import 'session_score.dart';

/// Problems a send attempt can exhibit.
enum SendIssueKind {
  ditTooLong,
  dahTooShort,

  /// Dahs held far beyond three dits (added with the rhythm timeline).
  dahTooLong,
  intraGapTooLong,
  charGapTooShort,
  wordGapTooShort,
  speedUnsteady,
}

enum SendSeverity { minor, moderate, severe }

/// Ratios (in units of the estimated dit) that decide element classes and
/// what counts as an error.
final class SendThresholds {
  const SendThresholds({
    this.ditDahBoundary = 2.0,
    this.charGapBoundary = 2.0,
    this.wordGapBoundary = 5.0,
    this.ditTooLongRatio = 1.3,
    this.dahTooShortRatio = 2.6,
    this.dahTooLongRatio = 4.0,
    this.intraGapTooLongRatio = 1.3,
    this.charGapTooShortRatio = 2.5,
    this.wordGapTooShortRatio = 6.0,
    this.unsteadyCv = 0.20,
    this.moderateFraction = 0.25,
    this.severeFraction = 0.50,
  });

  /// Marks at or above this many dits are dahs.
  final double ditDahBoundary;

  /// Gaps at or above this many dits separate characters ...
  final double charGapBoundary;

  /// ... and at or above this many dits separate words.
  final double wordGapBoundary;

  final double ditTooLongRatio;
  final double dahTooShortRatio;
  final double dahTooLongRatio;
  final double intraGapTooLongRatio;
  final double charGapTooShortRatio;
  final double wordGapTooShortRatio;

  /// Coefficient of variation of normalised mark lengths above which the
  /// speed is reported as unsteady.
  final double unsteadyCv;

  /// Fraction of offending elements at which severity becomes moderate /
  /// severe (below [moderateFraction] is minor).
  final double moderateFraction;
  final double severeFraction;
}

/// One detected problem with counts and an average measured ratio.
final class SendIssue {
  const SendIssue({
    required this.kind,
    required this.severity,
    required this.offending,
    required this.total,
    required this.meanRatio,
  });

  final SendIssueKind kind;
  final SendSeverity severity;

  /// Elements that violated the rule.
  final int offending;

  /// Elements of that class that were examined.
  final int total;

  /// Mean length of the offending elements in dits (for
  /// [SendIssueKind.speedUnsteady] this is the coefficient of variation).
  final double meanRatio;

  /// English diagnostic text for logs and [toString] only. The app never
  /// shows it: the localised wording lives in
  /// `apps/ditmesh/lib/ui/learn/send/send_tips.dart` (pure-Dart packages
  /// carry no ARBs).
  String describe() {
    final r = meanRatio.toStringAsFixed(2);
    return switch (kind) {
      SendIssueKind.ditTooLong =>
        '$offending of $total dits too long (avg ${r}x dit)',
      SendIssueKind.dahTooShort =>
        '$offending of $total dahs too short (avg ${r}x dit)',
      SendIssueKind.dahTooLong =>
        '$offending of $total dahs too long (avg ${r}x dit)',
      SendIssueKind.intraGapTooLong =>
        '$offending of $total gaps inside characters too long (avg ${r}x dit)',
      SendIssueKind.charGapTooShort =>
        '$offending of $total character gaps too short (avg ${r}x dit)',
      SendIssueKind.wordGapTooShort =>
        '$offending of $total word gaps too short (avg ${r}x dit)',
      SendIssueKind.speedUnsteady => 'keying speed unsteady (cv $r)',
    };
  }

  @override
  String toString() =>
      'SendIssue(${kind.name}, ${severity.name}: ${describe()})';
}

/// Raw measurements of one sending exercise.
///
/// [marks] are key-down durations in order; [gaps] are the key-up durations
/// between consecutive marks (normally `marks.length - 1` entries; extra or
/// missing entries are tolerated). [estimatedDit] is the decoder's dit
/// estimate for this attempt and anchors every threshold.
final class SendAttempt {
  const SendAttempt({
    required this.target,
    required this.decoded,
    required this.marks,
    required this.gaps,
    required this.estimatedDit,
  });

  final String target;
  final String decoded;
  final List<Duration> marks;
  final List<Duration> gaps;
  final Duration estimatedDit;

  /// `1200 / ditMs`, or 0 when the dit is unknown.
  double get measuredWpm {
    final ditMs = estimatedDit.inMicroseconds / 1000;
    return ditMs <= 0 ? 0 : 1200 / ditMs;
  }

  SendDiagnostics evaluate({
    SendThresholds thresholds = const SendThresholds(),
  }) => SendDiagnostics.evaluate(this, thresholds: thresholds);
}

/// Outcome of analysing a [SendAttempt].
final class SendDiagnostics {
  SendDiagnostics._({
    required this.attempt,
    required List<SendIssue> issues,
    required this.score,
    required this.ditCount,
    required this.dahCount,
    required this.intraGapCount,
    required this.charGapCount,
    required this.wordGapCount,
    required this.unsteadiness,
  }) : issues = List<SendIssue>.unmodifiable(issues);

  factory SendDiagnostics.evaluate(
    SendAttempt attempt, {
    SendThresholds thresholds = const SendThresholds(),
  }) {
    final t = thresholds;
    final ditUs = attempt.estimatedDit.inMicroseconds;
    final score = SessionScore.evaluate(attempt.target, attempt.decoded);
    if (ditUs <= 0) {
      return SendDiagnostics._(
        attempt: attempt,
        issues: const <SendIssue>[],
        score: score,
        ditCount: 0,
        dahCount: 0,
        intraGapCount: 0,
        charGapCount: 0,
        wordGapCount: 0,
        unsteadiness: 0,
      );
    }
    double ratio(Duration d) => d.inMicroseconds / ditUs;

    final dits = <double>[];
    final dahs = <double>[];
    for (final m in attempt.marks) {
      final r = ratio(m);
      (r < t.ditDahBoundary ? dits : dahs).add(r);
    }
    final intra = <double>[];
    final charGaps = <double>[];
    final wordGaps = <double>[];
    for (final g in attempt.gaps) {
      final r = ratio(g);
      if (r < t.charGapBoundary) {
        intra.add(r);
      } else if (r < t.wordGapBoundary) {
        charGaps.add(r);
      } else {
        wordGaps.add(r);
      }
    }

    final issues = <SendIssue>[];
    void check(
      SendIssueKind kind,
      List<double> values,
      bool Function(double) bad,
    ) {
      final offending = values.where(bad).toList();
      if (offending.isEmpty) {
        return;
      }
      issues.add(
        SendIssue(
          kind: kind,
          severity: _severityForFraction(offending.length / values.length, t),
          offending: offending.length,
          total: values.length,
          meanRatio: _mean(offending),
        ),
      );
    }

    check(SendIssueKind.ditTooLong, dits, (r) => r > t.ditTooLongRatio);
    check(SendIssueKind.dahTooShort, dahs, (r) => r < t.dahTooShortRatio);
    check(SendIssueKind.dahTooLong, dahs, (r) => r > t.dahTooLongRatio);
    check(
      SendIssueKind.intraGapTooLong,
      intra,
      (r) => r > t.intraGapTooLongRatio,
    );
    check(
      SendIssueKind.charGapTooShort,
      charGaps,
      (r) => r < t.charGapTooShortRatio,
    );
    check(
      SendIssueKind.wordGapTooShort,
      wordGaps,
      (r) => r < t.wordGapTooShortRatio,
    );

    final normalised = <double>[...dits, ...dahs.map((r) => r / 3)];
    final cv = normalised.length >= 3
        ? _coefficientOfVariation(normalised)
        : 0.0;
    if (cv >= t.unsteadyCv) {
      final severity = cv >= 2 * t.unsteadyCv
          ? SendSeverity.severe
          : (cv >= 1.5 * t.unsteadyCv
                ? SendSeverity.moderate
                : SendSeverity.minor);
      issues.add(
        SendIssue(
          kind: SendIssueKind.speedUnsteady,
          severity: severity,
          offending: normalised.length,
          total: normalised.length,
          meanRatio: cv,
        ),
      );
    }

    return SendDiagnostics._(
      attempt: attempt,
      issues: issues,
      score: score,
      ditCount: dits.length,
      dahCount: dahs.length,
      intraGapCount: intra.length,
      charGapCount: charGaps.length,
      wordGapCount: wordGaps.length,
      unsteadiness: cv,
    );
  }

  final SendAttempt attempt;
  final List<SendIssue> issues;

  /// Copy accuracy of [SendAttempt.decoded] against [SendAttempt.target].
  final SessionScore score;

  final int ditCount;
  final int dahCount;
  final int intraGapCount;
  final int charGapCount;
  final int wordGapCount;

  /// Coefficient of variation of normalised mark lengths (0 = metronomic).
  final double unsteadiness;

  double get measuredWpm => attempt.measuredWpm;

  bool get isClean => issues.isEmpty;

  bool hasIssue(SendIssueKind kind) => issues.any((i) => i.kind == kind);

  SendIssue? issueOf(SendIssueKind kind) {
    for (final issue in issues) {
      if (issue.kind == kind) {
        return issue;
      }
    }
    return null;
  }

  /// The most severe issue, or null when clean.
  SendIssue? get worst {
    SendIssue? worst;
    for (final issue in issues) {
      if (worst == null || issue.severity.index > worst.severity.index) {
        worst = issue;
      }
    }
    return worst;
  }

  static SendSeverity _severityForFraction(double fraction, SendThresholds t) {
    if (fraction >= t.severeFraction) {
      return SendSeverity.severe;
    }
    return fraction >= t.moderateFraction
        ? SendSeverity.moderate
        : SendSeverity.minor;
  }

  static double _mean(List<double> values) =>
      values.fold<double>(0, (a, b) => a + b) / values.length;

  static double _coefficientOfVariation(List<double> values) {
    final mean = _mean(values);
    if (mean == 0) {
      return 0;
    }
    final variance =
        values.fold<double>(0, (acc, v) => acc + (v - mean) * (v - mean)) /
        values.length;
    return sqrt(variance) / mean;
  }

  @override
  String toString() =>
      'SendDiagnostics(${measuredWpm.toStringAsFixed(1)} wpm, '
      '${issues.length} issues, $score)';
}
