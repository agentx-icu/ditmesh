import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';

/// Localised stage names and issue explanations for the QSO simulator.
abstract final class QsoLabels {
  static String stage(S s, QsoStage stage) => switch (stage) {
    QsoStage.callCq => s.learnQsoStageCallCq,
    QsoStage.callConfirm => s.learnQsoStageCallConfirm,
    QsoStage.exchange => s.learnQsoStageExchange,
    QsoStage.confirmInfo => s.learnQsoStageConfirmInfo,
    QsoStage.closing => s.learnQsoStageClosing,
    QsoStage.done => s.learnQsoStageDone,
  };

  static String issue(S s, QsoIssue issue) => switch (issue) {
    QsoIssue.empty => s.learnQsoIssueEmpty,
    QsoIssue.missingCq => s.learnQsoIssueMissingCq,
    QsoIssue.missingDe => s.learnQsoIssueMissingDe,
    QsoIssue.wrongLocalCall => s.learnQsoIssueWrongLocalCall,
    QsoIssue.wrongRemoteCall => s.learnQsoIssueWrongRemoteCall,
    QsoIssue.reversedCalls => s.learnQsoIssueReversedCalls,
    QsoIssue.missingEnding => s.learnQsoIssueMissingEnding,
    QsoIssue.missingRst => s.learnQsoIssueMissingRst,
    QsoIssue.invalidRst => s.learnQsoIssueInvalidRst,
    QsoIssue.missingName => s.learnQsoIssueMissingName,
    QsoIssue.wrongName => s.learnQsoIssueWrongName,
    QsoIssue.missingQth => s.learnQsoIssueMissingQth,
    QsoIssue.wrongQth => s.learnQsoIssueWrongQth,
    QsoIssue.missingAck => s.learnQsoIssueMissingAck,
    QsoIssue.wrongRemoteName => s.learnQsoIssueWrongRemoteName,
    QsoIssue.missing73 => s.learnQsoIssueMissing73,
    QsoIssue.missingSk => s.learnQsoIssueMissingSk,
  };
}
