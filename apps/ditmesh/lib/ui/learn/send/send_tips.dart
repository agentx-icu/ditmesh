import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';

/// Plain-language coaching for one [SendIssue], in the current locale. The
/// wording depends on the measured ratio, so this is a function of the
/// issue rather than a fixed string per kind.
String tipFor(S s, SendIssue issue) {
  final ratio = issue.meanRatio;
  return switch (issue.kind) {
    SendIssueKind.ditTooLong => s.learnTipDitTooLong(_x(s, ratio)),
    SendIssueKind.dahTooShort => s.learnTipDahTooShort(_x(s, ratio)),
    SendIssueKind.dahTooLong => s.learnTipDahTooLong(_x(s, ratio)),
    SendIssueKind.intraGapTooLong => s.learnTipIntraGapTooLong(_x(s, ratio)),
    SendIssueKind.charGapTooShort => s.learnTipCharGapTooShort(_x(s, ratio)),
    SendIssueKind.wordGapTooShort => s.learnTipWordGapTooShort(_x(s, ratio)),
    SendIssueKind.speedUnsteady => s.learnTipSpeedUnsteady(
      (ratio * 100).round(),
    ),
  };
}

/// Short headline for an issue kind.
String titleFor(S s, SendIssueKind kind) => switch (kind) {
  SendIssueKind.ditTooLong => s.learnTipDitTooLongTitle,
  SendIssueKind.dahTooShort => s.learnTipDahTooShortTitle,
  SendIssueKind.dahTooLong => s.learnTipDahTooLongTitle,
  SendIssueKind.intraGapTooLong => s.learnTipIntraGapTooLongTitle,
  SendIssueKind.charGapTooShort => s.learnTipCharGapTooShortTitle,
  SendIssueKind.wordGapTooShort => s.learnTipWordGapTooShortTitle,
  SendIssueKind.speedUnsteady => s.learnTipSpeedUnsteadyTitle,
};

/// Severity label shown after the headline.
String severityLabel(S s, SendSeverity severity) => switch (severity) {
  SendSeverity.minor => s.learnSeverityMinor,
  SendSeverity.moderate => s.learnSeverityModerate,
  SendSeverity.severe => s.learnSeveritySevere,
};

/// Localised counterpart of `SendIssue.describe()`: how many elements were
/// off and the average ratio, e.g. "2 of 5 dits too long (avg 1.60x dit)".
String detailFor(S s, SendIssue issue) {
  final ratio = issue.meanRatio.toStringAsFixed(2);
  final x = s.learnRatioTimes(ratio);
  final n = issue.offending;
  final total = issue.total;
  return switch (issue.kind) {
    SendIssueKind.ditTooLong => s.learnIssueDetailDitTooLong(n, total, x),
    SendIssueKind.dahTooShort => s.learnIssueDetailDahTooShort(n, total, x),
    SendIssueKind.dahTooLong => s.learnIssueDetailDahTooLong(n, total, x),
    SendIssueKind.intraGapTooLong => s.learnIssueDetailIntraGapTooLong(
      n,
      total,
      x,
    ),
    SendIssueKind.charGapTooShort => s.learnIssueDetailCharGapTooShort(
      n,
      total,
      x,
    ),
    SendIssueKind.wordGapTooShort => s.learnIssueDetailWordGapTooShort(
      n,
      total,
      x,
    ),
    SendIssueKind.speedUnsteady => s.learnIssueDetailSpeedUnsteady(ratio),
  };
}

/// Speed readout: `18 wpm`, or the placeholder while the speed is unknown.
String formatWpm(S s, double wpm) =>
    wpm <= 0 ? s.learnWpmUnknown : s.learnWpmValue(wpm.toStringAsFixed(0));

String _x(S s, double ratio) => s.learnRatioTimes(ratio.toStringAsFixed(1));
