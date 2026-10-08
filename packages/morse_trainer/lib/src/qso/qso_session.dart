import 'dart:math';

import 'qso_evaluator.dart';
import 'qso_scenario.dart';

/// One transmission in the log.
final class QsoTurn {
  const QsoTurn({
    required this.fromRemote,
    required this.text,
    required this.stage,
    this.accepted,
    this.issues = const <QsoIssue>[],
  });

  final bool fromRemote;
  final String text;
  final QsoStage stage;

  /// Learner turns only: whether the stage accepted it.
  final bool? accepted;
  final List<QsoIssue> issues;

  Map<String, Object?> toJson() => <String, Object?>{
    'remote': fromRemote,
    'text': text,
    'stage': stage.name,
    'accepted': accepted,
    'issues': issues.map((i) => i.name).toList(),
  };

  factory QsoTurn.fromJson(Map<String, Object?> json) => QsoTurn(
    fromRemote: json['remote']! as bool,
    text: json['text']! as String,
    stage: QsoStage.parse(json['stage'] as String?),
    accepted: json['accepted'] as bool?,
    issues: [
      for (final name in (json['issues'] as List<Object?>? ?? const []))
        for (final i in QsoIssue.values)
          if (i.name == name) i,
    ],
  );
}

/// What one submission did.
final class QsoReply {
  const QsoReply({
    required this.evaluation,
    required this.stageBefore,
    required this.stageAfter,
    this.remoteText,
    this.duplicate = false,
    this.speedLowered = false,
  });

  final QsoEvaluation evaluation;
  final QsoStage stageBefore;
  final QsoStage stageAfter;

  /// Text the remote sends in response (to play), or null.
  final String? remoteText;

  /// The submission id was already processed; nothing changed.
  final bool duplicate;
  final bool speedLowered;

  bool get advanced => stageAfter != stageBefore;
}

/// A hint for the current stage: an example with the learner's own values.
/// Level 2 (after [QsoSession.hintAfterErrors] consecutive errors) names
/// the expected fields more specifically; neither answers automatically.
final class QsoHint {
  const QsoHint({
    required this.stage,
    required this.level,
    required this.example,
  });

  final QsoStage stage;
  final int level;

  /// Protocol text, never translated.
  final String example;
}

/// Interactive QSO state machine (functional spec §5.2). Pure and
/// seed-replayable: callsigns, names, QTHs and reports stay consistent for a
/// session, and every submission id is processed once.
final class QsoSession {
  QsoSession._({
    required this.scenario,
    required this.seed,
    required this.local,
    required this.remote,
    required this.report,
    required this.characterWpm,
    required this.minEffectiveWpm,
    required double effectiveWpm,
    required QsoStage stage,
    required List<QsoTurn> turns,
    required Set<String> processed,
    this.repeats = 0,
    this.hints = 0,
    this.consecutiveErrors = 0,
    this.firstTryStages = 0,
  }) : _effectiveWpm = effectiveWpm,
       _stage = stage,
       _turns = turns,
       _processed = processed;

  factory QsoSession.start({
    required QsoScenario scenario,
    required int seed,
    required QsoStation local,
    required double characterWpm,
    required double effectiveWpm,
    double minEffectiveWpm = 5,
  }) {
    final random = Random(seed);
    final l = local.normalized();
    QsoStation remote;
    do {
      remote = QsoStation.random(random);
    } while (remote.callsign == l.callsign || remote.name == l.name);
    final report =
        QsoScript.remoteReports[random.nextInt(QsoScript.remoteReports.length)];
    final first = QsoScript.stagesFor(scenario).first;
    final session = QsoSession._(
      scenario: scenario,
      seed: seed,
      local: l,
      remote: remote,
      report: report,
      characterWpm: characterWpm,
      minEffectiveWpm: minEffectiveWpm,
      effectiveWpm: min(effectiveWpm, characterWpm),
      stage: first,
      turns: <QsoTurn>[],
      processed: <String>{},
    );
    session._remoteFor(first);
    return session;
  }

  static const int hintAfterErrors = 3;

  final QsoScenario scenario;
  final int seed;
  final QsoStation local;
  final QsoStation remote;

  /// The report the remote gives.
  final String report;
  final double characterWpm;
  final double minEffectiveWpm;
  double _effectiveWpm;
  QsoStage _stage;
  final List<QsoTurn> _turns;
  final Set<String> _processed;

  int repeats;
  int hints;
  int consecutiveErrors;

  /// Stages accepted on the first answer (field correctness).
  int firstTryStages;
  bool _stageHadError = false;

  QsoStage get stage => _stage;
  bool get isDone => _stage == QsoStage.done;
  double get effectiveWpm => _effectiveWpm;
  List<QsoTurn> get turns => List<QsoTurn>.unmodifiable(_turns);
  int get answerStages => QsoScript.stagesFor(scenario).length;

  /// The remote's most recent transmission (what AGN repeats), or null when
  /// the learner opens.
  String? get lastRemoteText {
    for (final t in _turns.reversed) {
      if (t.fromRemote) return t.text;
    }
    return null;
  }

  int get learnerTurns => _turns.where((t) => !t.fromRemote).length;

  /// Processes one explicit submission. A repeated [submissionId] (double
  /// tap, rebuild) returns a duplicate reply and changes nothing.
  QsoReply submit(String submissionId, String text) {
    final before = _stage;
    if (_processed.contains(submissionId) || isDone) {
      return QsoReply(
        evaluation: const QsoEvaluation(QsoIntent.answer),
        stageBefore: before,
        stageAfter: before,
        duplicate: true,
      );
    }
    _processed.add(submissionId);
    final eval = QsoEvaluator.evaluate(
      text,
      stage: _stage,
      scenario: scenario,
      local: local,
      remote: remote,
    );
    _turns.add(
      QsoTurn(
        fromRemote: false,
        text: text.trim().toUpperCase(),
        stage: _stage,
        accepted: eval.accepted,
        issues: eval.issues,
      ),
    );
    switch (eval.intent) {
      case QsoIntent.repeat:
        repeats++;
        final again = lastRemoteText;
        if (again != null) _addRemote(again);
        return QsoReply(
          evaluation: eval,
          stageBefore: before,
          stageAfter: _stage,
          remoteText: again,
        );
      case QsoIntent.slowDown:
        final lowered = max(minEffectiveWpm, _effectiveWpm - 1);
        final changed = lowered < _effectiveWpm;
        _effectiveWpm = lowered;
        final again = lastRemoteText;
        if (again != null) _addRemote(again);
        return QsoReply(
          evaluation: eval,
          stageBefore: before,
          stageAfter: _stage,
          remoteText: again,
          speedLowered: changed,
        );
      case QsoIntent.answer:
        break;
    }
    if (!eval.accepted) {
      consecutiveErrors++;
      _stageHadError = true;
      return QsoReply(
        evaluation: eval,
        stageBefore: before,
        stageAfter: _stage,
      );
    }
    consecutiveErrors = 0;
    if (!_stageHadError) firstTryStages++;
    _stageHadError = false;
    final stages = QsoScript.stagesFor(scenario);
    final index = stages.indexOf(_stage);
    _stage = index + 1 < stages.length ? stages[index + 1] : QsoStage.done;
    final remoteText = _remoteFor(_stage);
    return QsoReply(
      evaluation: eval,
      stageBefore: before,
      stageAfter: _stage,
      remoteText: remoteText,
    );
  }

  /// Hint for the current stage; level 2 after repeated errors. Counted as
  /// assistance.
  QsoHint hint() {
    hints++;
    final level = consecutiveErrors >= hintAfterErrors ? 2 : 1;
    final l = local.callsign;
    final r = remote.callsign;
    final example = switch (_stage) {
      QsoStage.callCq => level == 2 ? 'CQ CQ DE $l $l K' : 'CQ CQ DE <LOCAL> K',
      QsoStage.callConfirm =>
        level == 2 ? '$r DE $l K' : '<REMOTE> DE <LOCAL> K',
      QsoStage.exchange =>
        (scenario == QsoScenario.callCq ? '$r DE $l ' : '') +
            (level == 2
                ? 'UR RST 599 NAME ${local.name} QTH ${local.qth} K'
                : 'UR RST <RST> NAME <NAME> QTH <QTH> K'),
      QsoStage.confirmInfo =>
        level == 2 ? 'R R TNX ${remote.name}' : 'R R TNX <REMOTE NAME>',
      QsoStage.closing => 'TU 73 <SK>',
      QsoStage.done => '',
    };
    return QsoHint(stage: _stage, level: level, example: example);
  }

  String? _remoteFor(QsoStage stage) {
    final text = QsoScript.remoteBefore(
      scenario,
      stage,
      local: local,
      remote: remote,
      report: report,
    );
    if (text != null) _addRemote(text);
    return text;
  }

  void _addRemote(String text) =>
      _turns.add(QsoTurn(fromRemote: true, text: text, stage: _stage));

  Map<String, Object?> toJson() => <String, Object?>{
    'v': QsoScript.version,
    'scenario': scenario.name,
    'seed': seed,
    'local': local.toJson(),
    'remote': remote.toJson(),
    'report': report,
    'characterWpm': characterWpm,
    'effectiveWpm': _effectiveWpm,
    'minEffectiveWpm': minEffectiveWpm,
    'stage': _stage.name,
    'turns': _turns.map((t) => t.toJson()).toList(),
    'processed': _processed.toList(),
    'repeats': repeats,
    'hints': hints,
    'consecutiveErrors': consecutiveErrors,
    'firstTryStages': firstTryStages,
    'stageHadError': _stageHadError,
  };

  /// Restores text and state (never a held key or active playback).
  factory QsoSession.fromJson(Map<String, Object?> json) {
    final session = QsoSession._(
      scenario: QsoScenario.parse(json['scenario'] as String?),
      seed: (json['seed']! as num).toInt(),
      local: QsoStation.fromJson(json['local']! as Map<String, Object?>),
      remote: QsoStation.fromJson(json['remote']! as Map<String, Object?>),
      report: json['report']! as String,
      characterWpm: (json['characterWpm']! as num).toDouble(),
      effectiveWpm: (json['effectiveWpm']! as num).toDouble(),
      minEffectiveWpm: (json['minEffectiveWpm'] as num?)?.toDouble() ?? 5,
      stage: QsoStage.parse(json['stage'] as String?),
      turns: [
        for (final t in json['turns']! as List<Object?>)
          QsoTurn.fromJson(t! as Map<String, Object?>),
      ],
      processed: (json['processed']! as List<Object?>).cast<String>().toSet(),
      repeats: (json['repeats'] as num?)?.toInt() ?? 0,
      hints: (json['hints'] as num?)?.toInt() ?? 0,
      consecutiveErrors: (json['consecutiveErrors'] as num?)?.toInt() ?? 0,
      firstTryStages: (json['firstTryStages'] as num?)?.toInt() ?? 0,
    );
    session._stageHadError = json['stageHadError'] as bool? ?? false;
    return session;
  }
}
